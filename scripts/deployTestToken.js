const hre = require("hardhat");
const { ethers } = require("hardhat")
require("dotenv").config()

const constructorArguments = [
  "TestToken",
  "TestToken",
  "600000000000000000000000000",
  "600000000000000000000000000",
  "25836650",
  "25918276"
]

async function main(name) {
  console.log("Starting deployment...")
  const contractFactory = await ethers.getContractFactory(name)
  console.log("Deploying", name)
  const contract = await contractFactory.deploy(...constructorArguments)
  console.log(name, "deployed! Address:", contract.address)
  console.log("Verifying", name)
  await hre.run("verify:verify", {
    contract: "contracts/examples/TestToken.sol:TestToken",
    address: contract.address,
    constructorArguments
  })

}

main("TestToken")
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })