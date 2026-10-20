# Nursery mainnet signing handoff

This is the reviewed deployment candidate for private beta testing. Execution is not approved. The public nursery stays disabled. No Evo collection upgrade is required.

## Signers and frozen transactions

| Signer | Wallet | Transactions |
| --- | --- | --- |
| Deployment wallet | 0x575CEb9E9ca3d05be1ca18997173C4e3D10f26f1 | 1-2: deploy Hermann and Bertha |
| Existing administrator | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 3-19, in the five gated phases below |

Read `colleague-signing-review.json` and `transactions.md` alongside `unsigned-release.json`. The latter contains the exact chain, sender, target, calldata, constructor settings and proposed gas limits. The frozen deployment nonce is 312. Any change to that nonce, predicted addresses, permissions, constructor settings or pilot snapshot requires regeneration and rehearsal before signing.

1. Confirm database-owner execution access and the backup checkpoint. After explicit approval, hold the indexer before transaction 1 and record its last committed checkpoint.
2. Deploy both NPCs (1-2), independently verify receipts and runtime, then pause and configure them (3-7).
3. Preserve existing administrator mint access, grant Bertha its narrow mint permission and temporarily grant import access (8-12).
4. Apply the separately approved owner database transaction, resume the nursery-aware backend from its unchanged checkpoint, and verify catch-up and read-only private beta. Recheck legacy writers, pending requests, traits, ownership and cooldowns before importing the approved four pilot adults and removing import permission (13-17).
5. After explicit real-asset spending/activation approval and successful metadata checks, unpause the NPCs (18-19) and enable private beta signing. Public release follows a separate acceptance decision.

## Evidence and remaining acceptance

The exact contract artifacts passed 182 automated checks, the mainnet-fork sequence and live corrected OG hatches on Fuji. OG sizes 11 and 19 came from genuine callbacks, with all other historical trait draws preserved. All 49 wallet sizes round-trip through imports and percentage metadata without changes to existing Evos. Both candidate backend images and the private website candidate build passed local runtime checks; they are not published.

The approved read-only AWS checks found PostgreSQL 15.17, the three expected original migration entries, processor checkpoint 98022707 and zero legacy request rows. Both diagnostic tasks exited successfully and their temporary task definitions were deregistered. The deployed backend has no nursery registry/configuration yet.

`database-owner-migration.sql` is required because the existing indexer login cannot access metadata. Its local role-aware rehearsal passed migration execution, API reads, indexer writes, API write denial and repeat-execution rejection. Production owner execution privileges remain to be checked through the existing owner connection; no permission expansion or production migration has been performed. The full database size query was denied to the indexer role; the verified 49-wallet snapshot is a narrower scope.

Before execution, accept the pilot IDs 532, 3429, 4092 and 4503, refreshed costs and spending cap; confirm the actual OG holder/IDs if live OG testing is included; reconcile/stop legacy writers; and complete the colleague's artifact and permission review. Two previously bred Fuji eggs still need their final hatches after 23 October 2026, 10:09 am Australia/Brisbane. They are not recorded as completed hatch tests.

Use `backend-runtime-plan.json` for the precise backend order and recovery rules. Keep the new NPCs paused if any check fails. Preserve pending requests and their randomness; a website rollback does not undo minting, treatment or payments. Do not resume an old indexer past nursery events or reset the existing cursor.
