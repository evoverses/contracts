// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./MarketplaceConstants.sol";

abstract contract MarketplaceFundDestinations is Initializable, AccessControlEnumerableUpgradeable, MarketplaceConstants {
    address private _treasury;
    mapping (FeeType => address) private _feeDestinations;

    function __MarketplaceFundDestinations_init() internal initializer {
        __AccessControlEnumerable_init();
    }

    function getMarketplaceTreasury() public view returns (address) {
        return _treasury;
    }

    function setMarketplaceTreasury(address treasury) external onlyRole(UPDATER_ROLE) {
        _treasury = treasury;
    }

    function getMarketplaceFeeDestination(FeeType feeType) public view returns (address) {
        return _feeDestinations[feeType];
    }

    function setMarketplaceFeeDestination(address destination, FeeType feeType) external onlyRole(UPDATER_ROLE) {
        _feeDestinations[feeType] = destination;
    }

    function _getSendFeeDestinations() internal view returns(address[4] memory) {
        address[4] memory feeDestinations = [
            _feeDestinations[FeeType.Shared],
            _feeDestinations[FeeType.Founders],
            _feeDestinations[FeeType.Marketing],
            _feeDestinations[FeeType.Dev]
        ];
        return feeDestinations;
    }

    uint256[48] private __gap;
}
