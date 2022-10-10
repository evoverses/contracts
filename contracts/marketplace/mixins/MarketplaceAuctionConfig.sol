// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./MarketplaceConstants.sol";

abstract contract MarketplaceAuctionConfig is
Initializable, AccessControlEnumerableUpgradeable, MarketplaceConstants {
    uint256 internal extensionSeconds;
    uint256 internal _nexBidPercent;

    event MarketplaceAuctionConfigUpdated(
        uint256 nexBidPercentInBasisPoint, 
        uint256 extensionDuration
    );

    function __MarketplaceAuctionConfig_init() internal onlyInitializing {
        __AccessControlEnumerable_init();
        _nexBidPercent = 1000;
    }

    function getMarketplaceAuctionConfig() external view returns (uint256, uint256) {
        return (_nexBidPercent, extensionSeconds);
    }

    function updateMarketplaceAuctionConfig(uint256 nexBidPercent, uint256 _extensionSeconds) external onlyRole(UPDATER_ROLE) {
        require(
            0 <= nexBidPercent && nexBidPercent <= FEE_BASIS_POINTS,
            "MarketplaceAuctionConfigUpgradeable: Min increment must be >=0% and <= 100%"
        );
        
        _nexBidPercent = nexBidPercent;
        extensionSeconds = _extensionSeconds;
        emit MarketplaceAuctionConfigUpdated(nexBidPercent, extensionSeconds);
    }

    function _getNextBidAmount(uint256 currentBidAmount) internal view returns(uint256) {
        uint256 minIncrement = currentBidAmount * _nexBidPercent / FEE_BASIS_POINTS;
        return minIncrement == 0 ? currentBidAmount + 1 : currentBidAmount + minIncrement;
    }

    uint256[48] private __gap;
}