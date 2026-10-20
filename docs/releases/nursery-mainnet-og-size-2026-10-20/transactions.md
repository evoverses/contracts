# Unsigned mainnet nursery setup - corrected OG size

Review candidate only. Execution is not approved. No collection upgrade. Existing snapshot/pilot data is retained and not approved for import.

Source snapshot: block 98003799. Fresh nonce, permissions, fees and dependency preflight are recorded separately.
Expected mainnet deployer nonce: 312.

| Step | Action | Sender | Gas limit |
| --- | --- | --- | --- |
| 1 | Deploy Hatcher_Hermann | 0x575CEb9E9ca3d05be1ca18997173C4e3D10f26f1 | 5211467 |
| 2 | Deploy Breeder_Bertha | 0x575CEb9E9ca3d05be1ca18997173C4e3D10f26f1 | 2728509 |
| 3 | Pause Hermann until readiness verified | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 55690 |
| 4 | Pause Bertha until readiness verified | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 55607 |
| 5 | Pin reciprocal breeder | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 86494 |
| 6 | Freeze original Genesis root and pool | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 12479390 |
| 7 | Freeze separate bred species version | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 12399863 |
| 8 | Preserve existing mintNew permission for 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 76863 |
| 9 | Restrict existing mintNew selector to dedicated minter role | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 75692 |
| 10 | Grant Bertha zero-delay mint permission | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 76863 |
| 11 | Assign dedicated verified-import selectors | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 106660 |
| 12 | Grant temporary import permission | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 76863 |
| 13 | Import verified adult #532 | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 471363 |
| 14 | Import verified adult #3429 | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 521170 |
| 15 | Import verified adult #4092 | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 421565 |
| 16 | Import verified adult #4503 | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 421565 |
| 17 | Remove temporary import permission | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 51928 |
| 18 | Activate Hermann after readiness acceptance | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 55558 |
| 19 | Activate Bertha after readiness acceptance | 0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE | 55585 |

Exact constructor settings, targets, calldata and values are in unsigned-release.json. Mainnet signing remains disabled.
