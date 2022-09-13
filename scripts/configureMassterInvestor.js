const { ethers } = require("hardhat")
require("dotenv").config()

const PERCENT_LOCK_BONUS_REWARD = Array.from(Array(40).fill(79))


async function update() {
  const accounts = await ethers.getSigners()

  const contract = await ethers.getContractAt("MasterInvestor", "0xF88412Df9F60Bea80bf8846Da6089Eb18eb5F24a", accounts[0])

  const tx = await contract.updateUserLockPercents(PERCENT_LOCK_BONUS_REWARD);
  await tx.wait(1);
}
update()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
