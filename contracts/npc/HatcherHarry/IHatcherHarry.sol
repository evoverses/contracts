// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../ERC721/interfaces/EvoStructs.sol";

interface IHatcherHarry is EvoStructs {
    function speciesRoll(uint256 rand) external returns(uint256 speciesId);
}