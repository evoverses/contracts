const { ethers } = require("hardhat")
require("dotenv").config()

const REWARD_MULTIPLIERS = Array.prototype.concat(
  [256, 128, 96, 48, 32, 28, 24, 20, 16, 12, 12, 8, 8, 6, 6, 4, 4 ],
  Array(33).fill(2)
)
const REWARD_PER_SECOND = ethers.utils.parseEther('0.5')

async function update() {
  const accounts = await ethers.getSigners()

  const contract = await ethers.getContractAt("MasterInvestor", "0xF88412Df9F60Bea80bf8846Da6089Eb18eb5F24a", accounts[0])

  const tx = await contract.updateRewardPerSecond(REWARD_PER_SECOND);
  const tx2 = await contract.updateRewardMultipliers(REWARD_MULTIPLIERS);
  await tx2.wait(1);
}

update()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
