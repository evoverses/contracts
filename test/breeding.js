const assert=require('node:assert/strict');
const {ethers,network}=require('hardhat');
const {fixture,deploy,adult,pool,readyBreed,TREASURY}=require('./helpers/breeding.cjs');
const E=ethers.parseEther;
const wait=async p=>(await p).wait();
const fail=async(p,name)=>assert.rejects(p,e=>{if(name)assert.match(e.message,new RegExp(name));return true;});
const advance=async seconds=>{await network.provider.send('evm_increaseTime',[seconds]);await network.provider.send('evm_mine');};

describe('Bertha / Hermann local integration',function(){
  let f;
  beforeEach(async()=>{f=await fixture();});

  it('charges the 500 EVO base and Gen0 cap at four previous breeds',async()=>{
    const rules=await deploy('BreedingRulesHarness');
    for(const [count,cost] of [[0,500],[1,1000],[2,1500],[3,2000],[4,2500],[5,2500],[99,2500]]){
      assert.equal(await rules.cost(adult({totalBreeds:count})),E(String(cost)));
    }
    assert.equal(await rules.cost(adult({generation:1,totalBreeds:2})),E('3000'));
  });

  it('escrows EVO, allocates a new NFT ID, pays only treasury and settles exactly once',async()=>{
    const before=await f.token.balanceOf(TREASURY);
    const id=await readyBreed(f);
    assert.equal(await f.token.balanceOf(TREASURY),before);
    assert.equal(await f.breeder.escrowedEvo(),E('1000'));
    await wait(f.breeder.connect(f.other).completeBreed(id));
    const r=await f.breeder.requests(id);
    assert.equal(r.tokenId,5109n);
    assert.equal(await f.nft.ownerOf(r.tokenId),f.user.address);
    assert.equal(await f.token.balanceOf(TREASURY)-before,E('1000'));
    assert.equal(await f.breeder.escrowedEvo(),0n);
    assert.equal((await f.hatcher.adultOf(1)).totalBreeds,1n);
    assert.equal((await f.hatcher.eggs(5109)).status,1n);
    await fail(f.breeder.completeBreed(id),'InvalidRequestState');
    assert.equal(await f.nft.nextId(),5110n);
  });

  it('rejects forged receiver callbacks and unsolicited NFTs without losing ownership',async()=>{
    await fail(f.breeder.onERC721Received(f.breeder.target,ethers.ZeroAddress,999,'0x'),'InvalidMintCallback');
    await fail(f.nft.connect(f.user)['safeTransferFrom(address,address,uint256)'](f.user.address,f.breeder.target,1),'InvalidMintCallback');
    assert.equal(await f.nft.ownerOf(1),f.user.address);
    // Even the configured collection cannot inject a mint outside completion.
    await fail(f.nft.mintTo(f.breeder.target,100),'InvalidMintCallback');
    await fail(f.nft.ownerOf(100));
  });

  it('uses callback ID despite unrelated mints and registers before recipient delivery',async()=>{
    await wait(f.manager.grantRole(42,f.admin.address,0));
    await wait(f.nft.mintNew(f.other.address));
    const id=await readyBreed(f);
    const receipt=await wait(f.breeder.completeBreed(id));
    assert.equal((await f.breeder.requests(id)).tokenId,5110n);
    assert.equal(await f.nft.ownerOf(5110),f.user.address);
    assert.equal(await f.nft.balanceOf(f.breeder.target),0n);
    const transfers=receipt.logs.filter(x=>x.address===f.nft.target).map(x=>{try{return f.nft.interface.parseLog(x);}catch{return null;}}).filter(x=>x?.name==='Transfer');
    assert.equal(transfers.length,2);
    assert.equal(transfers[0].args.from,ethers.ZeroAddress);
    assert.equal(transfers[0].args.to,f.breeder.target);
    assert.equal(transfers[1].args.from,f.breeder.target);
    assert.equal(transfers[1].args.to,f.user.address);
  });

  it('rolls back missing, duplicate and malformed mint callbacks without consuming the request or seed',async()=>{
    const id=await readyBreed(f,123n);
    for(const mode of [1,2,3,4]) {
      await wait(f.nft.setCallbackMode(mode));
      await fail(f.breeder.completeBreed(id),'InvalidMintCallback');
      assert.equal((await f.breeder.requests(id)).status,2n);
      assert.equal((await f.breeder.randomness(1)).word,123n);
      assert.equal(await f.nft.nextId(),5109n);
      assert.equal(await f.nft.balanceOf(f.breeder.target),0n);
      assert.equal(await f.hatcher.known(5109),false);
      assert.equal((await f.hatcher.adultOf(1)).totalBreeds,0n);
      assert.equal(await f.breeder.escrowedEvo(),E('1000'));
    }
    await wait(f.nft.setCallbackMode(0));
    await wait(f.breeder.completeBreed(id));
    assert.equal(await f.nft.ownerOf(5109),f.user.address);
    assert.equal((await f.hatcher.adultOf(1)).totalBreeds,1n);
  });

  it('rejects ineligible/unimported parents, incorrect ownership and duplicate parent requests before payment',async()=>{
    const balance=await f.token.balanceOf(f.user.address);
    await fail(f.breeder.connect(f.user).breed(1,1,E('1000'),{value:E('.01')}),'IncompatibleParents');
    await fail(f.breeder.connect(f.user).breed(1,3,E('1000'),{value:E('.01')}),'NotAdult');
    await fail(f.breeder.connect(f.other).breed(1,2,E('1000'),{value:E('.01')}),'NotOwner');
    assert.equal(await f.token.balanceOf(f.user.address),balance);
    await wait(f.breeder.connect(f.user).prepareBreed(1,2,E('1000')));
    await fail(f.breeder.connect(f.user).prepareBreed(1,2,E('1000')),'ParentUnavailable');
  });

  it('checks price slippage, AVAX funding and wrapper availability atomically',async()=>{
    const balance=await f.token.balanceOf(f.user.address);
    await fail(f.breeder.connect(f.user).breed(1,2,E('999'),{value:E('.01')}),'PriceExceedsLimit');
    await fail(f.breeder.connect(f.user).breed(1,2,E('1000'),{value:0}),'InsufficientNativePayment');
    await wait(f.wrapper.setDisabled(true));
    await fail(f.breeder.connect(f.user).breed(1,2,E('1000'),{value:E('.01')}));
    assert.equal(await f.token.balanceOf(f.user.address),balance);
    assert.equal(await f.hatcher.parentReservation(1),0n);
    assert.equal(await f.breeder.nextRequestId(),1n);
  });

  it('refunds a prepared request and releases parents while paused, but never after VRF commitment',async()=>{
    const balance=await f.token.balanceOf(f.user.address);
    await wait(f.breeder.connect(f.user).prepareBreed(1,2,E('1000')));
    await fail(f.breeder.connect(f.other).cancelBreed(1),'NotRequester');
    await wait(f.breeder.pause());
    await wait(f.breeder.connect(f.user).cancelBreed(1));
    assert.equal(await f.token.balanceOf(f.user.address),balance);
    assert.equal(await f.hatcher.parentReservation(1),0n);
    await wait(f.breeder.unpause());
    await readyBreed(f);
    await fail(f.breeder.connect(f.user).cancelBreed(2),'InvalidRequestState');
    await fail(f.breeder.connect(f.user).commitBreed(2,{value:E('.01')}),'InvalidRequestState');
  });

  it('permits pre-commit refund after a parent sale, and binds post-commit offspring to the original wallet',async()=>{
    await wait(f.breeder.connect(f.user).prepareBreed(1,2,E('1000')));
    await wait(f.nft.connect(f.user).transferFrom(f.user.address,f.other.address,1));
    await fail(f.breeder.connect(f.user).commitBreed(1,{value:E('.01')}),'NotRequester');
    await wait(f.breeder.connect(f.other).cancelBreed(1));
    await wait(f.nft.connect(f.other).transferFrom(f.other.address,f.user.address,1));
    const id=await readyBreed(f);
    await wait(f.nft.connect(f.user).transferFrom(f.user.address,f.other.address,1));
    await wait(f.breeder.connect(f.other).completeBreed(id));
    assert.equal(await f.nft.ownerOf(5109),f.user.address);
  });

  it('accepts zero randomness, rejects forged callbacks and ignores duplicate callbacks within the gas budget',async()=>{
    await wait(f.breeder.connect(f.user).breed(1,2,E('1000'),{value:E('.01')}));
    await fail(f.breeder.rawFulfillRandomWords(1,[9]),'OnlyWrapper');
    await wait(f.breeder.pause());
    await wait(f.wrapper.fulfillWithGas(1,0,100000));
    await wait(f.wrapper.fulfill(1,999));
    assert.equal((await f.breeder.randomness(1)).word,0n);
    assert.equal((await f.breeder.randomness(1)).fulfilled,true);
    await fail(f.breeder.completeBreed(1),'EnforcedPause');
    await wait(f.breeder.unpause());
    await wait(f.breeder.completeBreed(1));
  });

  it('retries failed mint/treasury transfers with the same seed, without double charging or counting',async()=>{
    const id=await readyBreed(f,99n);
    await wait(f.nft.setFailMint(true));
    await fail(f.breeder.completeBreed(id));
    assert.equal((await f.breeder.requests(id)).status,2n);
    assert.equal((await f.hatcher.adultOf(1)).totalBreeds,0n);
    await wait(f.nft.setFailMint(false));
    await wait(f.token.setFailTransfers(true));
    await fail(f.breeder.completeBreed(id),'SafeERC20FailedOperation');
    assert.equal(await f.nft.nextId(),5109n);
    assert.equal(await f.breeder.escrowedEvo(),E('1000'));
    await wait(f.token.setFailTransfers(false));
    await wait(f.breeder.completeBreed(id));
    assert.equal((await f.breeder.randomness(1)).word,99n);
    assert.equal((await f.hatcher.adultOf(1)).totalBreeds,1n);
    await fail(f.breeder.connect(f.user).prepareBreed(1,2,E('2000')),'ParentUnavailable');
  });

  it('blocks receiver reentrancy and prevents a rejecting wallet from refunding or rerolling its result',async()=>{
    const receiver=await deploy('RejectingBreeder');
    await wait(f.nft.connect(f.user).transferFrom(f.user.address,receiver.target,1));
    await wait(f.nft.connect(f.user).transferFrom(f.user.address,receiver.target,2));
    await wait(f.token.mint(receiver.target,E('1000')));
    await wait(receiver.execute(f.token.target,f.token.interface.encodeFunctionData('approve',[f.breeder.target,E('1000')])));
    await wait(receiver.execute(f.breeder.target,f.breeder.interface.encodeFunctionData('breed',[1,2,E('1000')]),{value:E('.01')}));
    await wait(f.wrapper.fulfill(1,987));
    await fail(f.breeder.completeBreed(1),'reject mint');
    await fail(receiver.execute(f.breeder.target,f.breeder.interface.encodeFunctionData('cancelBreed',[1])));
    assert.equal(await f.breeder.escrowedEvo(),E('1000'));
    await wait(receiver.setReject(false));
    await wait(receiver.setRegistry(f.hatcher.target));
    await wait(receiver.setAttack(f.breeder.target,f.breeder.interface.encodeFunctionData('completeBreed',[1])));
    await wait(f.breeder.completeBreed(1));
    assert.equal(await receiver.attempted(),true);
    assert.equal(await receiver.reentrySucceeded(),false);
    assert.equal(await f.nft.ownerOf(5109),receiver.target);
    assert.equal((await f.breeder.randomness(1)).word,987n);
    assert.equal((await f.hatcher.adultOf(1)).totalBreeds,1n);
  });

  it('keeps failed token transfers from creating funded requests',async()=>{
    await wait(f.token.setFailTransfers(true));
    await fail(f.breeder.connect(f.user).prepareBreed(1,2,E('1000')),'SafeERC20FailedOperation');
    assert.equal(await f.breeder.escrowedEvo(),0n);
    assert.equal(await f.hatcher.parentReservation(1),0n);
  });

  it('enforces five breeds for non-Gen0 and generation-specific recovery boundaries',async()=>{
    await wait(f.hatcher.importAdult(3,adult({generation:1,totalBreeds:5})));
    await fail(f.breeder.connect(f.user).prepareBreed(3,2,E('10000')),'ParentUnavailable');
    const block=await ethers.provider.getBlock('latest');
    await wait(f.hatcher.importAdult(4,adult({generation:6,lastBreedTime:block.timestamp})));
    await fail(f.breeder.connect(f.user).prepareBreed(4,2,E('100000')),'ParentUnavailable');
    await advance(86400);
    await wait(f.breeder.connect(f.user).prepareBreed(4,2,E('100000')));
  });

  it('incubates three days, charges treatment to treasury once, locks treatment before rarity and hatches the same ID',async()=>{
    await wait(f.breeder.completeBreed(await readyBreed(f)));
    await fail(f.hatcher.connect(f.user).requestHatch(5109,{value:E('.01')}),'StillIncubating');
    await fail(f.hatcher.connect(f.other).treat(5109),'NotOwner');
    const before=await f.token.balanceOf(TREASURY);
    await wait(f.hatcher.connect(f.user).treat(5109));
    assert.equal(await f.token.balanceOf(TREASURY)-before,E('250'));
    await fail(f.hatcher.connect(f.user).treat(5109),'InvalidEggState');
    await advance(3*86400);
    await wait(f.hatcher.connect(f.user).requestHatch(5109,{value:E('.01')}));
    const egg=await f.hatcher.eggs(5109);
    await fail(f.hatcher.connect(f.user).requestHatch(5109,{value:E('.01')}),'InvalidEggState');
    await fail(f.hatcher.connect(f.user).treat(5109),'InvalidEggState');
    await wait(f.hatcher.pause());
    await wait(f.wrapper.fulfillWithGas(egg.vrfRequestId,123456789012345n,100000));
    await wait(f.hatcher.unpause());
    await wait(f.hatcher.connect(f.other).completeHatch(5109));
    assert.equal((await f.hatcher.eggs(5109)).status,3n);
    assert.equal((await f.hatcher.adultOf(5109)).stats.health,50n);
    assert.equal(await f.nft.ownerOf(5109),f.user.address);
    assert.equal(await f.nft.nextId(),5110n);
    await fail(f.hatcher.completeHatch(5109),'InvalidEggState');
  });

  it('does not allow treatment after an untreated hatch has requested randomness',async()=>{
    await wait(f.breeder.completeBreed(await readyBreed(f)));
    await advance(3*86400);
    await wait(f.hatcher.connect(f.user).requestHatch(5109,{value:E('.01')}));
    await fail(f.hatcher.connect(f.user).treat(5109),'InvalidEggState');
  });

  it('preserves immutable imported traits, configuration versions and one-time wiring',async()=>{
    await fail(f.hatcher.connect(f.other).importAdult(3,adult()),'AccessManagedUnauthorized');
    await fail(f.hatcher.importAdult(1,adult()),'AlreadyKnown');
    await fail(f.hatcher.importAdult(3,adult({attributes:{...adult().attributes,gender:2}})),'InvalidAdult');
    await fail(f.hatcher.setBreeder(f.breeder.target),'InvalidConfiguration');
    const id=await readyBreed(f,900n);
    await wait(f.hatcher.configureSpecies([{...pool[0],malePercentage:0}]));
    await wait(f.breeder.completeBreed(id));
    assert.equal((await f.hatcher.eggs(5109)).speciesVersion,1n);
    await fail(f.hatcher.connect(f.other).recordEgg(6000,1,2,1,id,0,0),'OnlyBreeder');
    await advance(3*86400);
    await wait(f.hatcher.connect(f.user).requestHatch(5109,{value:E('.01')}));
    const egg=await f.hatcher.eggs(5109);
    await wait(f.wrapper.fulfill(egg.vrfRequestId,10000));
    await wait(f.hatcher.completeHatch(5109));
    assert.equal((await f.hatcher.adultOf(5109)).attributes.gender,1n); // old version's 50%, not new 0%

  });

  it('credits only AVAX overpayment, protects it from admin withdrawals and supports an explicitly funded subsidy',async()=>{
    const id=await readyBreed(f);
    await wait(f.breeder.completeBreed(id));
    await advance(7*86400);
    await wait(f.breeder.connect(f.user).breed(1,2,E('2000'),{value:E('.02')}));
    assert.equal(await f.breeder.nativeCredit(f.user.address),E('.01'));
    await wait(f.breeder.withdrawUnusedSubsidy());
    assert.equal(await ethers.provider.getBalance(f.breeder.target),E('.01'));
    const before=await ethers.provider.getBalance(f.other.address);
    await wait(f.breeder.connect(f.user).withdrawNativeCredit(f.other.address));
    assert.equal(await ethers.provider.getBalance(f.other.address)-before,E('.01'));
    await wait(f.breeder.setVrfSubsidised(true));
    await wait(f.hatcher.importAdult(3,adult()));
    await wait(f.hatcher.importAdult(4,adult({species:2,attributes:{...adult().attributes,gender:1}})));
    await wait(f.breeder.connect(f.user).prepareBreed(3,4,E('1000')));
    assert.equal(await f.breeder.quoteVrf(5_000_000_000n),0n);
    await fail(f.breeder.connect(f.user).commitBreed(3),'InsufficientNativePayment');
    await wait(f.admin.sendTransaction({to:f.breeder.target,value:E('.01')}));
    await wait(f.breeder.connect(f.user).commitBreed(3));
    assert.equal(await f.wrapper.received(),E('.03'));
  });

  it('enforces dedicated NFT mint permissions rather than giving Bertha admin access',async()=>{
    await fail(f.nft.connect(f.other).mintNew(f.other.address),'AccessManagedUnauthorized');
    await wait(f.manager.revokeRole(42,f.breeder.target));
    const id=await readyBreed(f);
    await fail(f.breeder.completeBreed(id),'AccessManagedUnauthorized');
    await wait(f.manager.grantRole(42,f.breeder.target,0));
    await wait(f.breeder.completeBreed(id));
  });

  it('preserves legacy species boundary behaviour and Harry trait inheritance for fixed seeds',async()=>{
    const rules=await deploy('BreedingRulesHarness');
    const a=adult(),b=adult({species:2,attributes:{...adult().attributes,gender:1,nature:12,size:14}});
    assert.equal(await rules.child(a,b,pool,124),1n);
    assert.equal(await rules.child(a,b,pool,125),2n);
    assert.equal(await rules.child(a,b,pool,300),1n); // legacy zero-threshold boundary
    assert.equal(await rules.child(a,b,pool,301),2n);
    assert.equal(await rules.child(a,b,pool,450),3n); // legacy retained disabled/final entry
    const [attrs,stats]=await rules.hatch(a,b,pool[0],false,0);
    assert.deepEqual(Array.from(attrs),[1n,2n,1n,0n,7n,11n]);
    assert.deepEqual(Array.from(stats),[50n,8n,6n,4n,2n,10n]);
    const big=87654321098765432109876543210987654321n;
    const [treated]=await rules.hatch(a,b,pool[0],true,big);
    const [untreated]=await rules.hatch(a,b,pool[0],false,big);
    assert.equal(treated.gender,untreated.gender);
    assert.equal(treated.nature,untreated.nature);
  });

  it('keeps inherited traits within their game bounds over 128 deterministic random seeds',async()=>{
    const rules=await deploy('BreedingRulesHarness');
    for(let i=0;i<128;i++){
      const word=BigInt(ethers.keccak256(ethers.toUtf8Bytes('genetics-seed-'+i)));
      const [attrs,stats]=await rules.hatch(adult(),adult({generation:i%2}),pool[0],i%2===0,word);
      assert.ok(attrs.gender===0n || attrs.gender===1n);
      assert.ok(attrs.rarity>=0n && attrs.rarity<=2n);
      assert.ok(attrs.nature>=0n && attrs.nature<=20n);
      assert.ok(attrs.size>=0n && attrs.size<=20n);
      assert.equal(stats.health,50n);
      for(const stat of Array.from(stats).slice(1)) assert.ok(stat>=0n && stat<=50n);
    }
  });

  it('existing Evo mint functions allocate IDs and preserve historical mintTo limits',async()=>{
    const authority=await deploy('MockAuthority');
    await network.provider.send('hardhat_setCode',['0x204fc7955F816352afDe77D84e4e8719D2C28A0A',await ethers.provider.getCode(authority.target)]);
    const implementation=await deploy('Evo');
    const proxy=await deploy('ERC1967Proxy',implementation.target,implementation.interface.encodeFunctionData('initialize'));
    const evo=await ethers.getContractAt('Evo',proxy.target);
    await wait(evo.mintNew(f.user.address));
    assert.equal(await evo.ownerOf(5109),f.user.address);
    await wait(evo.mintNew(f.user.address));
    assert.equal(await evo.ownerOf(5110),f.user.address);
    await wait(evo.mintTo(f.user.address,5));
    await fail(evo.mintTo(f.user.address,5111),'InvalidTokenId');
  });
});
