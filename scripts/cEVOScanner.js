const { ethers } = require("hardhat")
const fs = require('fs')
const { BigNumber } = require('ethers');
require("dotenv").config()
const genesisBlock = 25448630 // 2022-04-18, 18:35:38, 04/18/2022, 18:35:38
const preAnnounceBlock = 25480935 // 2022-04-19, 14:13:59, 04/19/2022, 14:13:59
const voteOfConfidenceBlock = 25564000 // 2022-04-21, 14:15:58, 04/21/2022, 14:15:58
async function setup() {
  const accounts = await ethers.getSigners()

  const contract = await ethers.getContractAt("EmergencyWithdrawalReimbursementUpgradeable", "0x306D0783119c61E033FCa12AC78943213Df8dE39", accounts[0])
  const masterInvestor = await ethers.getContractAt("MasterInvestor", "0xc84fb102fc1ee58e4402b303c34c94106232705b")
  const cEVO = await ethers.getContractAt("cEVO", "0x465d89df3e9B1AFB6957B58Be6137feeBB8e9f61", accounts[0])

  const emergencyWithdrawFilter = masterInvestor.filters.EmergencyWithdraw()
  const depositFilter = masterInvestor.filters.Deposit()
  return { accounts, contract, masterInvestor, emergencyWithdrawFilter, depositFilter, cEVO }
}


async function scanEligible() {
  const { masterInvestor, emergencyWithdrawFilter, depositFilter } = await setup()
  let totalDelta = preAnnounceBlock - genesisBlock
  let blockDelta = totalDelta
  let depositEvents = []
  let withdrawEvents = []
  console.log("Pre-Announce Block:", preAnnounceBlock)
  console.log("Genesis Block:", genesisBlock)

  let from = genesisBlock + 1
  let to = preAnnounceBlock - 1
  if (blockDelta > 1024) {
    to = from + 1024
  }
  let scanned = 0
  let finalScanned = false
  while (!finalScanned) {
    if (to === preAnnounceBlock) {
      finalScanned = true;
    }
    console.log("Blocks to scan:", blockDelta)
    console.log(`Getting events from ${from} to ${to} | ${Math.round(scanned / totalDelta * 100)}% complete`)
    const ewEvents = (await masterInvestor.queryFilter(emergencyWithdrawFilter, from, to)).filter(e => e.args.amount.gt(0))
    const dEvents = (await masterInvestor.queryFilter(depositFilter, from, to)).filter(e => e.args.amount.gt(0))
    scanned += to - from
    blockDelta -= to - from
    from = to + 1
    to = blockDelta > 1024 ? from + 1024 : preAnnounceBlock
    if (dEvents.length > 0) {
      console.log(`Adding ${dEvents.length} deposit events`)
      depositEvents = depositEvents.concat(dEvents)
    }
    if (ewEvents.length > 0) {
      console.log(`Adding ${ewEvents.length} withdrawal events`)
      withdrawEvents = withdrawEvents.concat(ewEvents)
    }
  }
  return { depositEvents, withdrawEvents }
}

async function scanReduced() {
  const { masterInvestor, emergencyWithdrawFilter } = await setup()
  let totalDelta = voteOfConfidenceBlock - preAnnounceBlock
  let blockDelta = totalDelta
  let addtlWithdrawEvents = []
  console.log("Pre-Announce Block:", preAnnounceBlock)
  console.log("Vote Of Confidence Block:", voteOfConfidenceBlock)

  let from = preAnnounceBlock + 1
  let to = voteOfConfidenceBlock - 1
  if (blockDelta > 1024) {
    to = from + 1024
  }
  let scanned = 0
  let finalScanned = false
  while (!finalScanned) {
    if (to === voteOfConfidenceBlock) {
      finalScanned = true;
    }
    console.log("Blocks to scan:", blockDelta)
    console.log(`Getting events from ${from} to ${to} | ${Math.round(scanned / totalDelta * 100)}% complete`)
    const ewEvents = (await masterInvestor.queryFilter(emergencyWithdrawFilter, from, to)).filter(e => e.args.amount.gt(0))
    scanned += to - from
    blockDelta -= to - from
    from = to + 1
    to = blockDelta > 1024 ? from + 1024 : voteOfConfidenceBlock
    if (ewEvents.length > 0) {
      console.log(`Adding ${ewEvents.length} withdrawal events`)
      addtlWithdrawEvents = addtlWithdrawEvents.concat(ewEvents)
    }
  }
  return { addtlWithdrawEvents }
}

async function retrieve() {
  const {contract} = await setup()
  const allRefunds = await contract.allRefunds()
  console.log(allRefunds)
}

async function parse() {
  const { depositEvents, withdrawEvents } = await scanEligible()
  const { addtlWithdrawEvents } = await scanReduced()
  console.log(`Totals: ${depositEvents.length} Deposit | ${withdrawEvents.length} Withdraw`)
  const users = {}
  for (const event of depositEvents) {
    if (!users[event.args.user]) {
      users[event.args.user] = {
        deposited: {
          lp: BigNumber.from(0),
          single: BigNumber.from(0),
        },
        withdrawn: {
          lp: BigNumber.from(0),
          single: BigNumber.from(0),
        },
        withdrawBlock: 0
      }
    }
    if (event.args.pid.eq(0)) {
      users[event.args.user].deposited.lp = users[event.args.user].deposited.lp.eq(0) ? event.args.amount : users[event.args.user].deposited.lp.add(event.args.amount)
    } else {
      users[event.args.user].deposited.single = users[event.args.user].deposited.single.eq(0) ? event.args.amount : users[event.args.user].deposited.single.add(event.args.amount)
    }

  }
  for (const event of withdrawEvents) {
    try {
      if (event.args.pid.eq(0)) {
        users[event.args.user].withdrawn.lp = users[event.args.user].withdrawn.lp.eq(0) ? event.args.amount : users[event.args.user].withdrawn.lp.add(event.args.amount)
      } else {
        users[event.args.user].withdrawn.single = users[event.args.user].withdrawn.single.eq(0) ? event.args.amount : users[event.args.user].withdrawn.single.add(event.args.amount)
      }
      users[event.args.user].withdrawBlock = event.blockNumber
    } catch (e) {
      console.log("Error withdraw for:", event.args.user)
    }
  }
  for (const event of addtlWithdrawEvents) {
    try {
      users[event.args.user].withdrawBlock = event.blockNumber
    } catch (e) {
      console.log("Skipping late user:", event.args.user)
    }
  }
  console.log(`Address,rawDepositEVO-ONE,rawDepositvEVO,rawWithdrawEVO-ONE,rawWithrawvEVO,withdrawBlock`)
  for (const user of Object.keys(users)) {
    console.log(`${user},${ethers.utils.formatEther(users[user].deposited.lp)},${ethers.utils.formatEther(users[user].deposited.single)},${ethers.utils.formatEther(users[user].withdrawn.lp)},${ethers.utils.formatEther(users[user].withdrawn.single)},${users[user].withdrawBlock}`)
  }
}

async function disburse() {
  const {cEVO} = await setup()
  const u = users.slice(1000, 1158)
  const a = amounts.map(a => ethers.utils.parseEther(a)).slice(1000, 1158)
  const tx = await cEVO.batchMint(u, a, 1654916400, 365*24*60*60)
  await tx.wait(1)
  console.log(tx)
}
parse()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
