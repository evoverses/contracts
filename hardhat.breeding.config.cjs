require('@nomicfoundation/hardhat-ethers');
const { subtask } = require('hardhat/config');
const { TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD } = require('hardhat/builtin-tasks/task-names');
// Local pinned compiler; no network download or production credentials for tests.
subtask(TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD).setAction(async ({ solcVersion }, hre, runSuper) => {
  if (solcVersion !== '0.8.28') return runSuper();
  return {
    compilerPath: require.resolve('solc-0.8.28/soljson.js'),
    isSolcJs: true,
    version: '0.8.28',
    longVersion: require('solc-0.8.28').version(),
  };
});
module.exports = {
  defaultNetwork: 'hardhat',
  solidity: { version: '0.8.28', settings: { evmVersion: 'london', optimizer: { enabled: true, runs: 200 } } },
  paths: { tests: './test', cache: './cache-breeding', artifacts: './artifacts-breeding' },
  networks: { hardhat: { chainId: 31337 } },
  mocha: { timeout: 60000 },
};
