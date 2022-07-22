// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./MarketplaceConstantsUpgradeable.sol";

abstract contract MarketplaceBidTokensUpgradeable is
Initializable, AccessControlEnumerableUpgradeable, MarketplaceConstantsUpgradeable {
    using AddressUpgradeable for address;

    mapping(address => address) internal bidToken;

    event MarketplaceBidTokenConfigured(address indexed contractAddress, address indexed bidTokenAddress);

    function __MarketplaceBidTokens_init() internal onlyInitializing {
        __AccessControlEnumerable_init();
    }

    function setMarketplaceBidToken(address contractAddress, address bidTokenAddress) external onlyRole(UPDATER_ROLE) {
        require(contractAddress.isContract(), "MarketplaceBidTokensUpgradeable: Not a contract");
        require(bidTokenAddress.isContract(), "MarketplaceBidTokensUpgradeable: Not a contract");

        bidToken[contractAddress] = bidTokenAddress;
    }

    function getMarketplaceBidTokenOf(address contractAddress) external view returns(address) {
        return bidToken[contractAddress];
    }

    function removeMarketplaceBidToken(address contractAddress) external onlyRole(UPDATER_ROLE) {
        delete bidToken[contractAddress];
    }

    function isValidBidToken(address contractAddress, address bidTokenAddress) internal view returns(bool) {
        return bidToken[contractAddress] == bidTokenAddress;
    }

    uint256[49] private __gap;
}
