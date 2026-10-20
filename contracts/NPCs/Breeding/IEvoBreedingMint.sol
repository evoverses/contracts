// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
interface IEvoBreedingMint is IERC721 {
    function mintNew(address to) external;
    function requestMetadataUpdate(uint256 tokenId) external;
}
