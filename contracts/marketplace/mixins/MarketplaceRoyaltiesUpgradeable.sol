// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./MarketplaceConstantsUpgradeable.sol";

abstract contract MarketplaceRoyaltiesUpgradeable is Initializable, AccessControlUpgradeable, MarketplaceConstantsUpgradeable {

    struct Recipient {
        address _address;
        uint256 amount;
    }

    uint256 private _maxRoyaltyPercent;

    mapping(address => mapping(uint256 => Recipient)) internal royalties;

    event MarketplaceRoyaltiesUpdated(
        uint256 indexed maxRoyaltyPercent
    );

    function __MarketplaceRoyalties_init(uint256 maxRoyaltyPercent) internal onlyInitializing {
        require(maxRoyaltyPercent <= MAX_FEE, "MarketplaceRoyaltiesUpgradeable: Royalty > 10%");
        _maxRoyaltyPercent = maxRoyaltyPercent;
        __AccessControl_init();
    }

    function getMarketplaceRoyaltyPercent() external view returns (uint256) {
        return _maxRoyaltyPercent;
    }

    function setMarketplaceRoyaltyPercent(uint256 maxRoyaltyPercent) external onlyRole(UPDATER_ROLE) {
        require(maxRoyaltyPercent <= MAX_FEE, "MarketplaceRoyaltiesUpgradeable: Royalty > 10%");

        _maxRoyaltyPercent = maxRoyaltyPercent;

        emit MarketplaceRoyaltiesUpdated(maxRoyaltyPercent);
    }

    function setRoyaltyFor(address to, address contractAddress, uint256 tokenId, uint256 royaltyPercent) internal {
        require(
            royalties[contractAddress][tokenId]._address == address(0),
            "MarketplaceRoyaltiesUpgradeable: Royalty already set"
        );
        require(
            royaltyPercent > 0 && royaltyPercent <= _maxRoyaltyPercent,
            "MarketplaceRoyaltiesUpgradeable: Invalid royalty"
        );
        royalties[contractAddress][tokenId] = Recipient(
            {
                _address: to,
                amount: royaltyPercent
            }
        );
    }

    function _getRoyalty(address contractAddress, uint256 tokenId, uint256 price) internal view returns (address, uint256) {
        Recipient storage royalty = royalties[contractAddress][tokenId];
        if (royalty._address == address(0)) {
            return (address(0), 0);
        }

        return (royalty._address, price * royalty.amount / FEE_BASIS_POINTS);
    }

    uint256[48] private __gap;
}
