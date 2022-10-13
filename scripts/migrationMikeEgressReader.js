const { ethers } = require("hardhat")
require("dotenv").config()

async function update() {
  const accounts = await ethers.getSigners()

  const contract = await ethers.getContractAt("MigrationMikeEgressUpgradeable", "0xba9564732102222bdbf54b931D783AFCe52053C5", accounts[0])

  const fromAddress = "0xB40005c1b841975dDa6FF115a3cf6547a8eD49F2";

  const topics = [
    contract.filters.BridgedTokens().topics,
    contract.filters.BridgedNFT().topics,
    contract.filters.BridgedNFTs().topics,
    contract.filters.BridgedToken().topics,
    contract.filters.BridgedDisbursement().topics,
    contract.filters.BridgedTokenWithLocked().topics
  ];
  const events = [];
  const block = 28593936;
  for (const topic of topics) {
    const e = await contract.queryFilter({
      address: contract.address,
      topics: topic
    }, block, block)
    if (e.length > 0) {
      for (let i = 0; i < e.length; i++) {
        events.push(e[i])
        if (e[i].args[0] === fromAddress) {

        }
      }
    }
  }
  const mapped = events.map(e => {
    const r = {
      blockNumber: e.blockNumber,
      event: e.event,
      args: [
        e.args[0],
        e.args[1],
        e.args[2]
      ]
    }
    if (r.event === 'BridgedNFTs') {
      r.args[2] = e.args[2].map(n => n.toString())
    }
    if (['BridgedTokenWithLocked', 'BridgedToken', 'BridgedNFT'].includes(r.event)) {
      r.args[2] = e.args[2].toString()
    }
    if (r.event === 'BridgedTokenWithLocked') {
      r.args.push(e.args[3].toString())
    }
    return r;
  })
  console.log(mapped[0]);


}
update()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
