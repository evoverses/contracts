'use strict';
const {path,e,addresses:a,save,read,args,hash}=require('./lib.cjs');
// Metadata stores percent boosts; contracts store a raw 0-20 roll. Never round
// or clamp a legacy value: all existing sizes must survive the round trip.
function sizeFromPercentage(value){
 if(!Number.isSafeInteger(value)||value < -100||value > 100||value%10!==0)throw Error('Invalid percentage size metadata');
 return value/10+10;
}
function adultFromMetadata(row,mappings,now){
 const m=row.metadata;if(m.type!=='EVO')throw Error('Eggs cannot be imported as adults');
 const int=(value,max)=>{if(!Number.isSafeInteger(value)||value<0||value>max)throw Error('Invalid numeric adult metadata');return value;};
 const species=int(m.speciesId??mappings.species.indexOf(m.species.toLowerCase()),mappings.species.length-1);
 if(species===0||mappings.species[species]!==m.species.toLowerCase())throw Error('Species identity mismatch');
 const gender={female:0,male:1}[m.gender];if(gender===undefined)throw Error('Unknown gender');
 const rarity=m.rarity==='epic'?2:m.chroma==='chroma'?1:m.chroma==='none'?0:undefined;if(rarity===undefined)throw Error('Unsupported legacy rarity');
 const primaryType=mappings.elements.indexOf(m.primaryType),secondaryType=mappings.elements.indexOf(m.secondaryType),nature=mappings.natures.indexOf(m.nature)-1;
 if(primaryType<1||secondaryType<0||nature<0)throw Error('Unknown element or nature');
 const generation=int(m.generation,255),totalBreeds=int(m.totalBreeds,Number.MAX_SAFE_INTEGER);
 if(generation!==0&&totalBreeds>5)throw Error('Breed history exceeds generation cap');
 const lastBreedTime=m.lastBreedTime?Math.floor(Date.parse(m.lastBreedTime+'Z'.repeat(!/Z$|[+-]\d\d:\d\d$/.test(m.lastBreedTime)))/1000):0;
 if(!Number.isSafeInteger(lastBreedTime)||lastBreedTime<0||lastBreedTime>now||(totalBreeds>0&&lastBreedTime===0))throw Error('Unverified breeding date');
 return {species,generation,totalBreeds,lastBreedTime,attributes:{gender,rarity,primaryType,secondaryType,nature,size:sizeFromPercentage(m.size)},stats:{health:50,...Object.fromEntries(['attack','defense','special','resistance','speed'].map(key=>[key,int(m[key],50)]))}};
}
const cost=adult=>500n*10n**18n*2n**BigInt(adult.generation)*BigInt(1+(adult.generation===0?Math.min(4,adult.totalBreeds):adult.totalBreeds));
function selectPilot(out){
 const s=read(path.join(out,'mainnet-inventory.json')),m=read(path.join(out,'trait-mappings.json')),g=read(path.join(out,'genesis-snapshot.json'));
 const now=Math.floor(Date.parse(s.createdAt)/1000),valid=[],excluded=[];
 for(const row of s.inventory){try{const adult=adultFromMetadata(row,m,now);if(!g.species.some(x=>x.id===adult.species))throw Error('Species is absent from the reviewed pool');valid.push({tokenId:row.tokenId,adult,sourceMetadataSha256:hash(row.metadata)});}catch(error){excluded.push({tokenId:row.tokenId,reason:error.message});}}
 const eligible=valid.filter(x=>(x.adult.generation===0||x.adult.totalBreeds<5)&&now>=x.adult.lastBreedTime+Math.max(1,7-x.adult.generation)*86400);
 const pairs=[];for(let i=0;i<eligible.length;i++)for(let j=i+1;j<eligible.length;j++){const left=eligible[i],right=eligible[j];if(left.adult.attributes.gender===right.adult.attributes.gender)continue;const x=left.adult.attributes,y=right.adult.attributes;if(![x.primaryType,x.secondaryType].filter(Boolean).some(t=>[y.primaryType,y.secondaryType].includes(t)))continue;pairs.push({parents:[left.tokenId,right.tokenId],evoCost:(cost(left.adult)+cost(right.adult)).toString()});}
 pairs.sort((x,y)=>BigInt(x.evoCost)<BigInt(y.evoCost)?-1:BigInt(x.evoCost)>BigInt(y.evoCost)?1:Number(BigInt(x.parents[0])-BigInt(y.parents[0])));
 const chosen=[],used=new Set();for(const pair of pairs)if(pair.parents.every(id=>!used.has(id))){chosen.push(pair);pair.parents.forEach(id=>used.add(id));if(chosen.length===2)break;}
 if(chosen.length<2)throw Error('Two disjoint compatible pilot pairs could not be verified');
 const result={sourceBlock:s.sourceBlock,sourceHash:s.sourceHash,wallet:a.pilotWallet,proposedOnly:true,approvedNftIds:false,approvedSpendingCap:false,imports:valid.filter(x=>used.has(x.tokenId)),pairs:chosen,breedEvoTotal:chosen.reduce((sum,p)=>sum+BigInt(p.evoCost),0n).toString(),optionalTreatmentEvoEach:e.parseEther('250').toString(),ownedGenesis: g.manifest.entries.filter(x=>x.ownerAtSnapshot.toLowerCase()===a.pilotWallet.toLowerCase()),excluded,metadataAuthoritativeForImport:false,requires:'Confirm legacy breeding writer is stopped/reconciled before final snapshot approval.'};
 save(path.join(out,'pilot-proposal.json'),result);console.log(JSON.stringify({pairs:chosen,breedEvoTotal:result.breedEvoTotal,ownedGenesis:result.ownedGenesis.length,excluded:excluded.length}));return result;
}
module.exports={adultFromMetadata,cost,selectPilot,sizeFromPercentage};
if(require.main===module){const v=args();try{selectPilot(path.resolve(v.out));}catch(error){console.error(error.message);process.exitCode=1;}}
