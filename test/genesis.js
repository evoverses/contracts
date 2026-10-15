const assert=require('node:assert/strict');
const {ethers,network}=require('hardhat');
const {fixture,deploy,pool,TREASURY}=require('./helpers/breeding.cjs');
const {genesisLeaf,genesisMerkle}=require('../scripts/genesis-merkle.cjs');
const originalPool=require('./fixtures/genesis-species.json');
const legacy=require('./fixtures/genesis-legacy-reference.json');
const wait=async tx=>(await tx).wait();
const fail=(tx,name)=>assert.rejects(tx,error=>{assert.match(error.message,new RegExp(name));return true;});
const word=chunks=>chunks.reduceRight((acc,chunk)=>acc*10000n+BigInt(chunk),0n);
async function register(f,entries){const tree=genesisMerkle(31337,f.nft.target,entries);const configured=await wait(f.hatcher.configureGenesis(tree.root,originalPool));assert.ok(configured.gasUsed<13000000n,'Full Genesis configuration must stay below a 13m gas budget');await wait(f.hatcher.importGenesisEggs(tree.entries));return tree;}

describe('Genesis eggs retain original rules and NFT ownership',function(){
 let f;beforeEach(async()=>{f=await fixture();});
 it('restricts snapshot setup/import and verifies the chain, collection, treatment and date in every proof',async()=>{
  const entries=[{tokenId:3,treated:false,createdAt:0},{tokenId:4,treated:true,createdAt:0}],tree=genesisMerkle(31337,f.nft.target,entries);
  await fail(f.hatcher.connect(f.user).configureGenesis(tree.root,originalPool),'AccessManagedUnauthorized');
  await wait(f.hatcher.configureGenesis(tree.root,originalPool));
  await fail(f.hatcher.configureGenesis(tree.root,originalPool),'InvalidGenesisSnapshot');
  await fail(f.hatcher.connect(f.user).importGenesisEggs(tree.entries),'AccessManagedUnauthorized');
  for(const entry of [{...tree.entries[0],treated:true},{...tree.entries[0],createdAt:1},{...tree.entries[0],tokenId:5}])await fail(f.hatcher.importGenesisEggs([entry]),'InvalidGenesisSnapshot');
  for(const chain of [43113,43114])assert.notEqual(genesisMerkle(chain,f.nft.target,entries).root,tree.root);
  assert.notEqual(genesisMerkle(31337,f.token.target,entries).root,tree.root);
  assert.equal(await f.hatcher.genesisLeaf(3,false,0),genesisLeaf(31337,f.nft.target,entries[0]));
  await wait(f.hatcher.importGenesisEggs(tree.entries));
  assert.equal(await f.hatcher.eggKind(3),1n);assert.equal(await f.hatcher.eggKind(4),1n);
  assert.equal((await f.hatcher.eggs(4)).treated,true);assert.equal((await f.hatcher.eggs(3)).parent1,0n);
  await fail(f.hatcher.importGenesisEggs(tree.entries),'AlreadyKnown');await fail(f.hatcher.adultOf(3),'NotAdult');
 });
 it('rejects already imported adults and nonexistent NFTs atomically',async()=>{
  const tree=genesisMerkle(31337,f.nft.target,[{tokenId:3,treated:false,createdAt:0},{tokenId:1,treated:false,createdAt:0}]);
  await wait(f.hatcher.configureGenesis(tree.root,originalPool));await fail(f.hatcher.importGenesisEggs(tree.entries),'AlreadyKnown');assert.equal(await f.hatcher.known(3),false);
  const other=await fixture(),missing=genesisMerkle(31337,other.nft.target,[{tokenId:9,treated:false,createdAt:0}]);await wait(other.hatcher.configureGenesis(missing.root,originalPool));await fail(other.hatcher.importGenesisEggs(missing.entries),'ERC721NonexistentToken');
 });
 it('lets a newly registered Genesis egg hatch immediately and preserves owner, ID, generation and counters',async()=>{
  const now=(await ethers.provider.getBlock('latest')).timestamp;
  await register(f,[{tokenId:3,treated:false,createdAt:now},{tokenId:4,treated:true,createdAt:0}]);
  const version=await f.hatcher.genesisSpeciesVersion();await wait(f.hatcher.configureSpecies(pool));
  const balance=await f.token.balanceOf(f.user.address);await wait(f.hatcher.connect(f.user).requestHatch(3,{value:await f.wrapper.price()}));
  const egg=await f.hatcher.eggs(3);assert.equal(egg.speciesVersion,version);await fail(f.hatcher.connect(f.user).requestHatch(3,{value:await f.wrapper.price()}),'InvalidEggState');
  await fail(f.hatcher.completeHatch(3),'RandomnessNotReady');await wait(f.wrapper.fulfill(egg.vrfRequestId,123456789n));
  await wait(f.hatcher.connect(f.other).completeHatch(3));const adult=await f.hatcher.adultOf(3);
  assert.equal(adult.generation,0n);assert.equal(adult.totalBreeds,0n);assert.equal(adult.lastBreedTime,0n);assert.equal(adult.attributes.size,10n);assert.equal(adult.stats.health,50n);
  assert.equal(await f.nft.ownerOf(3),f.user.address);assert.equal(await f.nft.nextId(),5109n);assert.equal(await f.token.balanceOf(f.user.address),balance);assert.ok(await f.hatcher.hatchCompletedAt(3)>0n);
  await fail(f.hatcher.completeHatch(3),'InvalidEggState');
 });
 it('preserves prior treatment, charges untreated eggs once, and follows transfers before and during hatching',async()=>{
  await register(f,[{tokenId:3,treated:false,createdAt:0},{tokenId:4,treated:true,createdAt:0}]);
  await fail(f.hatcher.connect(f.user).treat(4),'InvalidEggState');
  await wait(f.nft.connect(f.user).transferFrom(f.user.address,f.other.address,3));
  await fail(f.hatcher.connect(f.user).treat(3),'NotOwner');await fail(f.hatcher.connect(f.user).requestHatch(3,{value:await f.wrapper.price()}),'NotOwner');
  await wait(f.token.mint(f.other.address,ethers.parseEther('250')));await wait(f.token.connect(f.other).approve(f.hatcher.target,ethers.MaxUint256));
  const balance=await f.token.balanceOf(TREASURY);await wait(f.hatcher.connect(f.other).treat(3));assert.equal(await f.token.balanceOf(TREASURY)-balance,ethers.parseEther('250'));await fail(f.hatcher.connect(f.other).treat(3),'InvalidEggState');
  await wait(f.hatcher.connect(f.user).requestHatch(4,{value:await f.wrapper.price()}));const egg=await f.hatcher.eggs(4);await wait(f.nft.connect(f.user).transferFrom(f.user.address,f.other.address,4));
  await fail(f.hatcher.connect(f.other).treat(4),'InvalidEggState');await wait(f.wrapper.fulfill(egg.vrfRequestId,42));await wait(f.hatcher.completeHatch(4));assert.equal(await f.nft.ownerOf(4),f.other.address);
 });
 it('matches the exact explorer-verified original Harry contract for fixed, boundary and random words',async()=>{
  const implementation=await new ethers.ContractFactory(legacy.abi,legacy.bytecode,f.admin).deploy();await implementation.waitForDeployment();
  const init=implementation.interface.encodeFunctionData('initialize');const proxy=await deploy('ERC1967Proxy',implementation.target,init);const reference=new ethers.Contract(proxy.target,legacy.abi,f.admin);
  await wait(reference.setBaseAttributes(originalPool.map(s=>s.id),originalPool.map(s=>[s.enabled?1:0,s.weight,s.malePercentage,s.primaryType,s.secondaryType])));
  const rules=await deploy('GenesisRulesHarness');
  const words=[0n,1n,569n,570n,9999n,ethers.MaxUint256,...[0,1,8,9,44,45,999,1000,2999,3000,4999,5000,9000,9999].map(x=>word([125,x,99,20,50,51,9999,0,1234]))];
  for(let i=0;i<20;i++)words.push(BigInt(ethers.keccak256(ethers.toUtf8Bytes('legacy-genesis-vector-'+i))));
  for(const treated of [false,true])for(const seed of words){const old=await reference.roll(19,treated,seed),actual=await rules.hatch(originalPool,treated,seed);assert.equal(actual[0],old.species);assert.deepEqual(Array.from(actual[1]),Array.from(old.attributes));assert.deepEqual(Array.from(actual[2]),Array.from(old.stats));assert.equal(old.generation,0n);}
 });
});
