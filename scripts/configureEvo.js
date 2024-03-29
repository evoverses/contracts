const { ethers } = require("hardhat")
require("dotenv").config()

async function update() {
  const accounts = await ethers.getSigners()

  const contract = await ethers.getContractAt("EvoEgg", "0xa3b63C50F0518aAaCf5cF4720B773e1371D10eBF", accounts[0]);
  //const begin = 30
  //const end = 70
  const evoIds = [1,2,3,4,5,6,7,9,10,11,12,13,15,16,19,20,22,25,26,28,30,33,34,35,37,39,40,42,43,45,46,48,50,51,53,54,55,56,59,61,63,64,66,68,69,70,75,77,78,81,83,84,85,86,89,91,93,96,97,100,102,103,106,109,117,120,122,125]
  const rarityPoints = [10,10,10,6,8,10,10,10,10,10,10,10,10,10,7,7,7,7,7,10,10,7,7,10,7,7,10,10,10,10,10,7,7,7,7,10,7,7,7,4,10,10,7,10,7,10,4,10,10,10,10,10,3,7,10,10,10,7,7,10,7,6,8,10,6,7,10,4]
  const femaleChance = [20, 50, 50, 50, 40, 60, 50, 30, 70, 60, 60, 60, 60, 50, 20, 50, 40, 40, 70, 40, 50, 50, 40, 20, 80, 60, 70, 30, 50, 60, 40, 30, 50, 20, 20, 50, 80, 70, 80, 50, 30, 60, 20, 50, 90, 50, 20, 50, 50, 50, 40, 40, 70, 20, 50, 50, 50, 50, 50, 30, 10, 70, 50, 50, 70, 50, 30, 30]
  const primaryType = [12,11,8,10,9,5,3,1,7,6,4,2,5,11,2,5,6,3,3,4,5,3,5,1,11,8,11,12,6,5,2,9,11,12,7,1,11,11,6,11,8,7,5,8,5,3,3,5,2,4,2,12,10,11,12,8,8,6,6,7,3,10,9,7,10,11,12,9]
  const secondaryType = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,12,4,1,7,5,0,0,11,12,0,8,4,0,0,0,0,0,2,5,1,12,0,1,7,4,9,0,0,2,0,1,0,9,0,0,0,0,0,1,4,0,0,0,0,1,0,5,0,0,0,0,6,0,6]


  //const attributeNestedMap = evoIds.map((id, i) => ([1, rarityPoints[i], femaleChance[i], primaryType[i], secondaryType[i]]))
  //console.log(attributeNestedMap);
  //const tx = await contract.setBaseAttributes(evoIds.slice(60, 70), attributeNestedMap.slice(60, 70));
  //await tx.wait(1);
  const attrStrings = [
    ["Nissel", "Finantis", "Karoite", "Nuvea", "Hodeon", "Eulocelus", "Arnoriel", "Carcoid", "Adhamandra", "Ainepolux", "Kapryno", "Kitsul", "Rattuos", "Beldar", "Firemon", "Obryos", "Lumi", "Onydae", "Skycyx", "Droserace", "Kerval", "Gwenbee", "Shazark", "Krokon", "Clocarstone", "Tokaleaf", "Sunopendra", "Yotnar", "Hikarul", "Aubelyon", "Flint", "Venuserpien", "Espyke", "Mobyd", "Ghorgon", "Mellio", "Fugush", "Morphee", "Lounn", "Uzumebach", "Gemarites", "Methyst", "Tamandu", "Tytan", "Moffunap", "Nymphel", "Allacrow", "Jokull", "Vulpyro", "Fayde", "Ruard", "Caerthos", "Ryomizu", "Obsy", "Dhaek", "Metheo", "Nythe", "Meissa", "Fluozacil", "Cyarabat", "Struthor", "Istral", "Cyzorak", "Kaos", "Athel", "Lamphal", "Geckaiba", "Sauderon"], // 0 species
    ['Normal', 'Chroma', 'Epic'], // 1 rarity
    ['Male', 'Female'], // 2 gender
    ['None', "Water", 'Fire', 'Air', 'Plant', 'Earth', 'Light', 'Dark', 'Mineral', 'Corrupt', 'Ether', 'Bug', 'Monster'], // 3 type
    ["Dauntless", "Executive", "Restless", "Nervous", "Cunning", "Energetic", "Clever", "Confident", "Ignorant", "Arrogant", "Biting", "Aggressive", "Patient", "Mature", "Sensible", "Calm", "Rude", "Cautious", "Curious", "Discrete", "Loyal"] // nature
  ]
  const nameTx = await contract.batchSetAttributeStrings(0, evoIds, attrStrings[0]);
  await nameTx.wait(1);

  //await Promise.all(attrStrings.map(async (s, i) => {
  //  // skip names
  //  if (i === 0) {
  //    return;
  //  }
  //  const tx = await contract.setBaseAttributeStrings(i, Array.from(Array(s.length).fill(0)).map((v, i) => v + i), s);
  //  await tx.wait(1);
  //}))

  //const tx = await contract.batchSetBaseAttributes(evoIds, attributeNestedMap);
  //const tx = await contract.enableSpecies(evoIds)

}

//         _attributes[evo.tokenId].set(0, evo.species);
//         _attributes[evo.tokenId].set(1, evo.attributes.rarity);
//         _attributes[evo.tokenId].set(2, evo.attributes.gender);
//         _attributes[evo.tokenId].set(3, evo.generation);
//         _attributes[evo.tokenId].set(4, evo.attributes.primaryType);
//         _attributes[evo.tokenId].set(5, evo.attributes.secondaryType);
//         _attributes[evo.tokenId].set(6, evo.breeds.total);
//         _attributes[evo.tokenId].set(7, evo.experience);
//         _attributes[evo.tokenId].set(8, evo.attributes.nature);
//         _attributes[evo.tokenId].set(9, evo.stats.attack);
//         _attributes[evo.tokenId].set(10, evo.stats.defense);
//         _attributes[evo.tokenId].set(11, evo.stats.special);
//         _attributes[evo.tokenId].set(12, evo.stats.resistance);
//         _attributes[evo.tokenId].set(13, evo.stats.speed);
//         _attributes[evo.tokenId].set(14, evo.attributes.size);
//         _attributes[evo.tokenId].set(15, evo.breeds.lastBreedTime);
const setEvoL2AttributeStrings = async () => {
  const accounts = await ethers.getSigners()
  //const contract = await ethers.getContractAt("EvoL2", "0x3e9694a37846C864C67253af6F5d1F534ff3BF46", accounts[0]);
  const contract = await ethers.getContractAt("EvoEgg", "0xa3b63C50F0518aAaCf5cF4720B773e1371D10eBF", accounts[0]);
  const attributeId = 999;
  const indicies = Array.from(Array(6)).map((u, i) => i);
  const values = ['species', 'generation', 'parent1', 'parent2', 'treated', 'createdAt']

  //const indicies = Array.from(Array(16)).map((u, i) => i);
  //const values = [
  //  'species',
  //  'rarity',
  //  'gender',
  //  'generation',
  //  'primaryType',
  //  'secondaryType',
  //  'total',
  //  'experience',
  //  'nature',
  //  'attack',
  //  'defense',
  //  'special',
  //  'resistance',
  //  'speed',
  //  'size',
  //  'lastBreedTime'
  //];
  const tx = await contract.batchSetAttributeStrings(attributeId, indicies, values)
  await tx.wait();
}

setEvoL2AttributeStrings()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
