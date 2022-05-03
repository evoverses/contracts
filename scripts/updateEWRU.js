const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function main(name, address) {
  console.log("Starting upgrade...")
  const Contract = await ethers.getContractFactory(name)
  console.log("Upgrading", name)
  const contract = await upgrades.upgradeProxy(address, Contract)
  console.log(name, "upgraded! Address:", contract.address)
}

main("EmergencyWithdrawalReimbursementUpgradeable", "0x306D0783119c61E033FCa12AC78943213Df8dE39")
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })