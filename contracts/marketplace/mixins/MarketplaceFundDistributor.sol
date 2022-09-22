// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../ERC20/interfaces/IERC20ExtendedUpgradeable.sol";
import "./MarketplaceFundDestinations.sol";
import "./MarketplaceRoyalties.sol";
import "./MarketplaceConstants.sol";
import "./MarketplaceFee.sol";

abstract contract MarketplaceFundDistributor is Initializable, MarketplaceRoyalties, MarketplaceFee, MarketplaceFundDestinations {
    using SafeERC20Upgradeable for IERC20ExtendedUpgradeable;

    function __MarketplaceFundDistributor_init() internal onlyInitializing {
        __MarketplaceRoyalties_init();
        __MarketplaceFee_init();
        __MarketplaceFundDestinations_init();
    }

    function _distributeFunds(
        address contractAddress,
        uint256 tokenId,
        address bidTokenAddress,
        address seller,
        uint256 price
    ) internal returns (uint256, uint256, uint256) {
        uint256 marketFee = _getFee(price);
        uint256 feeLeft = marketFee;

        IERC20ExtendedUpgradeable bidToken = IERC20ExtendedUpgradeable(bidTokenAddress);

        feeLeft -= _distributeBurned(marketFee, bidToken);
        feeLeft -= _distributeShares(marketFee, bidToken);

        if (feeLeft > 0) {
            bidToken.safeTransfer(getMarketplaceTreasury(), feeLeft);
        }

        uint256 royalty = _distributeRoyalty(contractAddress, bidTokenAddress, tokenId, price);

        uint256 revenue = price - marketFee - royalty;

        bidToken.safeTransfer(seller, revenue);

        return (royalty, marketFee, revenue);
    }

    function _distributeBurned(uint256 marketFee, IERC20ExtendedUpgradeable bidToken) private returns(uint256) {
        uint256 feeBurned = _getFeeWeight(marketFee, MarketplaceConstants.FeeType.Burned);
        if (feeBurned > 0) {
            bidToken.burn(feeBurned);
        }
        return feeBurned;
    }

    function _distributeShares(uint256 marketFee, IERC20ExtendedUpgradeable bidToken) private returns(uint256) {
        uint256[4] memory feeAmounts = _getSendFeeWeights(marketFee);
        address[4] memory feeDestinations = _getSendFeeDestinations();
        uint256 sent = 0;
        for (uint256 i = 0; i < feeAmounts.length; i++) {
            if (feeAmounts[i] > 0) {
                bidToken.safeTransfer(feeDestinations[i], feeAmounts[i]);
                sent += feeAmounts[i];
            }
        }
        return sent;
    }

    function _distributeRoyalty(address _contract, address bidToken, uint256 tokenId, uint256 price) private returns(uint256) {
        (address royaltyReceiver, uint256 royalty) = _getRoyalty(_contract, tokenId, price);
        if (royalty > 0) {
            IERC20ExtendedUpgradeable(bidToken).safeTransfer(royaltyReceiver, royalty);
        }
        return royalty;
    }

    uint256[50] private __gap;
}
