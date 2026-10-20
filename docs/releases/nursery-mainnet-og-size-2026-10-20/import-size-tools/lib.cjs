'use strict';
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const e=require('ethers');
const addresses=Object.freeze({chainId:43114,token:'0x42006Ab57701251B580bDFc24778C43c9ff589A1',nft:'0x4151b8afa10653d304FdAc9a781AFccd45EC164c',authority:'0x204fc7955F816352afDe77D84e4e8719D2C28A0A',treasury:'0x9F64C4bECa7BBda647B9A755B29F7F9687bc4303',wrapper:'0x62Fb87c10A917580cA99AB9a86E213Eb98aa820C',coordinator:'0xE40895D055bccd2053dD0638C9695E326152b1A4',pilotWallet:'0x575CEb9E9ca3d05be1ca18997173C4e3D10f26f1'});
const implementationSlot='0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc';
const hash=value=>crypto.createHash('sha256').update(typeof value==='string'?value:JSON.stringify(value)).digest('hex');
const save=(file,value)=>{fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,JSON.stringify(value,(_,v)=>typeof v==='bigint'?v.toString():v,2)+'\n');};
const read=file=>JSON.parse(fs.readFileSync(file,'utf8'));
function args(){const values={};for(let i=2;i<process.argv.length;i+=2){if(!process.argv[i].startsWith('--')||!process.argv[i+1])throw Error('Use --name value pairs');values[process.argv[i].slice(2)]=process.argv[i+1];}return values;}
function publicProvider(){const req=new e.FetchRequest('https://api.avax.network/ext/bc/C/rpc');req.timeout=30000;return new e.JsonRpcProvider(req,43114,{cacheTimeout:-1,batchMaxCount:40,batchStallTime:25});}
async function publicJson(url,options){const response=await fetch(url,{...options,signal:AbortSignal.timeout(30000)});if(!response.ok)throw Error(`Public source HTTP ${response.status}`);return response.json();}
module.exports={fs,path,e,addresses,implementationSlot,hash,save,read,args,publicProvider,publicJson};
