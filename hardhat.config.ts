import * as tenderly from "@tenderly/hardhat-tenderly";
import '@nomicfoundation/hardhat-verify';

import "@dirtycajunrice/hardhat-tasks/internal/type-extensions"
import "@dirtycajunrice/hardhat-tasks";
import "dotenv/config";
import "./tasks";
import '@openzeppelin/hardhat-upgrades';

import { NetworksUserConfig } from "hardhat/types";

tenderly.setup({ automaticVerifications: false });

const networkData = [
  {
    name: "avalanche",
    chainId: 43_114,
    urls: {
      rpc: `https://api.avax.network/ext/bc/C/rpc`,
      api: "https://api.snowtrace.io/api",
      browser: "https://snowtrace.io",
    },
  }
];

module.exports = {
  defaultNetwork: "avalanche",
  solidity: {
    compilers: [ "8.20" ].map(v => (
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
      accounts: [ process.env.PRIVATE_KEY! ]
    }
    return o;
  }, {} as NetworksUserConfig),
  etherscan: {
    apiKey: {
      avalanche: process.env.SNOWTRACE_API_KEY,
    },
    customChains: networkData.map(network => (
      {
        network: network.name,
        chainId: network.chainId,
        urls: { apiURL: network.urls.api, browserURL: network.urls.browser },
      }
    ))
  },
  tenderly: {
    project: 'evoverses',
    username: 'DirtyCajunRice',
  }
};
