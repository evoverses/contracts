// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./MarketplaceConstantsUpgradeable.sol";

abstract contract MarketplaceFeeUpgradeable is Initializable, AccessControlUpgradeable, MarketplaceConstantsUpgradeable {
    uint256 private _fee;

    event MarketplaceFeeUpdated(uint256 indexed fee);

    function __MarketplaceFee_init(uint256 fee) internal onlyInitializing {
        require(fee <= MAX_FEE, "MarketplaceFeeUpgradeable: Fees > 10%");
        _fee = fee;
        __AccessControl_init();
    }

    function getMarketplaceFee() external view returns (uint256) {
        return _fee;
    }

    function setMarketplaceFee(uint256 fee) external onlyRole(UPDATER_ROLE) {
        require(fee <= MAX_FEE, "MarketplaceFeeUpgradeable: Fees > 10%");
        _fee = fee;
        emit MarketplaceFeeUpdated(fee);
    }

    function _getFee(uint256 price) internal view returns (uint256) {
        return price * _fee / FEE_BASIS_POINTS;
    }

    uint256[49] private __gap;
}
