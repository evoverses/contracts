const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function deployProxy(name) {
  console.log("Starting deployment...")
  const contractFactory = await ethers.getContractFactory(name)
  console.log("Deploying", name)

  const contract = await upgrades.deployProxy(contractFactory)
  console.log(name, "deployed! Address:", contract.address)
}

async function deployProxyWithArgs(name, args) {
  console.log("Starting deployment...")
  const contractFactory = await ethers.getContractFactory(name)
  console.log("Deploying", name)

  const contract = await upgrades.deployProxy(contractFactory, args)
  console.log(name, "deployed! Address:", contract.address)
}

async function upgradeProxy(name, address) {
  console.log("Starting upgrade...")
  const Contract = await ethers.getContractFactory(name)
  console.log("Upgrading", name)
  const contract = await upgrades.upgradeProxy(address, Contract)
  console.log(name, "upgraded! Address:", contract.address)
}

module.exports = {
  deployProxy,
  deployProxyWithArgs,
  upgradeProxy
}