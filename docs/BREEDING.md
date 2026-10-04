# Bertha and Hermann — local implementation

This branch adds new, non-proxy `Breeder_Bertha` and `Hatcher_Hermann` contracts.
They are **not** storage-compatible upgrades of Brenda or Harry. Existing Brenda,
EVO, xEVO, authority and collection addresses are not replaced. No live deployment
or permission changes have been made. The website/backend work is separate.

## Agreed rules

- Breeding costs 500 EVO per parent, times `2 ** generation`, times previous breeds + 1.
- Gen0 cost uses at most four previous breeds: 2,500 EVO per parent from that point.
- Gen0 can breed indefinitely; other generations have five breeds.
- Recovery is `max(1, 7-generation)` days. The counter advances exactly once on successful egg minting.
- An egg is minted in the V2 Evo collection; the same token ID becomes an adult after hatching.
- Incubation lasts three days from successful egg minting, not from VRF submission.
- Optional treatment costs 250 EVO once, affects rarity and does not shorten incubation.
- Every successful breeding and treatment EVO payment goes to
  `0x9F64C4bECa7BBda647B9A755B29F7F9687bc4303`. There is no revenue split.
- Breed VRF and hatch VRF are separate native-AVAX surcharges, collected at their respective request times.
- The fixed wrapper is Chainlink VRF v2.5 direct funding. No project-owned VRF subscription is required.
- An administrator may later enable separately funded AVAX subsidies on either NPC. No EVO swaps occur.

## Why Hermann also stores game state

The live V2 collection does not expose parent genes, breed counters or incubation
state on chain. Hermann therefore stores imported adult traits, authoritative
breeding history and new eggs. Existing metadata requires a controlled one-time
`importAdult` from a verified snapshot. Unknown-gender eggs must not be imported
as adults. This is an explicit trusted migration; a holder cannot submit their
own traits. Imports cannot overwrite existing records. Species configuration is
versioned; requests and eggs retain the original version even after later changes.

The website must index `AdultImported`, `EggRecorded`, `EggTreated`,
`HatchRequested`, `EggHatched` and Bertha's request events, and derive metadata
from the confirmed contract state. The existing website worker must not also
increment these authoritative counters or use `MAX(token_id)+1`.

Before launch, reconcile all other breeding entry points with this registry.
Independent breeding paths that still mutate off-chain counts can otherwise
make imported history stale. The old Brenda has not been silently repaired or
retargeted by this branch.

## Payment, cancellation and VRF flow

The normal UI can call `breed(parent1,parent2,maxEvoCost)` once. This atomically
checks eligibility, reserves the parents, escrows the exact EVO price and pays
the wrapper's live AVAX quote. Insufficient allowance, native payment, wrapper
availability or incompatible parents revert the entire transaction.

Alternatively, `prepareBreed` escrows EVO without requesting randomness. The
requester can cancel this prepared state for a full EVO refund, including while
paused. If a parent was transferred or burned before commitment, anyone can
cancel; the refund always goes to the original requester. `commitBreed` checks
ownership again and starts VRF. Parent traits, species configuration and the
recipient cannot be changed after commitment.

**After VRF commitment, cancellation, denial, expiry refunds and new random
requests are deliberately unavailable.** Otherwise users could abandon an
unfavourable result and reroll. Consequently a permanently unfulfilled VRF
request can leave EVO escrow and parent reservations locked. This tradeoff needs
explicit production acceptance and independent review; there is no claim of
zero risk and no invented 24-hour refund policy. Do not launch with an untested
wrapper, insufficient confirmations or a callback that exceeds its gas budget.

The authenticated wrapper callback only stores one random word and a fulfilled
flag. It has no external calls or pause gate. Duplicate/unknown/malformed
callbacks do not overwrite results. `completeBreed` is permissionless and may be
retried with the same stored word after a mint or treasury transfer failure. It
always mints to the original requester. State changes, minting, game history and
treasury payment succeed atomically or all roll back.

Completion calls are separate ordinary transactions. They can be sent by the
user, UI or an automation keeper; that caller pays their network gas. The AVAX
VRF surcharge covers Chainlink's quoted request, not a keeper's later gas. The
website must display this distinction and offer completion/recovery controls.

The new `Evo.mintNewWithId(address)` returns the contract's allocated ID. This is
an additive mint function with no new storage. Historical `mintTo` bounds and
existing `mintNew` behaviour remain unchanged. It needs a separately reviewed
Evo implementation upgrade and a dedicated minter permission; **these local
changes alone cannot breed using the currently deployed implementation**.

For hatching, the current egg owner calls `requestHatch` after incubation, paying
that request's AVAX surcharge. This locks treatment before rarity randomness is
requested. Anyone can then call `completeHatch` once randomness is ready. The NFT
ID and current owner remain unchanged. No hatch reroll or post-request treatment
is allowed. Burned or transferred parents cannot alter their stored inherited
traits; NFTs can still transfer while requests are pending.

AVAX sent above the wrapper quote becomes withdrawable credit belonging to the
payer. It is not a cancellation or an oracle-fee refund. The wrapper's actual
charge is not refundable here. Credits cannot be swept to the treasury. Subsidy
funds are distinct from user credits and EVO escrow.

## Genetics and legacy quirks

`EvoBreedingRules` ports Betty/Harry's type compatibility, generation, species,
rarity, gender, nature, size, health and other stat formulas. Health starts at 50;
new offspring have no prior breeds; initial experience and moves are zero in
metadata. Two Gen0 parents receive the original stat modifier.

The original source's `<= 500` matching-species boundary is retained (501 of
1,000 outcomes). Harry's species threshold comparison and retained disabled
entries are also reproduced exactly, including the ability to select a disabled
final entry. Those quirks mean the original weights do not behave like a
conventional weighted draw. Tests document the behaviour. Correcting it would
change probabilities and requires a separate agreed rule change; do not
advertise configured weights as exact probabilities without that decision.

## Local validation and deployment proposals

After installing the pinned dependencies with `npm ci`:

```text
npm run compile:breeding
npm run test:breeding
npm run deploy:breeding:local
npm run plan:breeding -- --chain-id 43114
```

The isolated config uses a local Solidity 0.8.28 compiler, London, optimizer200,
chain31337, separate ignored artifacts and no production secrets or plugins.
The local demo deploys mocks and fixture species/parents; they are not production
data. `plan:breeding` only prints constructor arguments, role wiring and
verification prerequisites; it has no provider or signer. Its default is Fuji
with explicit placeholders. There is no automatic mainnet deployment script.

The new NPCs are non-upgradeable. Policy subsidy toggles and new species versions
are explicit administrator actions. Do not grant Bertha the global admin role.
Grant only the new Evo mint selector. Assign the data importer its own role, and
retain pause/configuration controls for administration. Existing legitimate
mint selectors and roles remain unchanged.

Before any live proposal: reproduce and validate the deployed Evo build/storage,
review metadata/species snapshots, exercise Fuji, review gas and pricing against
the real wrapper, test website indexing and user flows, and obtain independent
security review. Repository dependency audit findings are separate from a
contract security audit; legacy tooling dependencies need review before release.

## Validation performed on this branch

- Solidity compilation passed; Bertha/Hermann are below the EIP-170 runtime size limit.
- 19 local integration tests passed, including 128 deterministic genetics seeds,
  receiver reentrancy, rejected mints, duplicate callbacks/settlement, payment
  failures, refunds before commitment, treatment locking and version snapshots.
- Both VRF callbacks were exercised with the configured 100,000-gas allowance.
- The guarded local fixture deployment and transaction-free mainnet plan generator passed.
- Comparing cached explorer-verified Evo source with the modified implementation
  using Solidity 0.8.28 found the raw counter layout, six ERC-7201 namespaces and
  existing function ABI unchanged. This structural comparison is not full
  OpenZeppelin upgrade validation or an independent audit of the deployed build.
- Package audit reported 88 existing-toolchain/dependency findings, including
  five critical entries. No broad automatic dependency upgrades were applied.
  Production signing/deployment tooling needs remediation and verification.

No testnet/mainnet transactions, branch pushes, database writes or website edits
were performed. All chain transactions in validation used local chain 31337.
