// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../EvoToken.sol";


// MasterInvestor is the master investor of whatever investments are available.
contract MasterInvestorOld is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AUTHORIZED_ROLE = keccak256("AUTHORIZED_ROLE");

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardDebtAtBlock; // the last block user stake
        uint256 lastWithdrawBlock; // the last block a user withdrew at.
        uint256 firstDepositBlock; // the last block a user deposited at.
        uint256 blockdelta; //time passed since withdrawals
        uint256 lastDepositBlock;
        //
        // We do some fancy math here. Basically, at any point in time, the
        // amount of EVO
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accGovTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accGovTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct UserGlobalInfo {
        uint256 globalAmount;
        mapping(address => uint256) referrals;
        uint256 totalReferrals;
        uint256 globalRefAmount;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. EVO to distribute per block.
        uint256 lastRewardBlock; // Last block number that EVO distribution occurs.
        uint256 accGovTokenPerShare; // Accumulated EVO per share, times 1e12. See below.
    }

    // The EVO token
    EvoToken public govToken;
    //An ETH/USDC Oracle (Chainlink)
    address public usdOracle;
    // Dev address.
    address public devAddr = 0x946d5Cb6C3A329BD859e5C3Ba01767457Ea2DcA2;
    // LP address
    address public liquidityAddr = 0xA511794340216a49Ac8Ae4b5495631CcD80BCfcc;
    // Community Fund Address
    address public comFundAddr = 0xA511794340216a49Ac8Ae4b5495631CcD80BCfcc;
    // Founder Reward
    address public founderAddr = 0x946d5Cb6C3A329BD859e5C3Ba01767457Ea2DcA2;
    // EVO created per block.
    uint256 public REWARD_PER_BLOCK;
    // Bonus multiplier for early EVO makers.
    uint256[] public REWARD_MULTIPLIER; // init in constructor function
    uint256[] public HALVING_AT_BLOCK; // init in constructor function
    uint256[] public blockDeltaStartStage;
    uint256[] public blockDeltaEndStage;
    uint256[] public userFeeStage;
    uint256[] public devFeeStage;
    uint256 public FINISH_BONUS_AT_BLOCK;
    uint256 public userDepFee;
    uint256 public devDepFee;

    // The block number when EVO mining starts.
    uint256 public START_BLOCK;

    uint256[] public PERCENT_LOCK_BONUS_REWARD; // lock xx% of bonus reward
    uint256 public PERCENT_FOR_DEV; // dev bounties
    uint256 public PERCENT_FOR_LP; // LP fund
    uint256 public PERCENT_FOR_COM; // community fund
    uint256 public PERCENT_FOR_FOUNDERS; // founders fund

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => uint256) public poolId1; // poolId1 starting from 1, subtract 1 before using with poolInfo
    // Info of each user that stakes LP tokens. pid => user address => info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => UserGlobalInfo) public userGlobalInfo;
    mapping(IERC20 => bool) public poolExistence;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SendGovernanceTokenReward(address indexed user, uint256 indexed pid, uint256 amount, uint256 lockAmount);

    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "MasterInvestor::nonDuplicated: duplicated");
        _;
    }

    constructor(
        EvoToken _govToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _halvingAfterBlock,
        uint256 _userDepFee,
        uint256 _devDepFee,
        uint256[] memory _rewardMultiplier,
        uint256[] memory _blockDeltaStartStage,
        uint256[] memory _blockDeltaEndStage,
        uint256[] memory _userFeeStage,
        uint256[] memory _devFeeStage
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(AUTHORIZED_ROLE, _msgSender());

        govToken = _govToken;
        REWARD_PER_BLOCK = _rewardPerBlock;
        START_BLOCK = _startBlock;
        userDepFee = _userDepFee;
        devDepFee = _devDepFee;
        REWARD_MULTIPLIER = _rewardMultiplier;
        blockDeltaStartStage = _blockDeltaStartStage;
        blockDeltaEndStage = _blockDeltaEndStage;
        userFeeStage = _userFeeStage;
        devFeeStage = _devFeeStage;
        for (uint256 i = 0; i < REWARD_MULTIPLIER.length - 1; i++) {
            uint256 halvingAtBlock = (_halvingAfterBlock * (i+1)) + _startBlock + 1;
            HALVING_AT_BLOCK.push(halvingAtBlock);
        }
        FINISH_BONUS_AT_BLOCK = (_halvingAfterBlock * (REWARD_MULTIPLIER.length - 1)) + _startBlock;
        HALVING_AT_BLOCK.push(2**256 - 1);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyRole(ADMIN_ROLE) nonDuplicated(_lpToken) {
        require(poolId1[address(_lpToken)] == 0, "MasterInvestor::add: lp is already in pool");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = (block.number > START_BLOCK) ? block.number : START_BLOCK;
        totalAllocPoint += _allocPoint;
        poolId1[address(_lpToken)] = (poolInfo.length + 1);
        poolExistence[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accGovTokenPerShare: 0
        })
        );
    }

    // Update the given pool's EVO allocation points. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyRole(ADMIN_ROLE) {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 GovTokenForDev;
        uint256 GovTokenForFarmer;
        uint256 GovTokenForLP;
        uint256 GovTokenForCom;
        uint256 GovTokenForFounders;
        (
        GovTokenForDev,
        GovTokenForFarmer,
        GovTokenForLP,
        GovTokenForCom,
        GovTokenForFounders
        ) = getPoolReward(pool.lastRewardBlock, block.number, pool.allocPoint);
        // Mint some new EVO tokens for the farmer and store them in MasterInvestor.
        govToken.mint(address(this), GovTokenForFarmer);
        pool.accGovTokenPerShare = (((pool.accGovTokenPerShare + GovTokenForFarmer) * 1e12) / lpSupply);
        pool.lastRewardBlock = block.number;
        if (GovTokenForDev > 0) {
            govToken.mint(address(devAddr), GovTokenForDev);
            // Dev fund has xx% locked during the starting bonus period. After which locked funds drip
            // out linearly each block over 3 years.
            if (block.number <= FINISH_BONUS_AT_BLOCK) {
                govToken.lock(address(devAddr), ((GovTokenForDev * 75) / 100));
            }
        }
        if (GovTokenForLP > 0) {
            govToken.mint(liquidityAddr, GovTokenForLP);
            // LP + Partnership fund has only xx% locked over time as most of it is needed early on for
            // incentives and listings. The locked amount will drip out linearly each block after the bonus period.
            if (block.number <= FINISH_BONUS_AT_BLOCK) {
                govToken.lock(address(liquidityAddr), ((GovTokenForLP * 45) / 100));
            }
        }
        if (GovTokenForCom > 0) {
            govToken.mint(comFundAddr, GovTokenForCom);
            //Community Fund has xx% locked during bonus period and then drips out linearly.
            if (block.number <= FINISH_BONUS_AT_BLOCK) {
                govToken.lock(address(comFundAddr), ((GovTokenForCom * 85) / 100));
            }
        }
        if (GovTokenForFounders > 0) {
            govToken.mint(founderAddr, GovTokenForFounders);
            //The Founders reward has xx% of their funds locked during the bonus period which then drip out linearly.
            if (block.number <= FINISH_BONUS_AT_BLOCK) {
                govToken.lock(address(founderAddr), ((GovTokenForFounders * 95) / 100));
            }
        }
    }

    // |--------------------------------------|
    // [20, 30, 40, 50, 60, 70, 80, 99999999]
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 result = 0;
        if (_from < START_BLOCK) return 0;

        for (uint256 i = 0; i < HALVING_AT_BLOCK.length; i++) {
            uint256 endBlock = HALVING_AT_BLOCK[i];
            if (i > REWARD_MULTIPLIER.length - 1) return 0;

            if (_to <= endBlock) {
                uint256 m = ((_to - _from) * REWARD_MULTIPLIER[i]);
                return result + m;
            }

            if (_from < endBlock) {
                uint256 m = ((endBlock - _from) * REWARD_MULTIPLIER[i]);
                _from = endBlock;
                result += m;
            }
        }

        return result;
    }

    function getLockPercentage(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 result = 0;
        if (_from < START_BLOCK) return 100;

        for (uint256 i = 0; i < HALVING_AT_BLOCK.length; i++) {
            uint256 endBlock = HALVING_AT_BLOCK[i];
            if (i > PERCENT_LOCK_BONUS_REWARD.length - 1) return 0;

            if (_to <= endBlock) {
                return PERCENT_LOCK_BONUS_REWARD[i];
            }
        }

        return result;
    }

    function getPoolReward(uint256 _from, uint256 _to, uint256 _allocPoint) public view
    returns (uint256 forDev, uint256 forFarmer, uint256 forLP, uint256 forCom, uint256 forFounders) {
        uint256 multiplier = getMultiplier(_from, _to);
        uint256 amount = (((multiplier * REWARD_PER_BLOCK) * _allocPoint) / totalAllocPoint);
        uint256 GovernanceTokenCanMint = govToken.cap() - govToken.totalSupply();

        if (GovernanceTokenCanMint < amount) {
            // If there aren't enough governance tokens left to mint before the cap,
            // just give all of the possible tokens left to the farmer.
            forDev = 0;
            forFarmer = GovernanceTokenCanMint;
            forLP = 0;
            forCom = 0;
            forFounders = 0;
        } else {
            // Otherwise, give the farmer their full amount and also give some
            // extra to the dev, LP, com, and founders wallets.
            forDev = ((amount * PERCENT_FOR_DEV) / 100);
            forFarmer = amount;
            forLP = ((amount * PERCENT_FOR_LP) / 100);
            forCom = ((amount * PERCENT_FOR_COM) / 100);
            forFounders = ((amount * PERCENT_FOR_FOUNDERS) / 100);
        }
    }

    // View function to see pending EVO on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGovTokenPerShare = pool.accGovTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply > 0) {
            uint256 GovTokenForFarmer;
            (, GovTokenForFarmer, , , ) = getPoolReward(pool.lastRewardBlock, block.number, pool.allocPoint);
            accGovTokenPerShare = (((accGovTokenPerShare + GovTokenForFarmer) * 1e12) / lpSupply);
        }
        return (((user.amount * accGovTokenPerShare) / 1e12) - user.rewardDebt);
    }

    function claimRewards(uint256[] memory _pids) public {
        for (uint256 i = 0; i < _pids.length; i++) {
            claimReward(_pids[i]);
        }
    }

    function claimReward(uint256 _pid) public {
        updatePool(_pid);
        _harvest(_pid);
    }

    // lock a % of reward if it comes from bonus time.
    function _harvest(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // Only harvest if the user amount is greater than 0.
        if (user.amount > 0) {
            // Calculate the pending reward. This is the user's amount of LP tokens multiplied by
            // the accGovTokenPerShare of the pool, minus the user's rewardDebt.
            uint256 pending = (((user.amount * pool.accGovTokenPerShare) / 1e12) - user.rewardDebt);

            // Make sure we aren't giving more tokens than we have in the MasterInvestor contract.
            uint256 masterBal = govToken.balanceOf(address(this));

            if (pending > masterBal) {
                pending = masterBal;
            }

            if (pending > 0) {
                // If the user has a positive pending balance of tokens, transfer
                // those tokens from MasterInvestor to their wallet.
                govToken.transfer(msg.sender, pending);
                uint256 lockAmount = 0;
                if (user.rewardDebtAtBlock <= FINISH_BONUS_AT_BLOCK) {
                    // If we are before the FINISH_BONUS_AT_BLOCK number, we need
                    // to lock some of those tokens, based on the current lock
                    // percentage of their tokens they just received.
                    uint256 lockPercentage = getLockPercentage(block.number - 1, block.number);
                    lockAmount = ((pending * lockPercentage) / 100);
                    govToken.lock(msg.sender, lockAmount);
                }
                // Reset the rewardDebtAtBlock to the current block for the user.
                user.rewardDebtAtBlock = block.number;

                emit SendGovernanceTokenReward(msg.sender, _pid, pending, lockAmount);
            }
            // Recalculate the rewardDebt for the user.
            user.rewardDebt = ((user.amount * pool.accGovTokenPerShare) / 1e12);
        }
    }

    function getGlobalAmount(address _user) public view returns (uint256) {
        UserGlobalInfo storage current = userGlobalInfo[_user];
        return current.globalAmount;
    }

    function getGlobalRefAmount(address _user) public view returns (uint256) {
        UserGlobalInfo storage current = userGlobalInfo[_user];
        return current.globalRefAmount;
    }

    function getTotalRefs(address _user) public view returns (uint256) {
        UserGlobalInfo storage current = userGlobalInfo[_user];
        return current.totalReferrals;
    }

    function getRefValueOf(address _user, address _user2) public view returns (uint256) {
        UserGlobalInfo storage current = userGlobalInfo[_user];
        return current.referrals[_user2];
    }

    // Deposit LP tokens to MasterInvestor for EVO allocation.
    function deposit(uint256 _pid, uint256 _amount, address _ref) public nonReentrant {
        require(_amount > 0, "MasterInvestor::deposit: amount must be greater than 0");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        UserInfo storage devr = userInfo[_pid][devAddr];
        UserGlobalInfo storage refer = userGlobalInfo[_ref];
        UserGlobalInfo storage current = userGlobalInfo[msg.sender];

        if (refer.referrals[msg.sender] > 0) {
            refer.referrals[msg.sender] += _amount;
            refer.globalRefAmount += _amount;
        } else {
            refer.referrals[msg.sender] += _amount;
            refer.totalReferrals += 1;
            refer.globalRefAmount += _amount;
        }

        current.globalAmount += ((_amount * userDepFee) / 100);

        // When a user deposits, we need to update the pool and harvest beforehand,
        // since the rates will change.
        updatePool(_pid);
        _harvest(_pid);
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        if (user.amount == 0) {
            user.rewardDebtAtBlock = block.number;
        }
        user.amount += (_amount - ((_amount * userDepFee) / 10000));
        user.rewardDebt = ((user.amount * pool.accGovTokenPerShare) / 1e12);
        devr.amount += (_amount - ((_amount * devDepFee) / 10000));
        devr.rewardDebt = ((devr.amount * pool.accGovTokenPerShare) / 1e12);
        emit Deposit(msg.sender, _pid, _amount);
        if (user.firstDepositBlock > 0) {} else {
            user.firstDepositBlock = block.number;
        }
        user.lastDepositBlock = block.number;
    }

    // Withdraw LP tokens from MasterInvestor.
    function withdraw(uint256 _pid, uint256 _amount, address _ref) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        UserGlobalInfo storage refer = userGlobalInfo[_ref];
        UserGlobalInfo storage current = userGlobalInfo[msg.sender];
        require(user.amount >= _amount, "MasterInvestor::withdraw: not good");
        if (_ref != address(0)) {
            refer.referrals[msg.sender] -= _amount;
            refer.globalRefAmount -= _amount;
        }
        current.globalAmount -= _amount;

        updatePool(_pid);
        _harvest(_pid);

        if (_amount > 0) {
            user.amount -= _amount;
            if (user.lastWithdrawBlock > 0) {
                user.blockdelta = block.number - user.lastWithdrawBlock;
            } else {
                user.blockdelta = block.number - user.firstDepositBlock;
            }
            if (user.blockdelta == blockDeltaStartStage[0] || block.number == user.lastDepositBlock) {
                //25% fee for withdrawals of LP tokens in the same block this is to prevent abuse from flash loans
                pool.lpToken.safeTransfer(address(msg.sender), ((_amount * userFeeStage[0]) / 100));
                pool.lpToken.safeTransfer(address(devAddr), ((_amount * devFeeStage[0]) / 100));
            } else if (user.blockdelta >= blockDeltaStartStage[1] && user.blockdelta <= blockDeltaEndStage[0]) {
                //8% fee if a user deposits and withdraws in between same block and 59 minutes.
                pool.lpToken.safeTransfer(address(msg.sender), ((_amount * devFeeStage[1]) / 100));
                pool.lpToken.safeTransfer(address(devAddr), ((_amount * devFeeStage[1]) / 100));
            } else if (user.blockdelta >= blockDeltaStartStage[2] && user.blockdelta <= blockDeltaEndStage[1]) {
                //4% fee if a user deposits and withdraws after 1 hour but before 1 day.
                pool.lpToken.safeTransfer(address(msg.sender), ((_amount * devFeeStage[2]) / 100));
                pool.lpToken.safeTransfer(address(devAddr), ((_amount * devFeeStage[2]) / 100));
            } else if (user.blockdelta >= blockDeltaStartStage[3] && user.blockdelta <= blockDeltaEndStage[2]) {
                //2% fee if a user deposits and withdraws between after 1 day but before 3 days.
                pool.lpToken.safeTransfer(address(msg.sender), ((_amount * devFeeStage[3]) / 100));
                pool.lpToken.safeTransfer(address(devAddr), ((_amount * devFeeStage[3]) / 100));
            } else if (user.blockdelta >= blockDeltaStartStage[4] && user.blockdelta <= blockDeltaEndStage[3]) {
                //1% fee if a user deposits and withdraws after 3 days but before 5 days.
                pool.lpToken.safeTransfer(address(msg.sender), ((_amount * devFeeStage[4]) / 100));
                pool.lpToken.safeTransfer(address(devAddr), ((_amount * devFeeStage[4]) / 100));
            } else if (user.blockdelta >= blockDeltaStartStage[5] && user.blockdelta <= blockDeltaEndStage[4]) {
                //0.5% fee if a user deposits and withdraws if the user withdraws after 5 days but before 2 weeks.
                pool.lpToken.safeTransfer(address(msg.sender), ((_amount * devFeeStage[5]) / 1000));
                pool.lpToken.safeTransfer(address(devAddr), ((_amount * devFeeStage[5]) / 1000));
            } else if (user.blockdelta >= blockDeltaStartStage[6] && user.blockdelta <= blockDeltaEndStage[5]) {
                //0.25% fee if a user deposits and withdraws after 2 weeks.
                pool.lpToken.safeTransfer(address(msg.sender), ((_amount * devFeeStage[6]) / 10000));
                pool.lpToken.safeTransfer(address(devAddr), ((_amount * devFeeStage[6]) / 10000));
            } else if (user.blockdelta > blockDeltaStartStage[7]) {
                //0.1% fee if a user deposits and withdraws after 4 weeks
                pool.lpToken.safeTransfer(address(msg.sender), ((_amount * devFeeStage[7]) / 10000));
                pool.lpToken.safeTransfer(address(devAddr), ((_amount * devFeeStage[7]) / 10000));
            }
            user.rewardDebt = ((user.amount * pool.accGovTokenPerShare) / 1e12);
            emit Withdraw(msg.sender, _pid, _amount);
            user.lastWithdrawBlock = block.number;
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY. This has the same 25% fee as same block withdrawals
    // to prevent abuse of this function.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        //reordered from Sushi function to prevent risk of reentrancy
        uint256 amountToSend = ((user.amount * 75) / 100);
        uint256 devToSend = ((user.amount * 25) / 100);
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amountToSend);
        pool.lpToken.safeTransfer(address(devAddr), devToSend);
        emit EmergencyWithdraw(msg.sender, _pid, amountToSend);
    }

    // Safe GovToken transfer function, just in case if rounding error causes pool to not have enough GovTokens.
    function safeGovTokenTransfer(address _to, uint256 _amount) internal {
        uint256 govTokenBal = govToken.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > govTokenBal) {
            transferSuccess = govToken.transfer(_to, govTokenBal);
        } else {
            transferSuccess = govToken.transfer(_to, _amount);
        }
        require(transferSuccess, "MasterInvestor::safeGovTokenTransfer: transfer failed");
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public onlyRole(AUTHORIZED_ROLE) {
        devAddr = _devaddr;
    }

    // Update Finish Bonus Block
    function bonusFinishUpdate(uint256 _newFinish) public onlyRole(AUTHORIZED_ROLE) {
        FINISH_BONUS_AT_BLOCK = _newFinish;
    }

    // Update Halving At Block
    function halvingUpdate(uint256[] memory _newHalving) public onlyRole(AUTHORIZED_ROLE) {
        HALVING_AT_BLOCK = _newHalving;
    }

    // Update Liquidityaddr
    function lpUpdate(address _newLP) public onlyRole(AUTHORIZED_ROLE) {
        liquidityAddr = _newLP;
    }

    // Update comfundaddr
    function comUpdate(address _newCom) public onlyRole(AUTHORIZED_ROLE) {
        comFundAddr = _newCom;
    }

    // Update founderAddr
    function founderUpdate(address _newFounder) public onlyRole(AUTHORIZED_ROLE) {
        founderAddr = _newFounder;
    }

    // Update Reward Per Block
    function rewardUpdate(uint256 _newReward) public onlyRole(AUTHORIZED_ROLE) {
        REWARD_PER_BLOCK = _newReward;
    }

    // Update Rewards Mulitplier Array
    function rewardMulUpdate(uint256[] memory _newMulReward) public onlyRole(AUTHORIZED_ROLE) {
        REWARD_MULTIPLIER = _newMulReward;
    }

    // Update % lock for general users
    function lockUpdate(uint256[] memory _newlock) public onlyRole(AUTHORIZED_ROLE) {
        PERCENT_LOCK_BONUS_REWARD = _newlock;
    }

    // Update % lock for dev
    function lockdevUpdate(uint256 _newdevlock) public onlyRole(AUTHORIZED_ROLE) {
        PERCENT_FOR_DEV = _newdevlock;
    }

    // Update % lock for LP
    function locklpUpdate(uint256 _newlplock) public onlyRole(AUTHORIZED_ROLE) {
        PERCENT_FOR_LP = _newlplock;
    }

    // Update % lock for COM
    function lockcomUpdate(uint256 _newcomlock) public onlyRole(AUTHORIZED_ROLE) {
        PERCENT_FOR_COM = _newcomlock;
    }

    // Update % lock for Founders
    function lockfounderUpdate(uint256 _newfounderlock) public onlyRole(AUTHORIZED_ROLE) {
        PERCENT_FOR_FOUNDERS = _newfounderlock;
    }

    // Update START_BLOCK
    function starblockUpdate(uint256 _newstarblock) public onlyRole(AUTHORIZED_ROLE) {
        START_BLOCK = _newstarblock;
    }

    function getNewRewardPerBlock(uint256 pid1) public view returns (uint256) {
        uint256 multiplier = getMultiplier(block.number - 1, block.number);
        if (pid1 == 0) {
            return multiplier * REWARD_PER_BLOCK;
        } else {
            return (((multiplier * REWARD_PER_BLOCK) * poolInfo[pid1 - 1].allocPoint) / totalAllocPoint);
        }
    }

    function userDelta(uint256 _pid) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.lastWithdrawBlock > 0) {
            uint256 estDelta = block.number - user.lastWithdrawBlock;
            return estDelta;
        } else {
            uint256 estDelta = block.number - user.firstDepositBlock;
            return estDelta;
        }
    }

    function reviseWithdraw(uint256 _pid, address _user, uint256 _block) public onlyRole(AUTHORIZED_ROLE) {
        UserInfo storage user = userInfo[_pid][_user];
        user.lastWithdrawBlock = _block;
    }

    function reviseDeposit(uint256 _pid, address _user, uint256 _block) public onlyRole(AUTHORIZED_ROLE) {
        UserInfo storage user = userInfo[_pid][_user];
        user.firstDepositBlock = _block;
    }

    function setStageStarts(uint256[] memory _blockStarts) public onlyRole(AUTHORIZED_ROLE) {
        blockDeltaStartStage = _blockStarts;
    }

    function setStageEnds(uint256[] memory _blockEnds) public onlyRole(AUTHORIZED_ROLE) {
        blockDeltaEndStage = _blockEnds;
    }

    function setUserFeeStage(uint256[] memory _userFees) public onlyRole(AUTHORIZED_ROLE) {
        userFeeStage = _userFees;
    }

    function setDevFeeStage(uint256[] memory _devFees) public onlyRole(AUTHORIZED_ROLE) {
        devFeeStage = _devFees;
    }

    function setDevDepFee(uint256 _devDepFees) public onlyRole(AUTHORIZED_ROLE) {
        devDepFee = _devDepFees;
    }

    function setUserDepFee(uint256 _usrDepFees) public onlyRole(AUTHORIZED_ROLE) {
        userDepFee = _usrDepFees;
    }

    function reclaimTokenOwnership(address _newOwner) public onlyRole(AUTHORIZED_ROLE) {
        govToken.transferOwnership(_newOwner);
    }
}