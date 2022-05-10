const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

const GOV_TOKEN = '0x5b747e23a9E4c509dd06fbd2c0e3cB8B846e398F'
const REWARD_PER_SECOND = ethers.utils.parseEther("0.5");
const START_TIME = Date.parse('Tue May 04 2022 4:00:00 GMT') / 1000;
const HALVING_AFTER_TIME = 7 * 24 * 60 * 60; // 1 epoch (1 week | 604800)

const REWARD_MULTIPLIERS = [ 128, 64, 48, 32, 28, 24, 20, 16, 14, 12, 10, 9, 8, 7, 6, 5 ]
  .concat(Array(8).fill(4), Array(28).fill(2))

const PERCENT_LOCK_BONUS_REWARD = [...Array(48).keys()].map((_, i) => i * 2 + 1 ).reverse()

const DEV_FEE_STAGES = [25, 8, 4, 2, 1, 5, 25, 1];
const USER_FEE_STAGES = [75, 92, 96, 98, 99, 995, 9975, 9999];
const USER_DEPOSIT_FEE = 1;
const DEV_DEPOSIT_FEE = 1;

const DEV_ADDRESS = '0x946d5Cb6C3A329BD859e5C3Ba01767457Ea2DcA2';
const LP_ADDRESS = '0xA511794340216a49Ac8Ae4b5495631CcD80BCfcc';
const COMMUNITY_FUND_ADDRESS = '0xA511794340216a49Ac8Ae4b5495631CcD80BCfcc';
const FOUNDER_ADDRESS = '0x946d5Cb6C3A329BD859e5C3Ba01767457Ea2DcA2';

const args = [{
  govToken: GOV_TOKEN,
  rewardPerSecond: REWARD_PER_SECOND,
  startTime: START_TIME,
  halvingAfterTime: HALVING_AFTER_TIME,
  userDepositFee: USER_DEPOSIT_FEE,
  devDepositFee: DEV_DEPOSIT_FEE,
  devAddress: DEV_ADDRESS,
  lpAddress: LP_ADDRESS,
  communityFundAddress: COMMUNITY_FUND_ADDRESS,
  founderAddress: FOUNDER_ADDRESS,
  rewardMultipliers: REWARD_MULTIPLIERS,
  userFeeStages: USER_FEE_STAGES,
  devFeeStages: DEV_FEE_STAGES,
  percentLockBonusReward: PERCENT_LOCK_BONUS_REWARD
}]

async function main(name) {
  console.log("Starting deployment...")
  const contractFactory = await ethers.getContractFactory(name)
  console.log("Deploying", name)
  const args = [{
    govToken: GOV_TOKEN,
    rewardPerSecond: REWARD_PER_SECOND,
    startTime: START_TIME,
    halvingAfterTime: HALVING_AFTER_TIME,
    userDepositFee: USER_DEPOSIT_FEE,
    devDepositFee: DEV_DEPOSIT_FEE,
    devAddress: DEV_ADDRESS,
    lpAddress: LP_ADDRESS,
    communityFundAddress: COMMUNITY_FUND_ADDRESS,
    founderAddress: FOUNDER_ADDRESS,
    rewardMultipliers: REWARD_MULTIPLIERS,
    userFeeStages: USER_FEE_STAGES,
    devFeeStages: DEV_FEE_STAGES,
    percentLockBonusReward: PERCENT_LOCK_BONUS_REWARD
  }]
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