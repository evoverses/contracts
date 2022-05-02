// migrations/3_deploy_upgradeable_box.js
const EvoToken = artifacts.require('EvoToken');
const MasterInvestor = artifacts.require('MasterInvestor');



// MasterInvestor
const REWARD_PER_BLOCK = "1000000000000000000"; //
const START_BLOCK = "25918276";
const HALVING_AFTER_BLOCK = "302400"; // 1 epoch

const REWARD_MULTIPLIER = [
    256,
    128,
    96,
    64,
    56,
    48,
    40,
    32,
    28,
    24,
    20,
    16,
    15,
    14,
    13,
    12,
    11,
    10,
    9,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4
];

const _blockDeltaEndStage = [
    1770,
    43200,
    129600,
    216000,
    604800,
    1209600
];

const _blockDeltaStartStage = [
    0,
    1,
    1771,
    43201,
    129601,
    216001,
    604801,
    1209601
];

const _devFeeStage = [
    25,
    8,
    4,
    2,
    1,
    5,
    25,
    1
];

const _userFeeStage = [
    75,
    92,
    96,
    98,
    99,
    995,
    9975,
    9999
];

const _userDepFee = 1;
const _devDepFee = 1;
//


module.exports = async function (deployer) {
    const tokenAddress = (await EvoToken.deployed()).address;
    await deployer.deploy(
        MasterInvestor,
        tokenAddress,
        REWARD_PER_BLOCK,
        START_BLOCK,
        HALVING_AFTER_BLOCK,
        _userDepFee,
        _devDepFee,
        REWARD_MULTIPLIER,
        _blockDeltaStartStage,
        _blockDeltaEndStage,
        _userFeeStage,
        _devFeeStage
    );
};
