const { AbiCoder, keccak256, id, concat } = require('ethers');
const coder = AbiCoder.defaultAbiCoder();
function genesisLeaf(chainId, collection, item) {
  return keccak256(keccak256(coder.encode(['bytes32','uint256','address','uint256','bool','uint256'],[id('EVOVERSES_GENESIS_V1'),chainId,collection,item.tokenId,item.treated,item.createdAt])));
}
function genesisMerkle(chainId, collection, entries) {
  if (!entries.length || new Set(entries.map(x => String(x.tokenId))).size !== entries.length) throw Error('Invalid Genesis entries');
  const levels = [entries.map(item => genesisLeaf(chainId,collection,item))];
  while (levels.at(-1).length > 1) {
    const prior=levels.at(-1), next=[];
    for(let i=0;i<prior.length;i+=2) next.push(i+1<prior.length?keccak256(concat(BigInt(prior[i])<BigInt(prior[i+1])?[prior[i],prior[i+1]]:[prior[i+1],prior[i]])):prior[i]);
    levels.push(next);
  }
  return {root:levels.at(-1)[0],entries:entries.map((item,index)=>{const proof=[];for(let level=0;level<levels.length-1;level++){const sibling=index^1;if(sibling<levels[level].length)proof.push(levels[level][sibling]);index=Math.floor(index/2);}return {...item,proof};})};
}
module.exports={genesisLeaf,genesisMerkle};
