const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

const maxRoyaltyBps = 1000;
const marketFeeBps = 100;
const marketFeeBurnedBps = 10;
const marketFeeReflectedBps = 10;
const treasury = "0x39Af60141b91F7941Eb13AedA2124a61a953b7C0";
const bank = "0x9c6291b4a30C6662aA9723e7345137e71975b20f";
const nexBidPercentBps = 1000;





const args = [maxRoyaltyBps, marketFeeBps, marketFeeBurnedBps, marketFeeReflectedBps, treasury, bank, nexBidPercentBps]

async function main(name) {
  console.log("Starting deployment...")
  const contractFactory = await ethers.getContractFactory(name)
  console.log("Deploying", name)
  const contract = await upgrades.deployProxy(contractFactory, args)
  console.log(name, "deployed! Address:", contract.address)
}

module.exports = {
  args
}

main("MarketplaceUpgradeable")
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })