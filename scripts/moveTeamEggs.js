const { ethers } = require("hardhat")
require("dotenv").config()

const oldTreasury = '0x39Af60141b91F7941Eb13AedA2124a61a953b7C0';
const newTreasury = '0x9F64C4bECa7BBda647B9A755B29F7F9687bc4303';
async function move() {
  const accounts = await ethers.getSigners();
  const account = accounts[0]
  const contract = await ethers.getContractAt("EvoEggGen0", "0x75dDd2b19E6f7BEd3Bfe9D2D21dd226C38C0CbC4", account)
  const ids = await contract.tokensOfOwner(oldTreasury)
  const tx = await contract.transferTeamEggs(oldTreasury, newTreasury, ids);
  await tx.wait();
}

move()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
