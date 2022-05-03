const { ethers } = require("hardhat")
const fs = require('fs')
require("dotenv").config()

async function setup() {
  const accounts = await ethers.getSigners()

  const contract = await ethers.getContractAt("EmergencyWithdrawalReimbursementUpgradeable", "0x306D0783119c61E033FCa12AC78943213Df8dE39", accounts[0])
  const masterInvestor = await ethers.getContractAt("MasterInvestorOld", "0xc84fb102fc1ee58e4402b303c34c94106232705b")

  const emergencyWithdrawFilter = masterInvestor.filters.EmergencyWithdraw()
  return {accounts, contract, masterInvestor, emergencyWithdrawFilter}
}


async function scan() {
  const {contract, masterInvestor, emergencyWithdrawFilter} = await setup()
  const currentBlock = await ethers.provider.getBlockNumber()
  const lastSnapshotBlock = 26062388//(await contract.LAST_SNAPSHOT_BLOCK()).toNumber()
  let totalDelta = currentBlock - lastSnapshotBlock
  let blockDelta = totalDelta
  let refundList = []
  let poolIdList = []
  console.log("Current block:", currentBlock)
  console.log("Last snapshot block:", lastSnapshotBlock)

  let from = lastSnapshotBlock + 1
  let to = currentBlock - 1
  if (blockDelta > 1024) {
    to = from + 1024
  }
  let scanned = 0
  while (to !== currentBlock) {
    console.log("Blocks to scan:", blockDelta)
    console.log(`Getting events from ${from} to ${to} | ${Math.round(scanned / totalDelta * 100)}% complete`)
    const events = await masterInvestor.queryFilter(emergencyWithdrawFilter, from, to)
    scanned += to - from
    blockDelta -= to - from
    from = to + 1
    to = blockDelta > 1024 ? from + 1024 : currentBlock
    for (const event of events) {
      //.log(events)
      const refund = {
        _address: event.args.user,
        withdrawn: event.args.amount,
        txHash: event.transactionHash,
        block: event.blockNumber,
        time: (await ethers.provider.getBlock(event.blockNumber)).timestamp,
        fee: event.args.amount.div(75).mul(100).sub(event.args.amount),
        paid: false
      }
      if (!refund.withdrawn.eq(0)) {
        refundList.push(refund)
        poolIdList.push(event.args.pid.toNumber())
      }
    }
  }
  return { refundList, poolIdList, lastSnapshotBlock, currentBlock }

}

async function retrieve() {
  const {contract} = await setup()
  const allRefunds = await contract.allRefunds()
  console.log(allRefunds)
}

async function update() {
  const {contract} = await setup()
  const { refundList, poolIdList, lastSnapshotBlock, currentBlock } = await scan()
  if (refundList.length > 0) {

    console.log(`Preparing ${refundList.length} refunds`)
    const batchRefundList = refundList.reduce((resultArray, item, index) => {
      const chunkIndex = Math.floor(index/10)
      if(!resultArray[chunkIndex]) {
        resultArray[chunkIndex] = [] // start a new chunk
      }
      resultArray[chunkIndex].push(item)
      return resultArray
    }, [])

    const batchPoolIdList = poolIdList.reduce((resultArray, item, index) => {
      const chunkIndex = Math.floor(index/10)
      if(!resultArray[chunkIndex]) {
        resultArray[chunkIndex] = [] // start a new chunk
      }
      resultArray[chunkIndex].push(item)
      return resultArray
    }, [])

    let added = 0
    for (const i in batchRefundList) {
      console.log(`Adding ${batchRefundList[i].length} refunds | ${Math.round(added / refundList.length * 100)}% complete`)
      try {
        const tx = await contract.batchAddRefunds(batchRefundList[i], batchPoolIdList[i])
        await tx.wait(1)
        added += batchRefundList.length
      } catch (e) {
        console.log(e)
      }
    }
  }
}

async function oneTime() {
  const {contract} = await setup()
  const wallets = await contract.allAffectedAddresses()
  let count = 0;
  for (const w of wallets) {
    const tx = await contract.upgradeRefundValuesByAddress(w)
    await tx.wait(1)
    count++
    console.log(`Upgraded ${count}/${wallets.length} (${Math.round(count/wallets.length*100)})`)
  }
}

update()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
