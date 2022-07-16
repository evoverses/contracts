// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ConstantsBase.sol";

abstract contract TokenConstants is BaseConstants {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256[49] private __gap;
}