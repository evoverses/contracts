// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./MarketplaceConstantsUpgradeable.sol";

abstract contract MarketplaceFundDestinationsUpgradeable is Initializable, AccessControlUpgradeable, MarketplaceConstantsUpgradeable {
    using AddressUpgradeable for address;

    address private _treasury;
    address private _bank;

    function __MarketplaceFundDestinations_init(address treasury) internal initializer {
        require(treasury.isContract(), "MarketplaceFundDestinationsUpgradeable: Address is not a contract");
        __AccessControl_init();
        _treasury = treasury;
    }

    function getMarketplaceTreasury() public view returns (address) {
        return _treasury;
    }

    function setMarketplaceTreasury(address treasury) external onlyRole(UPDATER_ROLE) {
        require(treasury.isContract(), "MarketplaceFundDestinationsUpgradeable: Address is not a contract");
        _treasury = treasury;
    }

    function getMarketplaceBank() public view returns (address) {
        return _treasury;
    }

    function setMarketplaceBank(address bank) external onlyRole(UPDATER_ROLE) {
        require(bank.isContract(), "MarketplaceFundDestinationsUpgradeable: Address is not a contract");
        _bank = bank;
    }

    uint256[48] private __gap;
}
