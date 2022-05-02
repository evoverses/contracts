const hre = require("hardhat");
const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

const GOV_TOKEN = '0x5b747e23a9E4c509dd06fbd2c0e3cB8B846e398F'
const REWARD_PER_SECOND = ethers.utils.parseEther("0.5");
const START_TIME = Date.parse('Mon May 02 2022 19:30:00 GMT') / 1000;
const HALVING_AFTER_TIME = 7 * 24 * 60 * 60; // 1 epoch (1 week | 604800)

const REWARD_MULTIPLIER = [ 128, 64, 48, 32, 28, 24, 20, 16, 14, 12, 10, 9, 8, 7, 6, 5 ]
  .concat(Array(8).fill(4), Array(28).fill(2))


const DEV_FEE_STAGES = [25, 8, 4, 2, 1, 5, 25, 1];
const USER_FEE_STAGES = [75, 92, 96, 98, 99, 995, 9975, 9999];
const USER_DEPOSIT_FEE = 1;
const DEV_DEPOSIT_FEE = 1;

async function main(name) {
  console.log("Starting deployment...")
  const contractFactory = await ethers.getContractFactory(name)
  console.log("Deploying", name)
  const args = [
    GOV_TOKEN,
    REWARD_PER_SECOND,
    START_TIME,
    HALVING_AFTER_TIME,
    USER_DEPOSIT_FEE,
    DEV_DEPOSIT_FEE,
    REWARD_MULTIPLIER,
    USER_FEE_STAGES,
    DEV_FEE_STAGES
  ]
  const contract = await upgrades.deployProxy(contractFactory, args)
  console.log(name, "deployed! Address:", contract.address)
  console.log("Verifying", name)
  await hre.run("verify:verify", {
    address: contract.address,
    constructorArguments: args
  })

}

main("MasterInvestor")
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })