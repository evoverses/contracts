// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./extensions/ERC20BurnableUpgradeable.sol";
import "../utils/TokenConstants.sol";
import "./interfaces/IMintable.sol";

/**
* @title Vesting EVO v1.0.0
* @author @DirtyCajunRice
*/
contract vEVOUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable, ERC20PermitUpgradeable,
AccessControlUpgradeable, ERC20BurnableUpgradeable, TokenConstants {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint256 public GENESIS_TIMESTAMP;
    uint256 public VESTING_PERIOD_SECONDS;
    uint256 public OMEGA_TIMESTAMP;

    address private EVO;
    address private FARM;

    mapping(address => uint256) private _initialBalances;
    mapping(address => uint256) private _claimedBalances;

    mapping (address => EnumerableSetUpgradeable.AddressSet) private _whitelist;

    EnumerableSetUpgradeable.AddressSet private _globalWhitelist;

    event Claimed(address indexed from, uint256 amount);

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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("vEVO", "vEVO");
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init("vEVO");
        __ERC20Burnable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());

        GENESIS_TIMESTAMP = 1649190600;
        VESTING_PERIOD_SECONDS = 274 days;
        OMEGA_TIMESTAMP = GENESIS_TIMESTAMP + VESTING_PERIOD_SECONDS;

        EVO = 0x42006Ab57701251B580bDFc24778C43c9ff589A1;
    }

    function addInitialBalance(address _address, uint256 amount) public onlyRole(ADMIN_ROLE) {
        _initialBalances[_address] = amount;
    }

    function batchAddInitialBalance(address[] memory addresses, uint256[] memory amounts) public onlyRole(ADMIN_ROLE) {
        require(addresses.length == amounts.length, "Address list does not match amount list");
        for (uint256 i = 0; i < addresses.length; i++) {
            addInitialBalance(addresses[i], amounts[i]);
        }
    }

    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _claimedBalances[account] += _initialBalances[account] - amount;
        IMintable(EVO).mint(address(this), amount);
        _mint(account, amount);
    }

    function burn(uint256 amount) public virtual override(ERC20BurnableUpgradeable) {
        super.burn(amount);
        IMintable(EVO).burn(address(this), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual override(ERC20BurnableUpgradeable) {
        super.burnFrom(account, amount);
        IMintable(EVO).burn(address(this), amount);
    }

    function getWalletData(address _address) public view returns (uint256 total, uint256 claimed, uint256 pending) {
        total = _initialBalances[_address];
        claimed = _claimedBalances[_address];
        pending = _calculatePending(_address);
    }

    function _calculatePending(address _address) internal view returns (uint256) {
        uint256 userRatePerSecond = _initialBalances[_address] / VESTING_PERIOD_SECONDS;
        uint256 compareTime = block.timestamp;
        if (OMEGA_TIMESTAMP <= block.timestamp) {
            compareTime = OMEGA_TIMESTAMP;
        }
        uint256 elapsed = compareTime - GENESIS_TIMESTAMP;
        uint256 totalVested = userRatePerSecond * elapsed;
        return totalVested - _claimedBalances[_address];
    }

    function pendingOf(address _address) internal view returns (uint256) {
        return _calculatePending(_address);
    }

    function initialOf(address _address) internal view returns (uint256) {
        return _initialBalances[_address];
    }

    function claimedOf(address _address) internal view returns (uint256) {
        return _claimedBalances[_address];
    }

    function claimPending() external whenNotPaused {
        uint256 pending = _calculatePending(_msgSender());
        if (OMEGA_TIMESTAMP <= block.timestamp) {
            pending = _initialBalances[_msgSender()] - _claimedBalances[_msgSender()];
        }

        // Check balance of user to allow claiming less than total amount of claimable
        uint256 balance = balanceOf(_msgSender());
        require(balance >= 0, "No vEVO in wallet");
        if (balance < pending) {
            pending = balance;
        }

        _claimedBalances[_msgSender()] += pending;
        _burn(_msgSender(), pending);
        ERC20Upgradeable(EVO).transferFrom(address(this), _msgSender(), pending);

        emit Claimed(_msgSender(), pending);
    }

    function setVestingPeriod(uint256 _days) public onlyRole(ADMIN_ROLE) {
        VESTING_PERIOD_SECONDS = 1 days * _days;
        OMEGA_TIMESTAMP = GENESIS_TIMESTAMP + VESTING_PERIOD_SECONDS;
    }

    function setEvo(address _address) public onlyRole(ADMIN_ROLE) {
        EVO = _address;
    }

    function setFarm(address _address) public onlyRole(ADMIN_ROLE) {
        FARM = _address;
    }

    function addGlobalWhitelist(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _globalWhitelist.add(to);
    }

    function addWhitelist(address from, address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _whitelist[from].add(to);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal whenNotPaused override onlyWhitelist(from, to) {
        super._beforeTokenTransfer(from, to, amount);
    }
}