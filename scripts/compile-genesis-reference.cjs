const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sourceFile=process.env.GENESIS_VERIFIED_SOURCE || path.resolve(__dirname,'../../../evoverses/Documentation/nursery-gen0-investigation-evidence-2026-10-15/gen0-legacy-verified-source.json');
const verified=JSON.parse(fs.readFileSync(sourceFile)).result[0];let source=verified.SourceCode;const input=JSON.parse(source.startsWith('{{')?source.slice(1,-1):source);
input.sources['GenesisLegacyReference.sol']={content:`// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "contracts/npc/HatcherHarry/HatcherHarryAvalanche.sol";
contract GenesisLegacyReference is HatcherHarryAvalanche {
function roll(uint256 tokenId,bool treated,uint256 word) external view returns(Evo memory){
(uint256[] memory ids,uint256[] memory thresholds,uint256 total)=rarityConfig();
uint256[] memory chunks=chunkWord(word,10_000,14);
return geneRoll(tokenId,treated,speciesRoll(chunks[0],thresholds,ids,total),chunks);
}}
`};input.settings={optimizer:{enabled:true,runs:200},outputSelection:{'*':{'*':['abi','evm.bytecode.object']}}};
const compiler=require(process.env.GENESIS_LEGACY_COMPILER || 'solc-legacy');const output=JSON.parse(compiler.compile(JSON.stringify(input)));const errors=(output.errors||[]).filter(x=>x.severity==='error');if(errors.length)throw Error(errors.map(x=>x.formattedMessage).join('\n'));
const contract=output.contracts['GenesisLegacyReference.sol'].GenesisLegacyReference;
const dir=path.resolve(__dirname,'../test/fixtures');fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(dir+'/genesis-legacy-reference.json',JSON.stringify({compiler:compiler.version(),verifiedImplementation:'0xA1005f761a55CfB8FBfaf58eb35c9cA881aaacd6',verifiedSourceSha256:crypto.createHash('sha256').update(verified.SourceCode).digest('hex'),abi:contract.abi,bytecode:'0x'+contract.evm.bytecode.object}));
console.log('Compiled the exact verified legacy implementation with a read-only seeded-roll test entrypoint.');
