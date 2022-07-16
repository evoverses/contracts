// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract BaseConstants {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256[49] private __gap;
}