// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/EvoStructs.sol";
import "./IEggAttributeStorage.sol";

interface IEvoEgg is EvoStructs {
    function incubate(address to, Egg memory egg) external;
    function hatch(uint256 tokenId) external;
    function getEgg(uint256 tokenId) external view returns(Egg memory egg);
}