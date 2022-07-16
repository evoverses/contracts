// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IEvoEggUpgradeable {
    function hatch(address spender, uint256[] memory tokenIds) external;
    function checkTreated(uint256[] memory tokenIds) external view returns(bool[] memory);
}