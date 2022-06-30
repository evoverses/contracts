// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../deprecated/EvoToken.sol";
import "../deprecated/IcEVOUpgradeable.sol";

// MasterInvestor is the master investor of whatever investments are available.
contract MasterInvestor is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AUTHORIZED_ROLE = keccak256("AUTHORIZED_ROLE");

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardDebtAtTime; // the last time a user staked.
        uint256 lastWithdrawTime; // the last time a user withdrew.
        uint256 firstDepositTime; // the last time a user deposited.
        uint256 timeDelta; // time passed since withdrawals
        uint256 lastDepositTime;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. EVO to distribute per second.
        uint256 lastRewardTime; // Last time that EVO distribution occurs.
        uint256 accGovTokenPerShare; // Accumulated EVO per share, times 1e12. See below.
    }

    // Fixes stack too deep
    struct ConstructorParams {
        EvoToken govToken;
        uint256 rewardPerSecond;
        uint256 startTime;
        uint256 halvingAfterTime;
        uint256 userDepositFee;
        uint256 devDepositFee;
        address devAddress;
        address lpAddress;
        address communityFundAddress;
        address founderAddress;
        uint256[] rewardMultipliers;
        uint256[] userFeeStages;
        uint256[] devFeeStages;
        uint256[] percentLockBonusReward;
    }

    // The EVO token
    EvoToken public GOV_TOKEN;
    //An ETH/USDC Oracle (Chainlink)
    address public USD_ORACLE;
    // Dev address.
    address public DEV_ADDRESS;
    // LP address
    address public LP_ADDRESS;
    // Community Fund Address
    address public COMMUNITY_FUND_ADDRESS;
    // Founder Reward
    address public FOUNDER_ADDRESS;
    // EVO created per second.
    uint256 public REWARD_PER_SECOND;
    // Bonus multiplier for early EVO makers.
    uint256[] public REWARD_MULTIPLIERS; // init in constructor function
    uint256[] public HALVING_AT_TIMES; // init in constructor function
    uint256[] public USER_FEE_STAGES;
    uint256[] public DEV_FEE_STAGES;
    uint256 public FINISH_BONUS_AT_TIME;
    uint256 public USER_DEP_FEE;
    uint256 public DEV_DEP_FEE;

    // The time when EVO mining starts.
    uint256 public START_TIME;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public TOTAL_ALLOCATION_POINTS;

    uint256[] public PERCENT_LOCK_BONUS_REWARD; // lock xx% of bonus reward
    uint256 public PERCENT_FOR_DEV; // dev bounties
    uint256 public PERCENT_FOR_LP; // LP fund
    uint256 public PERCENT_FOR_COM; // community fund
    uint256 public PERCENT_FOR_FOUNDERS; // founders fund

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => uint256) public poolId; // poolId starting from 1, subtract 1 before using with poolInfo
    // Info of each user that stakes LP tokens. pid => user address => info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => uint256) public userGlobalInfo;
    mapping(IERC20Upgradeable => bool) public poolExistence;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SendGovernanceTokenReward(address indexed user, uint256 indexed pid, uint256 amount, uint256 lockAmount);

    modifier nonDuplicated(IERC20Upgradeable _lpToken) {
        require(poolExistence[_lpToken] == false, "MasterInvestor::nonDuplicated: duplicated");
        _;
    }

    modifier isDisabled() {
        require(false, "MasterInvestor::Deposits disabled. Please check discord. https://evoverses.com/discord");
        _;
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(ConstructorParams memory params) initializer public {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(AUTHORIZED_ROLE, _msgSender());

        USER_FEE_STAGES = params.userFeeStages;
        DEV_FEE_STAGES = params.devFeeStages;
        GOV_TOKEN = params.govToken;
        REWARD_PER_SECOND = params.rewardPerSecond;
        START_TIME = params.startTime;
        USER_DEP_FEE = params.userDepositFee;
        DEV_DEP_FEE = params.devDepositFee;
        REWARD_MULTIPLIERS = params.rewardMultipliers;
        DEV_ADDRESS = params.devAddress;
        LP_ADDRESS = params.lpAddress;
        COMMUNITY_FUND_ADDRESS = params.communityFundAddress;
        FOUNDER_ADDRESS = params.founderAddress;
        PERCENT_LOCK_BONUS_REWARD = params.percentLockBonusReward;
        TOTAL_ALLOCATION_POINTS = 0;
        for (uint256 i = 0; i < REWARD_MULTIPLIERS.length - 1; i++) {
            uint256 halvingAtTime = (params.halvingAfterTime * (i+1)) + params.startTime + 1;
            HALVING_AT_TIMES.push(halvingAtTime);
        }
        FINISH_BONUS_AT_TIME = (params.halvingAfterTime * (REWARD_MULTIPLIERS.length - 1)) + params.startTime;
        HALVING_AT_TIMES.push(2**256 - 1);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20Upgradeable _lpToken, bool _withUpdate) public onlyRole(ADMIN_ROLE) nonDuplicated(_lpToken) {
        require(poolId[address(_lpToken)] == 0, "MasterInvestor::add: lp is already in pool");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime = (block.timestamp > START_TIME) ? block.timestamp : START_TIME;
        TOTAL_ALLOCATION_POINTS += _allocPoint;
        poolId[address(_lpToken)] = (poolInfo.length + 1);
        poolExistence[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardTime: lastRewardTime,
        accGovTokenPerShare: 0
        })
        );
    }

    // Update the given pool's EVO allocation points.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyRole(ADMIN_ROLE) {
        if (_withUpdate) {
            massUpdatePools();
        }
        TOTAL_ALLOCATION_POINTS = TOTAL_ALLOCATION_POINTS - poolInfo[_pid].allocPoint + _allocPoint;
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
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
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
        ) = getPoolReward(pool.lastRewardTime, block.timestamp, pool.allocPoint);
        // Mint some new EVO tokens for the farmer and store them in MasterInvestor.
        GOV_TOKEN.mint(address(this), GovTokenForFarmer);
        pool.accGovTokenPerShare += (GovTokenForFarmer * 1e12) / lpSupply;
        pool.lastRewardTime = block.timestamp;

        IcEVOUpgradeable2 cEVO = IcEVOUpgradeable2(0x465d89df3e9B1AFB6957B58Be6137feeBB8e9f61);
        if (GovTokenForDev > 0) {
            uint256 cEVOForDev = (block.timestamp <= FINISH_BONUS_AT_TIME)
            ? ((GovTokenForDev * 75) / 100)
            : 0;
            uint256 govTokenForDev = block.timestamp <= FINISH_BONUS_AT_TIME
            ? ((GovTokenForDev * 25) / 100)
            : GovTokenForDev;
            GOV_TOKEN.mint(address(DEV_ADDRESS), govTokenForDev);
            if (cEVOForDev > 0) {
                cEVO.mintLocked(address(DEV_ADDRESS), cEVOForDev);
            }
        }
        if (GovTokenForLP > 0) {
            uint256 cEVOForLP = (block.timestamp <= FINISH_BONUS_AT_TIME)
            ? ((GovTokenForLP * 45) / 100)
            : 0;
            uint256 govTokenForLP = block.timestamp <= FINISH_BONUS_AT_TIME
            ? ((GovTokenForLP * 55) / 100)
            : GovTokenForLP;
            GOV_TOKEN.mint(address(LP_ADDRESS), govTokenForLP);
            if (cEVOForLP > 0) {
                cEVO.mintLocked(address(LP_ADDRESS), cEVOForLP);
            }
        }
        if (GovTokenForCom > 0) {
            uint256 cEVOForCom = (block.timestamp <= FINISH_BONUS_AT_TIME)
            ? ((GovTokenForCom * 85) / 100)
            : 0;
            uint256 govTokenForCom = block.timestamp <= FINISH_BONUS_AT_TIME
            ? ((GovTokenForCom * 15) / 100)
            : GovTokenForCom;
            GOV_TOKEN.mint(address(COMMUNITY_FUND_ADDRESS), govTokenForCom);
            if (cEVOForCom > 0) {
                cEVO.mintLocked(address(COMMUNITY_FUND_ADDRESS), cEVOForCom);
            }
        }
        if (GovTokenForFounders > 0) {
            uint256 cEVOForFounders = (block.timestamp <= FINISH_BONUS_AT_TIME)
            ? ((GovTokenForFounders * 95) / 100)
            : 0;
            uint256 govTokenForFounders = block.timestamp <= FINISH_BONUS_AT_TIME
            ? ((GovTokenForFounders * 5) / 100)
            : GovTokenForFounders;
            GOV_TOKEN.mint(address(FOUNDER_ADDRESS), govTokenForFounders);
            if (cEVOForFounders > 0) {
                cEVO.mintLocked(address(FOUNDER_ADDRESS), cEVOForFounders);
            }
        }
    }

    // |--------------------------------------|
    // [20, 30, 40, 50, 60, 70, 80, 99999999]
    // Return reward multiplier over the given _from to _to time.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 result = 0;
        if (_from < START_TIME) return 0;

        for (uint256 i = 0; i < HALVING_AT_TIMES.length; i++) {
            uint256 endTime = HALVING_AT_TIMES[i];
            if (i > REWARD_MULTIPLIERS.length - 1) return 0;

            if (_to <= endTime) {
                uint256 m = ((_to - _from) * REWARD_MULTIPLIERS[i]);
                return result + m;
            }

            if (_from < endTime) {
                uint256 m = ((endTime - _from) * REWARD_MULTIPLIERS[i]);
                _from = endTime;
                result += m;
            }
        }

        return result;
    }

    function getLockPercentage(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 result = 0;
        if (_from < START_TIME) return 100;

        for (uint256 i = 0; i < HALVING_AT_TIMES.length; i++) {
            uint256 endTime = HALVING_AT_TIMES[i];
            if (i > PERCENT_LOCK_BONUS_REWARD.length - 1) return 0;

            if (_to <= endTime) {
                return PERCENT_LOCK_BONUS_REWARD[i];
            }
        }

        return result;
    }

    function getPoolReward(uint256 _from, uint256 _to, uint256 _allocPoint) public view
    returns (uint256 forDev, uint256 forFarmer, uint256 forLP, uint256 forCom, uint256 forFounders) {
        uint256 multiplier = getMultiplier(_from, _to);
        uint256 amount = (((multiplier * REWARD_PER_SECOND) * _allocPoint) / TOTAL_ALLOCATION_POINTS);
        uint256 GovernanceTokenCanMint = GOV_TOKEN.cap() - GOV_TOKEN.totalSupply();

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
        if (block.timestamp > pool.lastRewardTime && lpSupply > 0) {
            uint256 GovTokenForFarmer;
            (, GovTokenForFarmer, , , ) = getPoolReward(pool.lastRewardTime, block.timestamp, pool.allocPoint);
            accGovTokenPerShare += (GovTokenForFarmer * 1e12) / lpSupply;
        }
        return ((user.amount * accGovTokenPerShare) / 1e12) - user.rewardDebt;
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
        _harvestFor(_pid, _msgSender());
    }

    // lock a % of reward if it comes from bonus time.
    function _harvestFor(uint256 _pid, address _address) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_address];

        // Only harvest if the user amount is greater than 0.
        if (user.amount > 0) {
            // Calculate the pending reward. This is the user's amount of LP tokens multiplied by
            // the accGovTokenPerShare of the pool, minus the user's rewardDebt.
            uint256 pending = ((user.amount * pool.accGovTokenPerShare) / 1e12) - user.rewardDebt;

            // Make sure we aren't giving more tokens than we have in the MasterInvestor contract.
            uint256 masterBal = GOV_TOKEN.balanceOf(address(this));

            if (pending > masterBal) {
                pending = masterBal;
            }

            if (pending > 0) {


                uint256 lockAmount = 0;
                if (user.rewardDebtAtTime <= FINISH_BONUS_AT_TIME) {
                    uint256 lockPercentage = getLockPercentage(block.timestamp - 1, block.timestamp);
                    lockAmount = ((pending * lockPercentage) / 100);

                }
                GOV_TOKEN.transfer(_address, pending - lockAmount);
                if (lockAmount > 0) {
                    IcEVOUpgradeable2 cEVO = IcEVOUpgradeable2(0x465d89df3e9B1AFB6957B58Be6137feeBB8e9f61);
                    cEVO.mintLocked(_address, lockAmount);
                }
                // Reset the rewardDebtAtTime to the current time for the user.
                user.rewardDebtAtTime = block.timestamp;

                emit SendGovernanceTokenReward(_address, _pid, pending, lockAmount);
            }
            // Recalculate the rewardDebt for the user.
            user.rewardDebt = (user.amount * pool.accGovTokenPerShare) / 1e12;
        }
    }

    // Deposit LP tokens to MasterInvestor for EVO allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant isDisabled {
        require(_amount > 0, "MasterInvestor::deposit: amount must be greater than 0");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        UserInfo storage devr = userInfo[_pid][DEV_ADDRESS];

        // When a user deposits, we need to update the pool and harvest beforehand,
        // since the rates will change.
        updatePool(_pid);
        _harvest(_pid);
        pool.lpToken.safeTransferFrom(_msgSender(), address(this), _amount);
        if (user.amount == 0) {
            user.rewardDebtAtTime = block.timestamp;
        }
        user.amount += _amount - ((_amount * USER_DEP_FEE) / 10000);
        user.rewardDebt = (user.amount * pool.accGovTokenPerShare) / 1e12;
        devr.amount += _amount - ((_amount * DEV_DEP_FEE) / 10000);
        devr.rewardDebt = (devr.amount * pool.accGovTokenPerShare) / 1e12;
        emit Deposit(_msgSender(), _pid, _amount);
        if (user.firstDepositTime > 0) {} else {
            user.firstDepositTime = block.timestamp;
        }
        user.lastDepositTime = block.timestamp;
    }

    // Withdraw LP tokens from MasterInvestor.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(user.amount >= _amount, "MasterInvestor::withdraw: not good");
        updatePool(_pid);
        _harvest(_pid);

        if (_amount > 0) {
            user.amount -= _amount;
            if (user.lastWithdrawTime > 0) {
                user.timeDelta = block.timestamp - user.lastWithdrawTime;
            } else {
                user.timeDelta = block.timestamp - user.firstDepositTime;
            }
            uint256 userAmount = _amount;
            uint256 devAmount = 0;
            if (block.timestamp == user.lastDepositTime) {
                // 25% fee for withdrawals of LP tokens in the same second. This is to prevent abuse from flash loans
                // userAmount = (_amount * USER_FEE_STAGES[0]) / 100;
                devAmount = (_amount * DEV_FEE_STAGES[0]) / 100;
            } else if (user.timeDelta >= 1 && user.timeDelta < 60 minutes) {
                // 8% fee if a user deposits and withdraws in between same second and 60 minutes.
                // userAmount = (_amount * USER_FEE_STAGES[1]) / 100;
                devAmount = (_amount * DEV_FEE_STAGES[1]) / 100;
            } else if (user.timeDelta >= 60 minutes && user.timeDelta < 1 days) {
                // 4% fee if a user deposits and withdraws after 1 hour but before 1 day.
                // userAmount = (_amount * USER_FEE_STAGES[2]) / 100;
                devAmount = (_amount * DEV_FEE_STAGES[2]) / 100;
            } else if (user.timeDelta >= 1 days && user.timeDelta < 3 days) {
                // 2% fee if a user deposits and withdraws between after 1 day but before 3 days.
                // userAmount = (_amount * USER_FEE_STAGES[3]) / 100;
                devAmount = (_amount * DEV_FEE_STAGES[3]) / 100;
            } else if (user.timeDelta >= 3 days && user.timeDelta < 5 days) {
                // 1% fee if a user deposits and withdraws after 3 days but before 5 days.
                // userAmount = (_amount * USER_FEE_STAGES[4]) / 100;
                devAmount = (_amount * DEV_FEE_STAGES[4]) / 100;
            } else if (user.timeDelta >= 5 days && user.timeDelta < 2 weeks) {
                //0.5% fee if a user deposits and withdraws if the user withdraws after 5 days but before 2 weeks.
                // userAmount = (_amount * USER_FEE_STAGES[5]) / 1000;
                devAmount = (_amount * DEV_FEE_STAGES[5]) / 1000;
            } else if (user.timeDelta >= 2 weeks && user.timeDelta < 4 weeks) {
                //0.25% fee if a user deposits and withdraws after 2 weeks.
                // userAmount = (_amount * USER_FEE_STAGES[6]) / 10000;
                devAmount = (_amount * DEV_FEE_STAGES[6]) / 10000;
            } else if (user.timeDelta >= 4 weeks) {
                //0.1% fee if a user deposits and withdraws after 4 weeks
                // userAmount = (_amount * USER_FEE_STAGES[7]) / 10000;
                devAmount = (_amount * DEV_FEE_STAGES[7]) / 10000;
            } else {
                revert("Something is very broken");
            }
            pool.lpToken.safeTransfer(_msgSender(), userAmount);
            pool.lpToken.safeTransfer(DEV_ADDRESS, devAmount);

            user.rewardDebt = (user.amount * pool.accGovTokenPerShare) / 1e12;

            emit Withdraw(_msgSender(), _pid, _amount);

            user.lastWithdrawTime = block.timestamp;
        }
    }

    // Withdraw LP tokens from MasterInvestor.
    function withdrawForClaim(uint256 _pid, uint256 _amount, address _address)
    public nonReentrant onlyRole(AUTHORIZED_ROLE) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_address];
        require(user.amount >= _amount, "MasterInvestor::withdraw: not good");
        updatePool(_pid);
        _harvestFor(_pid, _address);

        if (_amount > 0) {
            user.amount -= _amount;
            pool.lpToken.safeTransfer(_address, _amount);
            user.rewardDebt = (user.amount * pool.accGovTokenPerShare) / 1e12;
            emit Withdraw(_address, _pid, _amount);
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY. This has the same 25% fee as same second withdrawals
    // to prevent abuse of this function.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        //reordered from Sushi function to prevent risk of reentrancy
        uint256 amountToSend = ((user.amount * USER_FEE_STAGES[0]) / 100);
        uint256 devToSend = ((user.amount * DEV_FEE_STAGES[0]) / 100);
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(_msgSender(), amountToSend);
        pool.lpToken.safeTransfer(DEV_ADDRESS, devToSend);
        emit EmergencyWithdraw(_msgSender(), _pid, amountToSend);
    }

    // Safe GovToken transfer function, just in case if rounding error causes pool to not have enough GovTokens.
    function safeGovTokenTransfer(address _to, uint256 _amount) internal {
        uint256 govTokenBal = GOV_TOKEN.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > govTokenBal) {
            transferSuccess = GOV_TOKEN.transfer(_to, govTokenBal);
        } else {
            transferSuccess = GOV_TOKEN.transfer(_to, _amount);
        }
        require(transferSuccess, "MasterInvestor::safeGovTokenTransfer: transfer failed");
    }

    function getNewRewardPerSecond(uint256 pid1) public view returns (uint256) {
        uint256 multiplier = getMultiplier(block.timestamp - 1, block.timestamp);
        return (((multiplier * REWARD_PER_SECOND) * poolInfo[pid1].allocPoint) / TOTAL_ALLOCATION_POINTS);
    }

    function userDelta(uint256 _pid) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_msgSender()];
        if (user.lastWithdrawTime > 0) {
            return block.timestamp - user.lastWithdrawTime;
        }
        return block.timestamp - user.firstDepositTime;
    }

    function userDeltaOf(uint256 _pid, address _address) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_address];
        if (user.lastWithdrawTime > 0) {
            return block.timestamp - user.lastWithdrawTime;
        }
        return block.timestamp - user.firstDepositTime;
    }

    // Update Finish Bonus Time
    function updateLastRewardTime(uint256 time) public onlyRole(AUTHORIZED_ROLE) {
        FINISH_BONUS_AT_TIME = time;
    }

    // Update Halving At Time
    function updateHalvingAtTimes(uint256[] memory times) public onlyRole(AUTHORIZED_ROLE) {
        HALVING_AT_TIMES = times;
    }

    // Update Reward Per Second
    function updateRewardPerSecond(uint256 reward) public onlyRole(AUTHORIZED_ROLE) {
        REWARD_PER_SECOND = reward;
    }

    // Update Rewards Multiplier Array
    function updateRewardMultipliers(uint256[] memory multipliers) public onlyRole(AUTHORIZED_ROLE) {
        REWARD_MULTIPLIERS = multipliers;
    }

    // Update % lock for general users
    function updateUserLockPercents(uint256[] memory lockPercents) public onlyRole(AUTHORIZED_ROLE) {
        PERCENT_LOCK_BONUS_REWARD = lockPercents;
    }

    // Update START_TIME
    function updateStartTime(uint256 time) public onlyRole(AUTHORIZED_ROLE) {
        START_TIME = time;
    }

    function updateAddress(uint256 kind, address _address) public onlyRole(AUTHORIZED_ROLE) {
        if (kind == 1)  DEV_ADDRESS = _address;
        else if (kind == 2) LP_ADDRESS = _address;
        else if (kind == 3) COMMUNITY_FUND_ADDRESS = _address;
        else if (kind == 4) FOUNDER_ADDRESS = _address;
        else revert("Invalid kind identifier");
    }

    function updateLockPercent(uint256 kind, uint256 percent) public onlyRole(AUTHORIZED_ROLE) {
        if (kind == 1) PERCENT_FOR_DEV = percent;
        else if (kind == 2) PERCENT_FOR_LP = percent;
        else if (kind == 3) PERCENT_FOR_COM = percent;
        else if (kind == 4) PERCENT_FOR_FOUNDERS = percent;
        else revert("Invalid kind identifier");
    }

    function updateDepositFee(uint256 kind, uint256 fee) public onlyRole(AUTHORIZED_ROLE) {
        if (kind == 1) USER_DEP_FEE = fee;
        else if (kind == 2) DEV_DEP_FEE = fee;
        else revert("Invalid kind identifier");
    }
    function updateFeeStages(uint256 kind, uint256[] memory feeStages) public onlyRole(AUTHORIZED_ROLE) {
        if (kind == 1) USER_FEE_STAGES = feeStages;
        else if (kind == 2) DEV_FEE_STAGES = feeStages;
        else revert("Invalid kind identifier");
    }

    function reviseWithdraw(uint256 _pid, address _user, uint256 _time) public onlyRole(AUTHORIZED_ROLE) {
        UserInfo storage user = userInfo[_pid][_user];
        user.lastWithdrawTime = _time;
    }

    function reviseDeposit(uint256 _pid, address _user, uint256 _time) public onlyRole(AUTHORIZED_ROLE) {
        UserInfo storage user = userInfo[_pid][_user];
        user.firstDepositTime = _time;
    }

    function correctWithdrawal(uint256 _pid, address _user, uint256 _amount) public onlyRole(AUTHORIZED_ROLE) {
        PoolInfo storage pool = poolInfo[_pid];
        pool.lpToken.safeTransfer(_user, _amount);
        updatePool(_pid);
    }

    function reclaimTokenOwnership(address _newOwner) public onlyRole(AUTHORIZED_ROLE) {
        GOV_TOKEN.transferOwnership(_newOwner);
    }

    function totalAllocPoint() public view returns(uint256) {
        return TOTAL_ALLOCATION_POINTS;
    }
}