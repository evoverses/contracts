// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../ERC20/IEvoToken.sol";

interface IMasterInvestor {
    function withdrawForClaim(uint256 _pid, uint256 _amount, address _address) external;
}

/**
* @title vEVO Vesting v1.2.1
* @author @DirtyCajunRice
*/
contract vEVOVestingUpgradeable is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public constant GENESIS_TIMESTAMP = 1649190600;
    uint256 private constant _ORIG_VPS = 213 days;
    uint256 private constant _ORIG_OT = GENESIS_TIMESTAMP + _ORIG_VPS;

    IEvoToken private constant _ORIG_EVO = IEvoToken(0xD6e76742962379e234E9Fd4E73768cEF779f38B5);
    IEvoToken public constant vEVO = IEvoToken(0xEb76Ef5d121f31c2cb59e50A4fa5475042C84e34);

    address private constant _BURN_ADDRESS = payable(0x0000000000000000000000000000000000000001);

    uint256 private _claimed;
    uint256 private _total;

    struct User {
        uint256 total;
        uint256 claimed;
    }

    mapping (address => User) private users;

    EnumerableSetUpgradeable.AddressSet private _wallets;

    uint256 public VESTING_PERIOD_SECONDS;
    uint256 public OMEGA_TIMESTAMP;

    IEvoToken public EVO;

    address public MasterInvestor;

    event Claimed(address indexed from, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());

        _claimed = 0;
        _total = 0;
    }

    function addWallet(address _address, uint256 amount) public onlyRole(ADMIN_ROLE) {
        require(!_wallets.contains(_address), "Wallet already entered");

        users[_address].total = amount;
        users[_address].claimed = 0;

        _wallets.add(_address);

        _total += amount;
    }

    function bulkAddWallets(address[] memory addresses, uint256[] memory amounts) public onlyRole(ADMIN_ROLE) {
        require(addresses.length == amounts.length, "Address list does not match amount list");
        for (uint256 i = 0; i < addresses.length; i++) {
            addWallet(addresses[i], amounts[i]);
        }
    }

    function modifyWallet(address _address, uint256 amount) public onlyRole(ADMIN_ROLE) {
        require(_wallets.contains(_address), "Wallet does not exist");
        users[_address].total = amount;
    }

    function removeWallet(address _address) public onlyRole(ADMIN_ROLE) {
        require(_wallets.contains(_address), "Wallet does not exist");

        users[_address].total = 0;
        users[_address].claimed = 0;

        _wallets.remove(_address);
    }

    function getWalletData(address _address) public view returns (uint256 total, uint256 claimed, uint256 pending) {
        if (!_wallets.contains(_address)) {
            return (0, 0, 0);
        }
        total = users[_address].total;
        claimed = users[_address].claimed;
        pending = _calculatePending(_address);
    }

    function _calculatePending(address _address) internal view returns (uint256) {
        uint256 userRatePerSecond = users[_address].total / VESTING_PERIOD_SECONDS;
        uint256 compareTime = block.timestamp;
        if (OMEGA_TIMESTAMP <= block.timestamp) {
            compareTime = OMEGA_TIMESTAMP;
        }
        uint256 elapsed = compareTime - GENESIS_TIMESTAMP;
        uint256 totalVested = userRatePerSecond * elapsed;
        return totalVested - users[_address].claimed;
    }

    function claimVested() public whenNotPaused nonReentrant {
        require(_wallets.contains(_msgSender()), "Wallet does not exist");
        uint256 pending = _calculatePending(_msgSender());
        if (OMEGA_TIMESTAMP <= block.timestamp) {
            pending = users[_msgSender()].total - users[_msgSender()].claimed;
        }

        // Check balance of user to allow claiming less than total amount of claimable
        uint256 balance = vEVO.balanceOf(_msgSender());
        require(balance >= 0, "No vEVO in wallet");
        if (balance < pending) {
            pending = balance;
        }

        require(vEVO.allowance(_msgSender(), address(this)) >= pending, "Pending balance exceeds approved amount");

        users[_msgSender()].claimed += pending;
        _claimed += pending;

        vEVO.transferFrom(_msgSender(), _BURN_ADDRESS, pending);
        EVO.mint(_msgSender(), pending);
        emit Claimed(_msgSender(), pending);
    }

    function claimVestedFromInvestor() public whenNotPaused nonReentrant {
        require(_wallets.contains(_msgSender()), "Wallet does not exist");
        uint256 pending = _calculatePending(_msgSender());
        if (OMEGA_TIMESTAMP <= block.timestamp) {
            pending = users[_msgSender()].total - users[_msgSender()].claimed;
        }
        require(vEVO.allowance(_msgSender(), address(this)) >= pending, "Pending balance exceeds approved amount");

        IMasterInvestor mi = IMasterInvestor(MasterInvestor);
        mi.withdrawForClaim(1, pending, _msgSender());

        users[_msgSender()].claimed += pending;
        _claimed += pending;

        vEVO.transferFrom(_msgSender(), _BURN_ADDRESS, pending);
        EVO.mint(_msgSender(), pending);
        emit Claimed(_msgSender(), pending);
    }

    function totalPending() public view returns(uint256) {
        uint256 ratePerSecond = _total / VESTING_PERIOD_SECONDS;
        uint256 compareTime = block.timestamp;
        if (OMEGA_TIMESTAMP <= block.timestamp) {
            compareTime = OMEGA_TIMESTAMP;
        }
        uint256 elapsed = compareTime - GENESIS_TIMESTAMP;
        uint256 totalVested = ratePerSecond * elapsed;
        return totalVested - _claimed;
    }

    function setVestingPeriod(uint256 _days) public onlyRole(ADMIN_ROLE) {
        VESTING_PERIOD_SECONDS = 1 days * _days;
        OMEGA_TIMESTAMP = GENESIS_TIMESTAMP + VESTING_PERIOD_SECONDS;
    }
    function setEvo() public onlyRole(ADMIN_ROLE) {
        EVO = IEvoToken(0x5b747e23a9E4c509dd06fbd2c0e3cB8B846e398F);
    }
    function setMasterInvestor(address _address) public onlyRole(ADMIN_ROLE) {
        MasterInvestor = _address;
    }
}