// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "./EvoStructs.sol";

interface IEvo is IERC721Upgradeable, EvoStructs {
    function mint(address _address, Evo memory evo) external;
    function batchMint(address _address, Evo[] memory evos) external;
    function getPendingHatchFor(address _address) external view returns(PendingHatch memory);
    function clearPendingHatch(address _address) external;
    function setAttribute(uint256 tokenId, uint256 attributeId, uint256 value) external;
    function batchSetAttribute(uint256 tokenId, uint256[] memory attributeIds, uint256[] memory values) external;
    function addToAttribute(uint256 tokenId, uint256 attributeId, uint256 value) external;
    function batchAddToAttribute(uint256 tokenId, uint256[] memory attributeIds, uint256[] memory values) external;
    function tokensOfOwner(address owner) external view returns(uint256[] memory);
    function batchTokenUriJson(uint256[] memory tokenIds) external view returns(string[] memory);
    function getEvo(uint256 tokenId) external view returns(Evo memory);
    function getAttribute(uint256 tokenId, uint256 attributeId) external view returns(uint256);
}