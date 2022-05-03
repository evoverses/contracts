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
  const lastSnapshotBlock = (await contract.LAST_SNAPSHOT_BLOCK()).toNumber()
  let totalDelta = currentBlock - lastSnapshotBlock
  let blockDelta = totalDelta
  let refundList = []

  console.log("Current block:", currentBlock)
  console.log("Last snapshot block:", lastSnapshotBlock)

  let from = lastSnapshotBlock + 1
  let to = currentBlock
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
      }
    }
  }
  return { refundList, lastSnapshotBlock, currentBlock }

}

async function save() {
  const { refundList, lastSnapshotBlock, currentBlock } = await scan()
  fs.writeFileSync(`./${lastSnapshotBlock}-${currentBlock}.json`, JSON.stringify(refundList))
}

async function retrieve() {
  const {contract} = await setup()
  const allRefunds = await contract.allRefunds()
  console.log(allRefunds)
}
async function update() {
  const {contract} = await setup()
  const jsonString = fs.readFileSync('./25481041-26041892.json')
  const refundList = JSON.parse(jsonString)
  let succeeded = []
  let failedList = []
  if (refundList.length > 0) {

    console.log(`Preparing ${refundList.length} refunds`)
    const batchRefundList = refundList.reduce((resultArray, item, index) => {
      const chunkIndex = Math.floor(index/50)
      if(!resultArray[chunkIndex]) {
        resultArray[chunkIndex] = [] // start a new chunk
      }
      resultArray[chunkIndex].push(item)
      return resultArray
    }, [])
    let added = 0
    for (const refunds of batchRefundList) {
      console.log(`Adding ${refunds.length} refunds | ${Math.round(added / refundList.length * 100)}% complete`)
      try {
        const tx = await contract.batchAddRefunds(refunds)
        await tx.wait(1)
        succeeded = succeeded.concat(refunds)
        added += refunds.length
      } catch (e) {
        console.log(e)
        failedList = failedList.concat(refunds)
      }
    }
    fs.writeFileSync('./succeeded.json', JSON.stringify(succeeded))
    fs.writeFileSync('./failed.json', JSON.stringify(failedList))
  }
}

update()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
