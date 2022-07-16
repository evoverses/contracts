// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ConstantsBase.sol";

abstract contract NpcConstants is BaseConstants {
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");

    uint256[49] private __gap;
}