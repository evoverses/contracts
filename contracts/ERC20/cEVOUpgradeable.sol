// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";

import "./extensions/ERC20BurnableUpgradeable.sol";
import "../deprecated/OldTokenConstants.sol";
import "./interfaces/IMintable.sol";

/**
* @title Compensation EVO v2.0.0
* @author @DirtyCajunRice
*/
contract cEVOUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable, AccessControlUpgradeable,
ERC20PermitUpgradeable, ERC20BurnableUpgradeable, OldTokenConstants {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    address private EVO;

    uint256 public DEFAULT_VESTING_PERIOD;

    struct Disbursement {
        uint256 startTime;
        uint256 duration;
        uint256 amount;
        uint256 balance;
    }

    EnumerableSetUpgradeable.AddressSet private _globalWhitelist;

    mapping (address => EnumerableSetUpgradeable.AddressSet) private _whitelist;

    mapping (address => Disbursement[]) public disbursements;

    mapping (address => uint256) private _lockedOf;

    mapping (address => uint256) public transferTime;

    mapping (address => Disbursement) public selfDisbursement;

    modifier onlyWhitelist(address from, address to) {
        require(
            _globalWhitelist.contains(to)
            || _whitelist[from].contains(to)
            || from == address(0)
            || to == address(0),
            "cEVO is non-transferable"
        );
        _;
    }

    event ClaimedDisbursement(address indexed from, uint256 amount);
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("cEVO", "cEVO");
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init("cEVO");
        __ERC20Burnable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());

        EVO = 0x42006Ab57701251B580bDFc24778C43c9ff589A1;
        DEFAULT_VESTING_PERIOD = 365 days;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function mint(address _address, uint256 amount) public onlyRole(MINTER_ROLE) {
        uint256 locked = _lockedOf[_address];
        _lockedOf[_address] = 0;
        if (selfDisbursement[_address].duration == 0) {
            selfDisbursement[_address].startTime = 1681860918;
            selfDisbursement[_address].duration = 365 days;
        }
        selfDisbursement[_address].balance += locked + amount;
        selfDisbursement[_address].amount += locked + amount;

        IMintable(EVO).mint(address(this), amount);
        _mint(_address, amount);
    }

    function mintDisbursement(
        address to,
        uint256 startTime,
        uint256 duration,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) {
        uint256 _startTime = startTime > 0 ? startTime : block.timestamp;
        uint256 _duration = duration > 0 ? duration : DEFAULT_VESTING_PERIOD;
        disbursements[to].push(
          Disbursement(
            {
              startTime: _startTime,
              duration: _duration,
              amount: amount,
              balance: amount
            }
          )
        );
        IMintable(EVO).mint(address(this), amount);
        _mint(to, amount);
    }

    function bridgeMintDisbursement(
        address to,
        uint256 startTime,
        uint256 duration,
        uint256 amount,
        uint256 balance
    ) public onlyRole(MINTER_ROLE) {
        uint256 _startTime = startTime > 0 ? startTime : block.timestamp;
        uint256 _duration = duration > 0 ? duration : DEFAULT_VESTING_PERIOD;
        disbursements[to].push(
            Disbursement(
            {
            startTime: _startTime,
            duration: _duration,
            amount: amount,
            balance: balance
            }
            )
        );
        IMintable(EVO).mint(address(this), balance);
        _mint(to, balance);
    }

    function batchMintDisbursement(
        address[] memory to,
        uint256[] memory amount,
        uint256 startTime,
        uint256 duration
    ) public onlyRole(MINTER_ROLE) {
        require(to.length == amount.length, "to and amount arrays must match");
        for (uint256 i = 0; i < to.length; i++) {
            mintDisbursement(to[i], startTime, duration, amount[i]);
        }
    }

    function burn(uint256 amount) public virtual override(ERC20BurnableUpgradeable) {
        super.burn(amount);
        IMintable(EVO).burn(address(this), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual override(ERC20BurnableUpgradeable) {
        super.burnFrom(account, amount);
        IMintable(EVO).burnFrom(address(this), amount);
    }

    function useLocked(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(_lockedOf[account] >= amount, "Insufficient locked balance");
        _lockedOf[account] -= amount;
        _totalBurned += amount;
        _burn(account, amount);
        IMintable(EVO).burnFrom(address(this), amount);
    }

    function burnLocked() public onlyRole(MINTER_ROLE) {
        uint256 amount = balanceOf(address(this));
        _totalBurned += amount;
        _burn(address(this), amount);
        IMintable(EVO).burnFrom(address(this), amount);
    }

    function claimPending() public whenNotPaused {
        uint256 totalPending = 0;
        // pending disbursements;
        for (uint256 i = 0; i < disbursements[msg.sender].length; i++) {
            Disbursement storage d = disbursements[msg.sender][i];
            uint256 claimed = d.amount - d.balance;
            uint256 pendingPerSecond = d.amount / d.duration;
            uint256 pending = (d.startTime + d.duration) > block.timestamp
              ? ((block.timestamp - d.startTime) * pendingPerSecond)
              : d.amount;
            if (claimed < pending) {
                d.balance -= (pending - claimed);
                totalPending += (pending - claimed);
            }
        }
        Disbursement storage s = selfDisbursement[msg.sender];

        // pending original locked cEVO should be migrated
        uint256 locked = _lockedOf[msg.sender];
        if (locked > 0) {
            _lockedOf[msg.sender] = 0;
            if (s.duration == 0) {
                s.startTime = 1681860918;
                s.duration = DEFAULT_VESTING_PERIOD;
            }
            s.balance += locked;
            s.amount += locked;

        }
        // pending migrated locked cEVO;
        if (s.balance > 0) {
            uint256 claimed = s.amount - s.balance;
            uint256 pendingPerSecond = s.amount / s.duration;
            uint256 pending = s.startTime + s.duration > block.timestamp
              ? (block.timestamp - s.startTime) * pendingPerSecond
              : s.amount;
            if (claimed < pending) {
                s.balance -= (pending - claimed);
                totalPending += (pending - claimed);
            }
        }

        if (totalPending == 0) {
            return;
        }
        _burn(msg.sender, totalPending);
        if (ERC20Upgradeable(EVO).balanceOf(address(this)) >= totalPending) {
            ERC20Upgradeable(EVO).transfer(msg.sender, totalPending);
            return;
        }
        IMintable(EVO).mint(msg.sender, totalPending);
    }

    function pendingOf(address _address) public view returns(uint256) {
        uint256 totalPending = 0;
        // pending disbursements;
        for (uint256 i = 0; i < disbursements[_address].length; i++) {
            Disbursement storage d = disbursements[_address][i];
            uint256 claimed = d.amount - d.balance;
            uint256 pendingPerSecond = d.amount / d.duration;
            uint256 pending = (d.startTime + d.duration) > block.timestamp
              ? ((block.timestamp - d.startTime) * pendingPerSecond)
              : d.amount;
            if (claimed < pending) {
                totalPending += (pending - claimed);
            }
        }
        // pending original locked cEVO
        uint256 locked = _lockedOf[_address];
        if (locked > 0) {
            uint256 pendingPerSecond = locked / DEFAULT_VESTING_PERIOD;
            uint256 pending = 1681860918 + DEFAULT_VESTING_PERIOD > block.timestamp
              ? (block.timestamp - 1681860918) * pendingPerSecond
              : locked;
            totalPending += pending;
        }
        // pending migrated locked cEVO;
        Disbursement storage s = selfDisbursement[_address];
        if (s.balance > 0) {
            uint256 claimed = s.amount - s.balance;
            uint256 pendingPerSecond = s.amount / DEFAULT_VESTING_PERIOD;
            uint256 pending = 1681860918 + DEFAULT_VESTING_PERIOD > block.timestamp
              ? (block.timestamp - 1681860918) * pendingPerSecond
              : s.amount;
            if (claimed < pending) {
                totalPending += pending - claimed;
            }
        }
        return totalPending;
    }

    function lockedOf(address _address) public view returns(uint256) {
        return _lockedOf[_address] + selfDisbursement[_address].balance;
    }

    function transferAllDisbursements(address to) public {
        _transferAllDisbursements(msg.sender, to);
    }

    function adminTransferAllDisbursements(address from, address to) external onlyRole(ADMIN_ROLE) {
        _transferAllDisbursements(from, to);
    }

    function _transferAllDisbursements(address from, address to) internal {
        uint256 lockedFrom = _lockedOf[from];
        Disbursement memory d = selfDisbursement[from];
        require(lockedFrom > 0 || disbursements[from].length > 0 || d.balance > 0, "No balance");
        if (!_globalWhitelist.contains(from) || !_globalWhitelist.contains(to)) {
            require(
                transferTime[from] < block.timestamp
                && transferTime[to] < block.timestamp,
                "Cooldown period has not elapsed"
            );
            transferTime[from] = block.timestamp + 90 days;
            transferTime[to] = block.timestamp + 90 days;
        }
        _lockedOf[from] = 0;
        selfDisbursement[from] = Disbursement(0, 0, 0, 0);
        if (selfDisbursement[to].duration == 0) {
            selfDisbursement[to].startTime = 1681860918;
            selfDisbursement[to].duration = 365 days;
        }
        selfDisbursement[to].amount += d.amount + lockedFrom + _lockedOf[to];
        selfDisbursement[to].balance += d.balance + lockedFrom + _lockedOf[to];
        _lockedOf[to] = 0;
        for (uint256 i = 0; i < disbursements[from].length; i++) {
            disbursements[to].push(disbursements[from][i]);
        }

        delete disbursements[from];
        _whitelist[from].add(to);
        _transfer(from, to, balanceOf(from));
        _whitelist[from].remove(to);
    }

    function addGlobalWhitelist(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _globalWhitelist.add(to);
    }

    function addWhitelist(address from, address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _whitelist[from].add(to);
    }

    function resetTransferTimeOf(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        transferTime[_address] = 0;
    }

    function disbursementsOf(address _address) public view returns(Disbursement[] memory) {
        return disbursements[_address];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal whenNotPaused override onlyWhitelist(from, to) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
