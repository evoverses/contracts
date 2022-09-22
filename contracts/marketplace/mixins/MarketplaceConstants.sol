// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract MarketplaceConstants {
    enum FeeType {
        Burned,
        Shared,
        Marketing,
        Dev,
        Founders
    }

    uint256 internal constant FEE_BASIS_POINTS = 10000;
    uint256 internal constant MAX_FEE = 1000;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    uint256[46] private __gap;
}