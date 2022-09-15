// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../utils/constants/NpcConstants.sol";

/**
* @title Accountant Aurora v1.0.0
* @author @DirtyCajunRice
*/
contract AccountantAurora is Initializable, AccessControlEnumerableUpgradeable, NpcConstants {
    address public Treasury;
    address public Director;
    address public Founders;
    address public Marketing;
    address public Development;

}