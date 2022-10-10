import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import '@openzeppelin/hardhat-upgrades';
import "@nomiclabs/hardhat-etherscan";

import "dotenv/config";

import "./tasks/deploy";
import "./tasks/deployUpgradeable";
import "./tasks/upgrade";
import "./tasks/getUpgradeDetails";

module.exports = {
  defaultNetwork: 'boba',
  solidity: {
    compilers: [
      {
        version: "0.8.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.6.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
  },
  networks: {
    harmony: {
      url: process.env.RPC_URL,
      chainId: 1666600000,
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 200000000000
    },
    harmonyTest: {
      url: 'https://api.s0.b.hmny.io',
      chainId: 1666700000,
      accounts: [process.env.PRIVATE_KEY]
    },
    optimisticEthereum: {
      url: 'https://mainnet.optimism.io',
      chainId: 10,
      accounts: [process.env.PRIVATE_KEY]
    },
    polygon: {
      url: 'https://polygon-mainnet.public.blastapi.io',
      chainId: 137,
      accounts: [process.env.PRIVATE_KEY]
    },
    arbitrumOne: {
      url: 'https://arb1.arbitrum.io/rpc',
      chainId: 42161,
      accounts: [process.env.PRIVATE_KEY]
    },
    opera: {
      url: 'https://fantom-mainnet.public.blastapi.io',
      chainId: 250,
      accounts: [process.env.PRIVATE_KEY]
    },
    avalanche: {
      url: 'https://ava-mainnet.public.blastapi.io/ext/bc/C/rpc',
      chainId: 43114,
      accounts: [
        process.env.PRIVATE_KEY,
        process.env.PRIVATE_KEY_2,
        process.env.PRIVATE_KEY_3,
        process.env.PROXY_WALLET
      ]
    },
    cronos: {
      url: 'https://evm.cronos.org',
      chainId: 25,
      accounts: [process.env.PRIVATE_KEY]
    },
    boba: {
      url: 'https://avax.boba.network',
      chainId: 43288,
      accounts: [
        process.env.PRIVATE_KEY,
        process.env.PRIVATE_KEY_2,
        process.env.PRIVATE_KEY_3,
        process.env.PROXY_WALLET
      ]
    }
  },
  etherscan: {
    apiKey: {
      harmony: 'not needed',
      harmonyTest: 'not needed',
      optimisticEthereum: process.env.OPTIMISTIC_API_KEY,
      polygon: process.env.POLYGONSCAN_API_KEY,
      arbitrumOne: process.env.ARBISCAN_API_KEY,
      opera: process.env.FTMSCAN_API_KEY,
      avalanche: process.env.SNOWTRACE_API_KEY,
      cronos: process.env.CRONOSCAN_API_KEY,
      boba: 'not needed'
    },
    customChains: [
      {
        network: "cronos",
        chainId: 25,
        urls: {
          apiURL: "https://api.cronoscan.com/api",
          browserURL: "https://cronoscan.com/",
        },
      },
      {
        network: "boba",
        chainId: 43288,
        urls: {
          apiURL: "https://blockexplorer.avax.boba.network/api",
          browserURL: "https://blockexplorer.avax.boba.network",
        },
      }
    ]
  }
};
