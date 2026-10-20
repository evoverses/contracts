const {test}=require('node:test'),assert=require('node:assert/strict');
const {matchTransaction}=require('./verify-release.cjs'),{adultFromMetadata,cost}=require('./pilot.cjs');
const {cacheable}=require('./fork-rpc.cjs');
test('fork cache never substitutes stale head, fee, pending or canonicality-sensitive reads',()=>{
 for(const method of ['eth_blockNumber','eth_gasPrice','eth_getTransactionReceipt'])assert.equal(cacheable({method,params:['0x123']}),false);
 for(const tag of ['latest','pending','safe','finalized',{blockHash:'0x'+'1'.repeat(64),requireCanonical:true}])assert.equal(cacheable({method:'eth_getStorageAt',params:['0xaddress','0x0',tag]}),false);
 assert.equal(cacheable({method:'eth_getStorageAt',params:['0xaddress','0x0','0x5d6e703']}),true);
});
const expected={from:'0x'+'1'.repeat(40),to:'0x'+'2'.repeat(40),data:'0x1234',value:'0',nonce:7};
const tx={...expected,chainId:43114n,value:0n,hash:'0xhash'},receipt={status:1,hash:'0xhash',blockHash:'0xblock'},block={hash:'0xblock'};
test('independent verification accepts only exact signed transaction and canonical receipt',()=>{matchTransaction(expected,tx,receipt,block);for(const change of [{chainId:43113n},{from:'0xother'},{to:'0xother'},{data:'0x5678'},{value:1n},{nonce:8}])assert.throws(()=>matchTransaction(expected,{...tx,...change},receipt,block));assert.throws(()=>matchTransaction(expected,tx,{...receipt,status:0},block));assert.throws(()=>matchTransaction(expected,tx,receipt,{hash:'reorg'}));matchTransaction({...expected,chainId:43113},{...tx,chainId:43113n},receipt,block);assert.throws(()=>matchTransaction({...expected,chainId:43113},tx,receipt,block));});
const row={metadata:{type:'EVO',species:'kitsul',speciesId:1,gender:'male',rarity:'unknown',chroma:'none',nature:'calm',generation:0,totalBreeds:7,lastBreedTime:'2022-01-01T00:00:00Z',size:10,primaryType:'fire',secondaryType:'none',attack:30,defense:30,special:30,resistance:30,speed:30}},maps={species:['unknown','kitsul'],elements:['none','fire'],natures:['unknown','calm']};
test('adult imports preserve valid metadata and generation-zero price cap',()=>{const adult=adultFromMetadata(row,maps,2000000000);assert.equal(adult.totalBreeds,7);assert.equal(adult.attributes.size,11);assert.equal(cost(adult),2500n*10n**18n);});
test('invalid legacy sizes, unknown gender, wrong species and future timestamps cannot be silently normalized',()=>{for(const change of [{size:75},{size:-110},{size:110},{size:NaN},{gender:'unknown'},{speciesId:0},{lastBreedTime:'2099-01-01T00:00:00Z'}])assert.throws(()=>adultFromMetadata({metadata:{...row.metadata,...change}},maps,2000000000));});
test('all 21 percentage sizes round-trip through imports without changing any other trait',()=>{
 const baseline=adultFromMetadata({...row,metadata:{...row.metadata,size:0}},maps,2000000000);
 for(let raw=0;raw<=20;raw++){
  const percentage=(raw-10)*10,adult=adultFromMetadata({...row,metadata:{...row.metadata,size:percentage}},maps,2000000000);
  assert.equal(adult.attributes.size,raw);assert.equal((adult.attributes.size-10)*10,percentage);
  assert.deepEqual({...adult,attributes:{...adult.attributes,size:10}},baseline);
 }
});
