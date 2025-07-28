//import "@tenderly/hardhat-tenderly";
import '@nomicfoundation/hardhat-verify';

import "@dirtycajunrice/hardhat-tasks/internal/type-extensions"
import "@dirtycajunrice/hardhat-tasks";
import "dotenv/config";
import "./tasks";
import '@openzeppelin/hardhat-upgrades';
import { vars } from "hardhat/config";

import { NetworksUserConfig } from "hardhat/types";


const networkData = [
  {
    name: "avalanche",
    chainId: 43_114,
    urls: {
      rpc: `https://api.avax.network/ext/bc/C/rpc`,
      api: "https://api.snowscan.xyz/api",
      browser: "https://snowscan.xyz",
    },
  }
];

module.exports = {
  defaultNetwork: "avalanche",
  solidity: {
    compilers: [ "8.20", "8.28" ].map(v => (
      {
        version: `0.${v}`,
        settings: {
          ...(
            v === "8.20" ? { evmVersion: "london" } : {}
          ), optimizer: { enabled: true, runs: 200 }
        },
      }
    )),
  },
  networks: networkData.reduce((o, network) => {
    o[network.name] = {
      url: network.urls.rpc,
      chainId: network.chainId,
      accounts: [ vars.get("PRIVATE_KEY") ]
    }
    return o;
  }, {} as NetworksUserConfig),
  etherscan: {
    apiKey: vars.get("ETHERSCAN_API_KEY"),
  },
  tenderly: {
    project: 'evoverses',
    username:  vars.get("TENDERLY_USERNAME"),
  },
  sourcify: {
    enabled: true
  }
};
