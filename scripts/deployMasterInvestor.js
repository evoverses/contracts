const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

const EVO = '0x42006Ab57701251B580bDFc24778C43c9ff589A1'
const cEVO = '0x7B5501109c2605834F7A4153A75850DB7521c37E'
const REWARD_PER_SECOND = ethers.utils.parseEther("0.5");
const START_TIME = 1656880080; // Sunday, July 3, 2022 20:28:00 GMT
const HALVING_AFTER_TIME = 7 * 24 * 60 * 60; // 1 epoch (1 week | 604800)

const REWARD_MULTIPLIERS = [16, 12, 12, 8, 8, 6, 6, 4, 4]
  .concat(Array(33).fill(2))

const PERCENT_LOCK_BONUS_REWARD = [...Array(40).keys()].map((_, i) => i * 2 + 1 ).reverse()

const DEV_FEE_STAGES = [25, 8, 4, 2, 1, 5, 25, 1];
const USER_FEE_STAGES = [75, 92, 96, 98, 99, 995, 9975, 9999];
const USER_DEPOSIT_FEE = 1;
const DEV_DEPOSIT_FEE = 1;

const DEV_ADDRESS = '0x94Cff3951Bb178c26E890058CD7C9a3B1AB98E99';
const LP_ADDRESS = '0xAc8642F6F55a9fd5f717B03Be2f9d29B70e434DF';
const COMMUNITY_FUND_ADDRESS = '0xa765a40b37becFCEa0Bcf84A48032eE9BC6127Dc';
const FOUNDER_ADDRESS = '0x7F8Ac7d0D886CA6881C795c7AF547487A029104A';

const args = [{
  govToken: EVO,
  rewardToken: cEVO,
  rewardPerSecond: REWARD_PER_SECOND,
  startTime: START_TIME,
  halvingAfterTime: HALVING_AFTER_TIME,
  userDepositFee: USER_DEPOSIT_FEE,
  devDepositFee: DEV_DEPOSIT_FEE,
  devFundAddress: DEV_ADDRESS,
  feeShareFundAddress: LP_ADDRESS,
  marketingFundAddress: COMMUNITY_FUND_ADDRESS,
  foundersFundAddress: FOUNDER_ADDRESS,
  rewardMultipliers: REWARD_MULTIPLIERS,
  userFeeStages: USER_FEE_STAGES,
  devFeeStages: DEV_FEE_STAGES,
  percentLockBonusReward: PERCENT_LOCK_BONUS_REWARD
}]

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

main("MasterInvestor")
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })