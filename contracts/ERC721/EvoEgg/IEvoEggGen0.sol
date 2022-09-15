// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/EvoStructs.sol";
import "./IEggAttributeStorage.sol";

interface IEvoEggGen0 is EvoStructs {
    function incubate(address to, Egg memory egg) external;
    function hatch(address spender, uint256[] memory tokenIds) external;
    function checkTreated(uint256[] memory tokenIds) external view returns(bool[] memory);
    function getEgg(uint256 tokenId) external view returns(Egg memory egg);
}