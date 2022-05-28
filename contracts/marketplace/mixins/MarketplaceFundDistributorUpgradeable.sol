// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./MarketplaceRoyaltiesUpgradeable.sol";
import "./MarketplaceFeeUpgradeable.sol";
import "./MarketplaceFundDestinationsUpgradeable.sol";

abstract contract MarketplaceFundDistributorUpgradeable is
Initializable, MarketplaceRoyaltiesUpgradeable, MarketplaceFeeUpgradeable, MarketplaceFundDestinationsUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function __MarketplaceFundDistributor_init(
        uint256 maxRoyaltyPercent,
        uint256 fee,
        address treasury
    ) internal onlyInitializing {
        __MarketplaceRoyalties_init(maxRoyaltyPercent);
        __MarketplaceFee_init(fee);
        __MarketplaceFundDestinations_init(treasury);
    }

    function _distributeFunds(
        address contractAddress,
        uint256 tokenId,
        address bidTokenAddress,
        address seller,
        uint256 price
    ) internal returns (uint256, uint256, uint256) {
        uint256 marketFee = _getFee(price);

        (address royaltyReceiver, uint256 royalty) = _getRoyalty(contractAddress, tokenId, price);

        uint256 revenue = price - marketFee - royalty;

        IERC20Upgradeable bidToken = IERC20Upgradeable(bidTokenAddress);

        if (royalty > 0) {
            bidToken.safeTransfer(royaltyReceiver, royalty);
        }

        bidToken.safeTransfer(getMarketplaceTreasury(), marketFee);
        bidToken.safeTransfer(seller, revenue);

        return (royalty, marketFee, revenue);
    }

    uint256[50] private __gap;
}
