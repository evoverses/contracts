const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function main(name, address) {
  console.log("Starting deployment...")
  const Contract = await ethers.getContractFactory(name)
  console.log("Deploying", name)
  const contract = await upgrades.upgradeProxy(address, Contract)
  console.log(name, "deployed! Address:", contract.address)
}

main("MasterInvestor", "0x97fe80311460dff1612e2829698116b668d2324f")
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })