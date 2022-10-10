// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
* @title xEVO v1.1.0
* @author @DirtyCajunRice
*/
contract xEVOAvalanche is Initializable, PausableUpgradeable, AccessControlUpgradeable, ERC20Upgradeable {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");

    ERC20Upgradeable private EVO;

    EnumerableMapUpgradeable.AddressToUintMap private _finalBalance;
    EnumerableMapUpgradeable.AddressToUintMap private _finalEVOBalance;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC20_init("xEVO", "xEVO");
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(CONTRACT_ROLE, _msgSender());

        EVO = ERC20Upgradeable(0x42006Ab57701251B580bDFc24778C43c9ff589A1);
    }

    function deposit(uint256 amount) public whenNotPaused {
        uint256 totalGovernanceToken = EVO.balanceOf(address(this));

        uint256 totalShares = totalSupply();

        if (totalShares == 0 || totalGovernanceToken == 0) {
            _mint(_msgSender(), amount);
        } else {
            uint256 what = amount * totalShares / totalGovernanceToken;
            _mint(_msgSender(), what);
        }

        EVO.transferFrom(_msgSender(), address(this), amount);
    }

    function withdraw(uint256 amount) public whenNotPaused {
        uint256 totalShares = totalSupply();

        uint256 what = amount * EVO.balanceOf(address(this)) / totalShares;

        _burn(_msgSender(), amount);

        EVO.transfer(_msgSender(), what);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function adminMigrate(address[] memory users) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < users.length; i++) {
            uint256 totalShares = totalSupply();

            uint256 amount = balanceOf(users[i]);
            require(amount > 0, "User already migrated");

            uint256 what = amount * EVO.balanceOf(address(this)) / totalShares;

            _burn(users[i], amount);
            _finalBalance.set(users[i], amount);

            EVO.transfer(_msgSender(), what);
            _finalEVOBalance.set(users[i], what);
        }
    }

    function getFinalBalance(address user) public view returns (uint256 xevo, uint256 evo) {
        xevo = _finalBalance.get(user);
        evo = _finalEVOBalance.get(user);
    }

    function getAllFinalBalances() public view returns (address[] memory users, uint256[] memory xevo, uint256[] memory evo) {
        uint256 count = _finalBalance.length();

        users = new address[](count);
        xevo = new uint256[](count);
        evo = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            (users[i], xevo[i]) = _finalBalance.at(i);
        }

        for (uint256 i = 0; i < count; i++) {
            evo[i] = _finalEVOBalance.get(users[i]);
        }
    }

    function setBaseToken(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        EVO = ERC20Upgradeable(_address);
    }
}