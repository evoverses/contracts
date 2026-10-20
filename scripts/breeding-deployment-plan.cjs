// Prints a proposal only: no provider, signer, RPC calls, deployments or transactions.
const {getAddress}=require('ethers');
const args=process.argv.slice(2);
const options={};
for(let i=0;i<args.length;i+=2){
  if(!args[i].startsWith('--') || args[i+1]===undefined) throw new Error('Use --name value pairs.');
  options[args[i].slice(2)]=args[i+1];
}
const chainId=Number(options['chain-id']||43113);
if(![43113,43114].includes(chainId)) throw new Error('Use Fuji 43113 or Avalanche 43114.');
const live={authority:'0x204fc7955F816352afDe77D84e4e8719D2C28A0A',token:'0x42006Ab57701251B580bDFc24778C43c9ff589A1',nft:'0x4151b8afa10653d304FdAc9a781AFccd45EC164c',wrapper:'0x62Fb87c10A917580cA99AB9a86E213Eb98aa820C'};
const addresses={};
for(const key of ['authority','token','nft','wrapper']){
  const value=options[key]||(chainId===43114?live[key]:undefined);
  addresses[key]=value?getAddress(value):`<FUJI_${key.toUpperCase()}>`;
}
const treasury='0x9F64C4bECa7BBda647B9A755B29F7F9687bc4303';
console.log(JSON.stringify({dryRun:true,chainId,treasury,addresses,
  requiresApprovalBeforeExecution:true,
  prerequisites:[
    'Verify live ABI, implementation, authority, wrapper configuration and deployed dependency versions.',
    'Verify existing Evo.mintNew uses safe mint and confirm its permission role; no collection upgrade is proposed.',
    'Verify and freeze the species order/weights and complete adult metadata snapshot.',
    'Verify original Gen0 egg provenance, treatment directly from the original contract, and all legacy pending hatches; do not trust indexed treatment alone.',
    'Commit the reviewed Genesis Merkle snapshot for the exact chain/collection; unknown dates remain zero sentinels and OG incubation is bypassed.',
    'Review legacy entry points and coordinate authoritative breeding counts before launch.',
    'Independent security review and successful Fuji end-to-end validation.'
  ],
  deploy:[
    {contract:'Hatcher_Hermann',constructorArguments:[addresses.authority,addresses.token,addresses.nft,addresses.wrapper,3]},
    {contract:'Breeder_Bertha',constructorArguments:[addresses.authority,'<HERMANN>',addresses.wrapper,3]}
  ],
  wiring:[
    'Hermann.setBreeder(<BERTHA>) once; verified dependency addresses must match.',
    'Assign Evo.mintNew selector to a dedicated Bertha minter role; preserve existing authorised minters and grant Bertha zero execution delay.',
    'Assign Hermann.configureGenesis and importGenesisEggs to dedicated configuration/verified-import roles; configure the immutable Genesis root and original species pool once, then import proofs in batches of at most 32.',
    'Assign Hermann.importAdult selector to a dedicated verified-data importer role.',
    'Keep configuration, pauses, subsidy policy and authority administration restricted to the administrator.',
    'Hermann.configureGenesis(<REVIEWED_ROOT>, <ORIGINAL_GENESIS_POOL>) creates a frozen species version. Hermann.configureSpecies(<REVIEWED_BRED_POOL>) may then create a separate immutable version for bred eggs.',
    'Import existing adult traits/breed history exactly once; never import unknown-gender eggs as adults.'
  ],
  verification:[
    'Verify both non-proxy NPCs using the exact constructor arguments and compiler 0.8.28/London/optimizer200.',
    'Verify Evo implementation separately; do not replace the collection, token, Brenda or authority proxies.',
    'Confirm fixed treasury, dependency getters, NPC wiring, mint/import roles and subsidy=false.',
    'Smoke-test quotes and permissions read-only before enabling UI.'
  ]},null,2));
