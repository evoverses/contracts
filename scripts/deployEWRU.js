const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function main(name) {
  console.log("Starting deployment...")
  const contractFactory = await ethers.getContractFactory(name)
  console.log("Deploying", name)

  const contract = await upgrades.deployProxy(contractFactory)
  console.log(name, "deployed! Address:", contract.address)
}

main("EmergencyWithdrawalReimbursementUpgradeable")
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })