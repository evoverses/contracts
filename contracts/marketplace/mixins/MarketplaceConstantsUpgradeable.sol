// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract MarketplaceConstantsUpgradeable {
    uint256 internal constant FEE_BASIS_POINTS = 10000;
    uint256 internal constant MAX_FEE = 1000;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    uint256[50] private __gap;
}