const { ethers } = require("hardhat")
require("dotenv").config()

const treasury = '0x39Af60141b91F7941Eb13AedA2124a61a953b7C0';
async function move() {
  const accounts = await ethers.getSigners();
  const account = accounts[0]
  const contract = await ethers.getContractAt("EvoEggUpgradeable", "0x75dDd2b19E6f7BEd3Bfe9D2D21dd226C38C0CbC4", account)
  const ids = await contract.tokensOfOwner(accounts[1].address)
  const tx = await contract.transferTeamEggs(accounts[1].address, treasury, ids);
  await tx.wait(1);
}

move()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
