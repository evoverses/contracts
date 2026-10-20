# Mainnet nursery release candidate: corrected OG size

**Unsigned review package. Do not deploy or import from this package without separate approval.** No mainnet transaction, production database write or website deployment was made during this revision.

## Change

Original OG hatching fixed size at 10. Genesis hatching now uses the remaining committed VRF entropy after the nine historical base-10000 trait chunks, modulo 21. This produces raw size 0-20 without changing the original species, gender, rarity, types, nature or battle-stat draws. Bred size inheritance remains unchanged. Existing hatched Evos are not rerolled.

Bertha uses the existing collection's `mintNew(address)` interface and captures the allocated ID through a guarded ERC721 receiver before registering/delivering the egg. The existing collection needs no implementation upgrade. The package preserves current authorized mint access before granting Bertha its dedicated mint role.

## Validation

- 179 tests: 28 contracts, 52 website nursery/owner security, 36 wallet, 22 marketplace, 37 indexer and four release-tool checks.
- Website, indexer and API type checks passed. No website source/configuration changed in this revision, so the prior successful production build was retained.
- Exact 19-step deployment/configuration/import sequence passed on a mainnet fork. Existing collection implementation, owners, legacy mint/transfer behaviour and production three-day incubation boundaries were verified.
- The three OG paths (untreated, purchased treatment and originally treated) produced the expected boundary/midpoint sizes 0, 10 and 20 on the fork.
- Nine resulting metadata records, disposable database migrations and three wallet lists passed the actual registry reader/projection/API rehearsal. No production database was written.
- All 19 local setup receipts were independently checked twice against exact targets, senders, values and calldata.
- Pinned Solidity 0.8.28 compiler inputs reproduce both NPC bytecodes. The packaged Hermann artifact is identical to the corrected artifact tested live on Fuji.
- Two fresh synthetic OGs hatched using genuine Fuji Chainlink callbacks, with sizes 11 and 19. Replaying their actual random words against the explorer-verified legacy bytecode confirmed that every other trait matches. Existing Fuji NFTs and pending eggs were unchanged.

## Review files

- `transactions.md`: the human-readable sequence and rehearsed gas limits.
- `unsigned-release.json`: exact unsigned calldata, constructors, predicted addresses, roles and mainnet signing-disabled website settings.
- `npc-artifacts.json`, `npc-input-*.json`, `npc-source-reproduction.json`: frozen artifacts and compiler inputs.
- `cost-estimate.json`: refreshed fee estimate; no approved spending cap.
- `live-chain-preflight.json`: fresh implementation, owner, unused-address and nonce checks against mainnet, read-only.
- `manifest.json`: check scopes, counts and file hashes.
- `gaps.json`: remaining gates. `live-fuji-og-size/`: actual corrected Fuji transaction, callback and trait evidence.

## Remaining gates

The earlier pinned inventory, Genesis eligibility snapshot and unapproved pilot selection are retained for reproducibility. They are not newly approved imports. Refresh/reconcile final traits, breeding counts, cooldowns and legacy writers before signing.

The user confirmed `percentage = (raw - 10) * 10`. Applying and verifying that conversion at import/output boundaries remains pending; the old pilot's raw numeric bounds alone do not validate its units. This package does not silently change any existing Evo's size.

Administrator signing coordination, production database/indexer readiness, pilot NFT IDs and spending cap, actual OG-holding wallet/IDs and independent security review remain open. The two prior bred Fuji eggs also still require their real incubation period before their final hatches on 23 October 2026 after 10:09 am Australia/Brisbane.

Requote and regenerate if the mainnet deployer's nonce, permission assignments, addresses, final imports or source changes. Website rollback cannot reverse paid randomness or minting. Maintain pending requests and use reviewed pause/unpause recovery. Keep public activation separate from private mainnet acceptance.
