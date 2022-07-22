// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./MarketplaceConstantsUpgradeable.sol";

abstract contract MarketplaceFeeUpgradeable is
Initializable, AccessControlEnumerableUpgradeable, MarketplaceConstantsUpgradeable {
    uint256 private _fee;

    uint256 private _feeBurned;
    uint256 private _feeReflected;
    uint256 private _placeholder1;
    uint256 private _placeholder2;

    event MarketplaceFeeUpdated(uint256 indexed fee);
    event MarketplaceFeeBurnedUpdated(uint256 indexed feeBurned);
    event MarketplaceFeeReflectedUpdated(uint256 indexed feeReflected);

    function __MarketplaceFee_init(uint256 fee, uint256 feeBurned, uint256 feeReflected) internal onlyInitializing {
        require(fee <= MAX_FEE, "MarketplaceFeeUpgradeable: Fees > 10%");
        _fee = fee;
        _feeBurned = feeBurned;
        _feeReflected = feeReflected;
        __AccessControlEnumerable_init();
    }

    function getMarketplaceFee() external view returns (uint256) {
        return _fee;
    }

    function getMarketplaceFeeBurned() external view returns (uint256) {
        return _feeBurned;
    }

    function getMarketplaceFeeReflected() external view returns (uint256) {
        return _feeReflected;
    }

    function getMarketplaceFees() external view returns (uint256, uint256, uint256) {
        return (_fee, _feeBurned, _feeReflected);
    }

    function setMarketplaceFee(uint256 fee) external onlyRole(UPDATER_ROLE) {
        require(fee <= MAX_FEE, "MarketplaceFeeUpgradeable: Fees > 10%");
        _fee = fee;
        emit MarketplaceFeeUpdated(fee);
    }

    function setMarketplaceFeeBurned(uint256 feeBurned) external onlyRole(UPDATER_ROLE) {
        require(feeBurned <= MAX_FEE, "MarketplaceFeeUpgradeable: Fees > 10%");
        _feeBurned = feeBurned;
        emit MarketplaceFeeBurnedUpdated(feeBurned);
    }

    function setMarketplaceFeeReflected(uint256 feeReflected) external onlyRole(UPDATER_ROLE) {
        require(feeReflected <= MAX_FEE, "MarketplaceFeeUpgradeable: Fees > 10%");
        _feeReflected = feeReflected;
        emit MarketplaceFeeReflectedUpdated(feeReflected);
    }

    function _getFee(uint256 price) internal view returns (uint256) {
        return price * _fee / FEE_BASIS_POINTS;
    }

    function _getFeeBurned(uint256 price) internal view returns (uint256) {
        return price * _feeBurned / FEE_BASIS_POINTS;
    }

    function _getFeeReflected(uint256 price) internal view returns (uint256) {
        return price * _feeReflected / FEE_BASIS_POINTS;
    }

    uint256[45] private __gap;
}
