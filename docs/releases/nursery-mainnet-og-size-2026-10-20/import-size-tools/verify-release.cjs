'use strict';
const assert=require('node:assert/strict');
const {path,e,addresses:a,save,read,args,publicProvider}=require('./lib.cjs');
function matchTransaction(expected,tx,receipt,block){
 assert.equal(tx.chainId,BigInt(expected.chainId??43114),'wrong transaction chain');assert.equal(tx.from.toLowerCase(),expected.from.toLowerCase(),'wrong sender');
 assert.equal(tx.to?.toLowerCase()??null,expected.to?.toLowerCase()??null,'wrong target');assert.equal(tx.data,expected.data,'wrong calldata/initcode');assert.equal(tx.value,BigInt(expected.value),'wrong value');
 if(expected.nonce!==undefined)assert.equal(tx.nonce,expected.nonce,'deployment nonce changed');
 assert.equal(receipt.status,1,'transaction reverted');assert.equal(receipt.hash.toLowerCase(),tx.hash.toLowerCase());assert.equal(receipt.blockHash,block.hash,'receipt block is no longer canonical');
}
async function verify(out,receiptsFile,local=false){
 const release=read(path.join(out,'unsigned-release.json')),hashes=read(receiptsFile),provider=local?new e.JsonRpcProvider('http://127.0.0.1:18866',43114,{cacheTimeout:-1}):publicProvider(),verified=[];
 if(local){const metadata=await provider.send('hardhat_metadata',[]);assert.equal(metadata.forkedNetwork.chainId,43114);}
 for(const expected of release.transactions){const hash=hashes[String(expected.step)];if(!hash)continue;if(!/^0x[a-f0-9]{64}$/i.test(hash))throw Error('Invalid transaction hash');const [tx,receipt]=await Promise.all([provider.getTransaction(hash),provider.getTransactionReceipt(hash)]);if(!tx||!receipt)throw Error('Transaction not mined yet');const block=await provider.getBlock(receipt.blockNumber);matchTransaction(expected,tx,receipt,block);if(expected.to===null)assert.equal(receipt.contractAddress,e.getCreateAddress({from:expected.from,nonce:expected.nonce}));verified.push({step:expected.step,hash,blockNumber:receipt.blockNumber,blockHash:receipt.blockHash});}
 for(let i=0;i<verified.length;i++)assert.equal(verified[i].step,i+1,'receipts must form a contiguous verified sequence');
 const result={verified,remaining:release.transactions.slice(verified.length).map(x=>({step:x.step,label:x.label})),executionApproved:false,localOnly:local};save(path.join(out,local?'receipt-verification-local.json':'receipt-verification.json'),result);console.log(JSON.stringify({verifiedSteps:verified.length,remainingSteps:result.remaining.length}));return result;
}
module.exports={matchTransaction,verify};
if(require.main===module){const v=args();verify(path.resolve(v.out),path.resolve(v.receipts),v['local-rehearsal']==='1').catch(error=>{console.error(error.shortMessage||error.message);process.exitCode=1;});}
