// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../constants/ConstantsBase.sol";
import "../standard/ETHReceiver.sol";

/**
* @title Boba Faucet v1.0.0
* @author @DirtyCajunRice
*/
contract BobaFaucet is Initializable, ETHReceiver, PausableUpgradeable, AccessControlEnumerableUpgradeable, BaseConstants {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private _quenched;

    uint256 public dripSize;

    event DripSizeChanged(uint256 amount);
    event Dripped(address indexed to, uint256 amount);
    event Poured(address[] indexed to, uint256 amount);
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ETHReceiver_init();
        __Pausable_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        dripSize = 2 ether;
        emit DripSizeChanged(dripSize);
    }

    function drip(address payable to) public onlyRole(ADMIN_ROLE) {
        require(address(this).balance >= dripSize, "BobaFaucet::Insufficient reservoir remaining");
        bool added = _quenched.add(to);
        require(added, "BobaFaucet::Address already dripped");
        to.transfer(dripSize);
        emit Dripped(to, dripSize);
    }

    function pour(address[] memory to) public onlyRole(ADMIN_ROLE) {
        require(address(this).balance >= (dripSize * to.length), "BobaFaucet::Insufficient reservoir remaining");
        for (uint256 i = 0; i < to.length; i++) {
            bool added = _quenched.add(to[i]);
            require(added, "BobaFaucet::Address already dripped");
            payable(to[i]).transfer(dripSize);
        }
        emit Poured(to, dripSize);
    }

    function setDripSize(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, "BobaFaucet::Invalid amount");
        dripSize = amount;
        emit DripSizeChanged(dripSize);
    }

    function markQuenched(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _quenched.add(to);
    }

    function getReservoir() public view returns (uint256 reservoir, uint256 drips) {
        reservoir = address(this).balance;
        drips = reservoir / dripSize;
    }

    function getQuenched() external view returns (address[] memory) {
        return _quenched.values();
    }

    function isQuenched(address to) external view returns (bool) {
        return _quenched.contains(to);
    }

    function isThirsty(address to) external view returns (bool) {
        return !_quenched.contains(to);
    }

}