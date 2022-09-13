const { Contract, Provider } = require('ethers-multicall');
const { ethers } = require('ethers')
const abi = require('../artifacts/contracts/npc/MasterInvestor.sol/MasterInvestor.json');

const provider = new ethers.providers.JsonRpcProvider("https://api.avax.network/ext/bc/C/rpc")
const masterInvestor = "0xD782Cf9F04E24CAe4953679EBF45ba34509F105C";

async function test() {
  const ethcallProvider = new Provider(provider, 43114);

  //await ethcallProvider.init(); // Only required when `chainId` is not provided in the `Provider` constructor

  const contract = new Contract(masterInvestor, abi.abi);

  const uniswapDaiPool = '0x2a1530c4c41db0b0b2bb646cb5eb1a67b7158667';

  const plCall = contract.poolLength();
  const rpsCall = contract.REWARD_PER_SECOND();

  const [pl, rps] = await ethcallProvider.all([plCall, rpsCall]);

  console.log('plCall', pl.toString());
  console.log('rpsCall', rps.toString());

}
test()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
