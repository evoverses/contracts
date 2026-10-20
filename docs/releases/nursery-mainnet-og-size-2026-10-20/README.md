# Mainnet nursery release candidate: corrected OG size

**Unsigned review package. Do not deploy or import from this package without separate approval.** No mainnet transaction, production database write or website deployment was made during this revision.

## Change

Original OG hatching fixed size at 10. Genesis hatching now uses the remaining committed VRF entropy after the nine historical base-10000 trait chunks, modulo 21. This produces raw size 0-20 without changing the original species, gender, rarity, types, nature or battle-stat draws. Bred size inheritance remains unchanged. Existing hatched Evos are not rerolled.

Bertha uses the existing collection's `mintNew(address)` interface and captures the allocated ID through a guarded ERC721 receiver before registering/delivering the egg. The existing collection needs no implementation upgrade. The package preserves current authorized mint access before granting Bertha its dedicated mint role.

## Validation

- 182 tests: 28 contracts, 53 website nursery/owner security, 36 wallet, 22 marketplace, 38 indexer and five release-tool checks.
- Fresh website/API production builds, indexer build, OpenNext packaging/dry run, owner-login runtime and all type checks passed. Both backend container images built locally and passed isolated runtime smoke checks; neither image has been published.
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

## Database and cutover preparation

`backend-readiness-summary.json` records the live findings. `database-owner-migration.sql` applies both frozen migrations, reinstalls the list-query helpers, records the migration ledger and grants only required registry access. It aborts if the ledger or legacy requests changed. This file is a review candidate, not permission to run it on production. `database-owner-rehearsal.json` records the local permission-aware proof.

Before the first contract deployment, hold the existing indexer at its committed checkpoint. Resume only with the nursery-aware image and verified deployment block. Setting NURSERY_FROM_BLOCK alone does not rewind a processor that already passed those events. The precise order and recovery rules are in `backend-runtime-plan.json`.

## Remaining gates

Mainnet ownership and Genesis eligibility were refreshed at blocks 98021010/98021026, and administrator permissions at block 98021113. The original pilot IDs and EVO costs are retained. They are not newly approved imports. Final cutover must still reconcile pending legacy requests/writers before signing imports.

The agreed `percentage = (raw - 10) * 10` conversion is implemented at import and output boundaries. All 49 existing sizes round-trip exactly. The fresh fork/database/API rehearsal verifies that imported sizes and XP stay unchanged and that new sizes are exposed as percentages once. Invalid values fail closed.

`colleague-signing-review.json` separates the 19 exact transactions into five phases and identifies each signer. `backend-runtime-plan.json` stages the existing backend migration/configuration order. The deployed indexer still lacks nursery configuration. Approved temporary read-only AWS tasks verified the three original migration entries, processor checkpoint at block 98022707 and zero rows in the legacy breeding-request table. Both tasks exited successfully and their temporary task definitions were deregistered. No production SQL write or service update occurred. The indexer login lacks metadata-schema access, so the reviewed `database-owner-migration.sql` must run through the existing database owner before the updated indexer starts. Its exact live function interfaces, restricted indexer role, migration transaction, API reads, denied API writes and duplicate-execution rejection passed a disposable database rehearsal. Database-owner execution privileges and the stopped legacy writer still need confirmation at cutover. Full-database size coverage could not be queried through this restricted login; all 49 wallet sizes were independently validated through public metadata. Pilot NFT IDs and spending cap, actual OG-holding wallet/IDs and the colleague's security review still require acceptance. The two prior bred Fuji eggs also still require their real incubation period before their final hatches on 23 October 2026 after 10:09 am Australia/Brisbane.

Requote and regenerate if the mainnet deployer's nonce, permission assignments, addresses, final imports or source changes. Website rollback cannot reverse paid randomness or minting. Maintain pending requests and use reviewed pause/unpause recovery. Keep public activation separate from private mainnet acceptance.
