const { ethers } = require('hardhat');
const TREASURY = '0x9F64C4bECa7BBda647B9A755B29F7F9687bc4303';
const adult = (overrides = {}) => ({
  species: 1, generation: 0, totalBreeds: 0, lastBreedTime: 0,
  attributes: { gender: 0, rarity: 0, primaryType: 1, secondaryType: 0, nature: 7, size: 9 },
  stats: { health: 50, attack: 40, defense: 30, special: 20, resistance: 10, speed: 50 }, ...overrides,
});
const pool = [
  { id: 1, enabled: true, weight: 100, malePercentage: 50, primaryType: 1, secondaryType: 0 },
  { id: 2, enabled: true, weight: 200, malePercentage: 50, primaryType: 1, secondaryType: 2 },
  { id: 3, enabled: false, weight: 0, malePercentage: 25, primaryType: 2, secondaryType: 0 },
];
async function deploy(name, ...args) {
  const c = await (await ethers.getContractFactory(name)).deploy(...args);
  await c.waitForDeployment(); return c;
}
async function fixture() {
  const [admin, user, other] = await ethers.getSigners();
  const manager = await deploy('AccessManager', admin.address);
  const token = await deploy('MockEVO');
  const nft = await deploy('MockEvoNFT', manager.target);
  const wrapper = await deploy('MockNativeVRFWrapper');
  const hatcher = await deploy('Hatcher_Hermann', manager.target, token.target, nft.target, wrapper.target, 3);
  const breeder = await deploy('Breeder_Bertha', manager.target, hatcher.target, wrapper.target, 3);
  await (await hatcher.setBreeder(breeder.target)).wait();
  await (await hatcher.configureSpecies(pool)).wait();
  for (const id of [1,2,3,4]) await (await nft.mintTo(user.address,id)).wait();
  await (await hatcher.importAdult(1,adult())).wait();
  await (await hatcher.importAdult(2,adult({species:2,attributes:{...adult().attributes,gender:1}}))).wait();
  await (await manager.setTargetFunctionRole(nft.target,[nft.interface.getFunction('mintNew').selector],42)).wait();
  await (await manager.grantRole(42,breeder.target,0)).wait();
  await (await token.mint(user.address,ethers.parseEther('100000'))).wait();
  await (await token.connect(user).approve(breeder.target,ethers.MaxUint256)).wait();
  await (await token.connect(user).approve(hatcher.target,ethers.MaxUint256)).wait();
  return {admin,user,other,manager,token,nft,wrapper,hatcher,breeder};
}
async function readyBreed(f,word=42n) {
  const id=await f.breeder.nextRequestId();
  await (await f.breeder.connect(f.user).breed(1,2,ethers.parseEther('1000'),{value:await f.wrapper.price()})).wait();
  const request=await f.breeder.requests(id);
  await (await f.wrapper.fulfill(request.vrfRequestId,word)).wait();
  return id;
}
module.exports={fixture,deploy,adult,pool,readyBreed,TREASURY};
