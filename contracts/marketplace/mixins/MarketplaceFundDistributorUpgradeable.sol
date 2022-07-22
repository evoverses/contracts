// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../ERC20/interfaces/IERC20ExtendedUpgradeable.sol";
import "./MarketplaceFundDestinationsUpgradeable.sol";
import "./MarketplaceRoyaltiesUpgradeable.sol";
import "./MarketplaceFeeUpgradeable.sol";

abstract contract MarketplaceFundDistributorUpgradeable is
Initializable, MarketplaceRoyaltiesUpgradeable, MarketplaceFeeUpgradeable, MarketplaceFundDestinationsUpgradeable {
    using SafeERC20Upgradeable for IERC20ExtendedUpgradeable;

    function __MarketplaceFundDistributor_init(
        uint256 maxRoyaltyPercent,
        uint256 fee,
        uint256 feeBurned,
        uint256 feeReflected,
        address treasury,
        address bank
    ) internal onlyInitializing {
        __MarketplaceRoyalties_init(maxRoyaltyPercent);
        __MarketplaceFee_init(fee, feeBurned, feeReflected);
        __MarketplaceFundDestinations_init(treasury, bank);
    }

    function _distributeFunds(
        address contractAddress,
        uint256 tokenId,
        address bidTokenAddress,
        address seller,
        uint256 price
    ) internal returns (uint256, uint256, uint256) {
        uint256 marketFee = _getFee(price);
        uint256 marketFeeBurned = _getFeeBurned(price);
        uint256 marketFeeReflected = _getFeeReflected(price);

        (address royaltyReceiver, uint256 royalty) = _getRoyalty(contractAddress, tokenId, price);

        uint256 marketKept = marketFee - marketFeeBurned - marketFeeReflected;
        uint256 revenue = price - marketFee - royalty;

        IERC20ExtendedUpgradeable bidToken = IERC20ExtendedUpgradeable(bidTokenAddress);

        if (royalty > 0) {
            bidToken.safeTransfer(royaltyReceiver, royalty);
        }

        if (marketFeeBurned > 0) {
            bidToken.burn(marketFeeBurned);
        }

        if (marketFeeReflected > 0) {
            bidToken.safeTransfer(getMarketplaceBank(), marketFeeReflected);
        }

        bidToken.safeTransfer(getMarketplaceTreasury(), marketKept);
        bidToken.safeTransfer(seller, revenue);

        return (royalty, marketFee, revenue);
    }

    uint256[50] private __gap;
}
