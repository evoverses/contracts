// migrations/2_deploy.js
const EvoToken = artifacts.require('EvoToken');

module.exports = async function (deployer) {
    await deployer.deploy(EvoToken, "EVO", "EVO", "600000000000000000000000000", "600000000000000000000000000", "25836650", "25918276");
};