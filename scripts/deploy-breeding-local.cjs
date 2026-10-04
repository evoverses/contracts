const {ethers}=require('hardhat');
const {fixture}=require('../test/helpers/breeding.cjs');
(async()=>{
  const network=await ethers.provider.getNetwork();
  if(network.chainId!==31337n) throw new Error('This demo deploys only to a local chain (31337).');
  const f=await fixture();
  console.log(JSON.stringify({chainId:31337,fixturesOnly:true,
    authority:f.manager.target,evoToken:f.token.target,evoNft:f.nft.target,wrapper:f.wrapper.target,
    Breeder_Bertha:f.breeder.target,Hatcher_Hermann:f.hatcher.target},null,2));
})().catch(e=>{console.error(e);process.exitCode=1;});
