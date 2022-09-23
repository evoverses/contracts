const { ethers, upgrades } = require("hardhat")
require("dotenv").config()


const L1_NFT_BRIDGE_ABI = [{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_l1Contract","type":"address"},{"indexed":true,"internalType":"address","name":"_l2Contract","type":"address"},{"indexed":true,"internalType":"address","name":"_from","type":"address"},{"indexed":false,"internalType":"address","name":"_to","type":"address"},{"indexed":false,"internalType":"uint256","name":"_tokenId","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"_data","type":"bytes"}],"name":"NFTDepositInitiated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_l1Contract","type":"address"},{"indexed":true,"internalType":"address","name":"_l2Contract","type":"address"},{"indexed":true,"internalType":"address","name":"_from","type":"address"},{"indexed":false,"internalType":"address","name":"_to","type":"address"},{"indexed":false,"internalType":"uint256","name":"_tokenId","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"_data","type":"bytes"}],"name":"NFTWithdrawalFailed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_l1Contract","type":"address"},{"indexed":true,"internalType":"address","name":"_l2Contract","type":"address"},{"indexed":true,"internalType":"address","name":"_from","type":"address"},{"indexed":false,"internalType":"address","name":"_to","type":"address"},{"indexed":false,"internalType":"uint256","name":"_tokenId","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"_data","type":"bytes"}],"name":"NFTWithdrawalFinalized","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Paused","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Unpaused","type":"event"},{"inputs":[{"internalType":"uint32","name":"_depositL2Gas","type":"uint32"}],"name":"configureGas","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"depositL2Gas","outputs":[{"internalType":"uint32","name":"","type":"uint32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_l1Contract","type":"address"},{"internalType":"uint256","name":"_tokenId","type":"uint256"},{"internalType":"uint32","name":"_l2Gas","type":"uint32"}],"name":"depositNFT","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_l1Contract","type":"address"},{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_tokenId","type":"uint256"},{"internalType":"uint32","name":"_l2Gas","type":"uint32"}],"name":"depositNFTTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_l1Contract","type":"address"},{"internalType":"uint256","name":"_tokenId","type":"uint256"},{"internalType":"uint32","name":"_l2Gas","type":"uint32"}],"name":"depositNFTWithExtraData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_l1Contract","type":"address"},{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_tokenId","type":"uint256"},{"internalType":"uint32","name":"_l2Gas","type":"uint32"}],"name":"depositNFTWithExtraDataTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"deposits","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_l1Contract","type":"address"},{"internalType":"address","name":"_l2Contract","type":"address"},{"internalType":"address","name":"_from","type":"address"},{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_tokenId","type":"uint256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"finalizeNFTWithdrawal","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_l1messenger","type":"address"},{"internalType":"address","name":"_l2NFTBridge","type":"address"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"l2NFTBridge","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"messenger","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bytes","name":"","type":"bytes"}],"name":"onERC721Received","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"pairNFTInfo","outputs":[{"internalType":"address","name":"l1Contract","type":"address"},{"internalType":"address","name":"l2Contract","type":"address"},{"internalType":"enum L1NFTBridge.Network","name":"baseNetwork","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"paused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_l1Contract","type":"address"},{"internalType":"address","name":"_l2Contract","type":"address"},{"internalType":"string","name":"_baseNetwork","type":"string"}],"name":"registerNFTPair","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"}]

const PROXY_L1_NFT_BRIDGE = "0x328eb74673Eaa1D2d90A48E8137b015F1B6Ed35d";
const PROXY_L2_NFT_BRIDGE = "0x1A0245f23056132fEcC7098bB011C5C303aE0625";

const EVO_NFT_L1 = "0x454a0E479ac78e508a95880216C06F50bf3C321C";
const EVO_NFT_L2 = "0x3e9694a37846C864C67253af6F5d1F534ff3BF46";

async function bridgeFromAvalancheToBoba() {
  const accounts = await ethers.getSigners();
  const wallet = accounts[0];
  const nft = await ethers.getContractAt("Evo", EVO_NFT_L1, wallet)
  const bridge = await ethers.getContractAt(L1_NFT_BRIDGE_ABI, PROXY_L1_NFT_BRIDGE, wallet);

  const approvedForAll = await nft.isApprovedForAll(wallet.address, PROXY_L1_NFT_BRIDGE);
  if (!approvedForAll) {
    console.log("Giving bridge approval");
    const approvalTx = await nft.setApprovalForAll(PROXY_L1_NFT_BRIDGE, true);
    await approvalTx.wait();
  }
  const tokens = await nft.tokensOfOwner(wallet.address);
  const gasCost = await bridge.depositL2Gas();
  for (let i = 0; i < tokens.length; i++) {
    const nftId = tokens[i].toNumber();

    console.log(`Bridging #${nftId} using ${gasCost.toString()} gas`);
    const tx = await bridge.depositNFTWithExtraData(EVO_NFT_L1, nftId, gasCost);
    await tx.wait();
  }

}

async function bridgeFromBobaToAvalanche() {
  const accounts = await ethers.getSigners();
  const contract = await ethers.getContractAt(L1_NFT_BRIDGE_ABI, PROXY_L2_NFT_BRIDGE, accounts[0])
}

bridgeFromAvalancheToBoba()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })