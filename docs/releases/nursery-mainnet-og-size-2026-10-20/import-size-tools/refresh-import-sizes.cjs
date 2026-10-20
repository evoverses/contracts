'use strict';
const assert=require('node:assert/strict');
const {path,read,save,args,hash}=require('./lib.cjs');
const {adultFromMetadata,sizeFromPercentage,cost}=require('./pilot.cjs');
const v=args(),out=path.resolve(v.out),source=read(path.join(out,'mainnet-inventory.json')),mappings=read(path.join(out,'trait-mappings.json')),pilot=read(path.join(out,'pilot-proposal.json'));
const now=Math.floor(Date.parse(source.createdAt)/1000),records=[];
for(const row of source.inventory){const raw=sizeFromPercentage(row.metadata.size);assert.equal((raw-10)*10,row.metadata.size);records.push({tokenId:row.tokenId,percentage:row.metadata.size,raw,percentageRestored:(raw-10)*10});}
const priorIds=pilot.imports.map(x=>x.tokenId);
pilot.imports=pilot.imports.map(item=>{
 const row=source.inventory.find(x=>x.tokenId===item.tokenId);assert.ok(row);
 const adult=adultFromMetadata(row,mappings,now);
 // Only the unit representation changes in the previously selected pilot.
 assert.deepEqual({...adult,attributes:{...adult.attributes,size:item.adult.attributes.size}},item.adult);
 return {...item,adult,sourceMetadataSha256:hash(row.metadata)};
});
assert.deepEqual(pilot.imports.map(x=>x.tokenId),priorIds);
for(const pair of pilot.pairs){const adults=pair.parents.map(id=>pilot.imports.find(x=>x.tokenId===id).adult);assert.equal((cost(adults[0])+cost(adults[1])).toString(),pair.evoCost);}
pilot.sizeUnits={source:'percentage boost -100..100 in increments of 10',contract:'raw integer 0..20',inverse:'percentage/10+10',forward:'(raw-10)*10',roundTripValidated:true};
pilot.sourceBlock=source.sourceBlock;pilot.sourceHash=source.sourceHash;
pilot.excluded=pilot.excluded.filter(x=>!records.some(r=>r.tokenId===x.tokenId));
save(path.join(out,'pilot-proposal.json'),pilot);
save(path.join(out,'import-size-validation.json'),{sourceBlock:source.sourceBlock,allSizesPreserved:true,count:records.length,pilotIdsUnchanged:true,pilotCostsUnchanged:true,records});
console.log(JSON.stringify({sizesVerified:records.length,pilotIds:priorIds,costsUnchanged:true}));
