'use strict';
// Loopback-only, read-only archive gateway for fork tests. Public writes are rejected.
const http=require('node:http'),fs=require('node:fs'),path=require('node:path');
const allowed=new Set(['eth_chainId','net_version','eth_blockNumber','eth_getBlockByNumber','eth_getBlockByHash','eth_getCode','eth_getStorageAt','eth_getBalance','eth_getTransactionCount','eth_getTransactionByHash','eth_getTransactionReceipt','eth_getLogs','eth_call','eth_getProof','eth_feeHistory','eth_gasPrice']);
const upstream=process.env.NURSERY_FORK_RPC_URL||'https://api.avax.network/ext/bc/C/rpc';
const networks={'https://api.avax.network/ext/bc/C/rpc':'0xa86a','https://api.avax-test.network/ext/bc/C/rpc':'0xa869'};
if(!networks[upstream])throw Error('Only official Avalanche mainnet/Fuji archive endpoints are allowed');
const port=Number(process.env.NURSERY_FORK_RPC_PORT||18867);
if(![18867,18869].includes(port))throw Error('Use a dedicated loopback fork port');
const cache=new Map();let queue=Promise.resolve(),lastRequest=0,reads=0;
function cacheable(item){
 if(['eth_chainId','net_version'].includes(item.method))return true;
 if(item.method==='eth_getBlockByHash')return /^0x[0-9a-f]{64}$/i.test(item.params?.[0]||'');
 const index={eth_getBlockByNumber:0,eth_getCode:1,eth_getBalance:1,eth_getTransactionCount:1,eth_getStorageAt:2,eth_getProof:2,eth_call:1}[item.method];
 return index!==undefined&&/^0x[0-9a-f]+$/i.test(item.params?.[index]||'');
}
const cacheFile=path.resolve(process.env.NURSERY_FORK_CACHE||'evidence/archive-cache.json');
const saved=fs.existsSync(cacheFile)?JSON.parse(fs.readFileSync(cacheFile,'utf8')):{};
for(const [key,value] of Object.entries(saved)){const [method,params]=JSON.parse(key);if(cacheable({method,params}))cache.set(key,Promise.resolve(value));else delete saved[key];}
const delay=ms=>new Promise(resolve=>setTimeout(resolve,ms));
function flush(){fs.mkdirSync(path.dirname(cacheFile),{recursive:true});fs.writeFileSync(cacheFile,JSON.stringify(saved));}
process.on('SIGTERM',()=>{flush();process.exit(0);});
// Optional pristine-account cache for not-yet-deployed CREATE addresses. Only a
// pinned block with empty code AND zero account nonce may use zero storage.
// Existing contracts and every other read always go to the archive service.
const pristine=new Set(),pinned=process.env.NURSERY_MAINNET_FORK_BLOCK;
async function initializePristine(){
 const chain=await call({jsonrpc:'2.0',id:0,method:'eth_chainId',params:[]});
 if(chain.result!==networks[upstream])throw Error('Archive chain/cache mismatch');
 const addresses=(process.env.NURSERY_PRISTINE_ADDRESSES||'').split(',').filter(Boolean);
 if(!addresses.length)return;
 if(!/^[0-9]+$/.test(pinned||''))throw Error('Pristine storage cache requires a pinned numeric block');
 const block='0x'+BigInt(pinned).toString(16),verified=[];
 for(const address of addresses){
  if(!/^0x[0-9a-f]{40}$/i.test(address)||BigInt(address)<65536n)throw Error('Invalid pristine account');
  const code=await call({id:1,method:'eth_getCode',params:[address.toLowerCase(),block]});
  const nonce=await call({id:2,method:'eth_getTransactionCount',params:[address.toLowerCase(),block]});
  if(code.result!=='0x'||!/^0x0+$/.test(nonce.result||''))throw Error('Account is not pristine; do not synthesize storage');
  pristine.add(address.toLowerCase()+':'+block);
  verified.push({address,block,code:code.result,nonce:nonce.result});
 }
 const file=path.resolve(process.env.NURSERY_PRISTINE_EVIDENCE||'evidence/pristine-accounts.json');fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,JSON.stringify({method:'Zero storage inferred only for nonce-zero code-empty non-precompile accounts at the pinned block',verified},null,2));
}
async function call(item){
 if(!allowed.has(item.method))return {jsonrpc:'2.0',id:item.id,error:{code:-32601,message:'Read-only fork gateway rejects this method'}};
 if(item.method==='eth_getStorageAt'&&pristine.has(item.params?.[0]?.toLowerCase()+':'+item.params?.[2]))return {jsonrpc:'2.0',id:item.id,result:'0x'+'0'.repeat(64)};
 const key=JSON.stringify([item.method,item.params]),keep=cacheable(item);let value=keep?cache.get(key):undefined;
 if(!value){const pending=queue.then(async()=>{
  await delay(Math.max(0,150-(Date.now()-lastRequest)));lastRequest=Date.now();
  let response;
  for(let attempt=0;attempt<5;attempt++){
   response=await fetch(upstream,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({...item,jsonrpc:'2.0',id:1}),signal:AbortSignal.timeout(15000)});
   if(response.status!==429)break;await response.arrayBuffer();await delay(2000*(attempt+1));
  }
  if(!response.ok)throw Error('Archive HTTP '+response.status);
  const data=await response.json();if(data.error)throw Error(data.error.message);
  if(keep)saved[key]=data.result;if(++reads%25===0){flush();console.log('Verified archive reads: '+reads);}
  return data.result;
 });queue=pending.catch(()=>{});if(keep)cache.set(key,pending);value=pending;}
 try{return {jsonrpc:'2.0',id:item.id,result:await value};}catch(error){cache.delete(key);console.log(item.method,error.message);return {jsonrpc:'2.0',id:item.id,error:{code:-32000,message:'Archive read failed: '+error.message}};}
}
const server=http.createServer(async(req,res)=>{try{if(req.method!=='POST')throw Error('POST only');let body='';for await(const chunk of req){body+=chunk;if(body.length>1048576)throw Error('Request too large');}const data=JSON.parse(body);const result=Array.isArray(data)?await Promise.all(data.map(call)):await call(data);res.writeHead(200,{'Content-Type':'application/json'});res.end(JSON.stringify(result));}catch{res.writeHead(400);res.end('Invalid request');}});
module.exports={cacheable};
if(require.main===module)initializePristine().then(()=>server.listen(port,'127.0.0.1',()=>console.log('Read-only fork gateway ready; pristine pinned accounts: '+pristine.size))).catch(error=>{console.error(error.message);process.exitCode=1;});
