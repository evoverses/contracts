const hre = require("hardhat");
const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function main(name, address) {
  const accounts = await ethers.getSigners()

  const contract = await ethers.getContractAt(name, address, accounts[0])
  const contract2 = await ethers.getContractAt('EvoToken', "", accounts[0])
  console.log(await contract.poolInfo(0))
  const tx = await contract.deposit(0, 10000000000)
  await tx.wait(1)
}

main("MasterInvestor", "")
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
