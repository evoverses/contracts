// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IEggAttributeStorage {
    function setAttribute(uint256 tokenId, uint256 attributeId, uint256 value) external;
    function batchSetAttribute(uint256 tokenId, uint256[] memory attributeIds, uint256[] memory values) external;
    function addToAttribute(uint256 tokenId, uint256 attributeId, uint256 value) external;
    function batchAddToAttribute(uint256 tokenId, uint256[] memory attributeIds, uint256[] memory values) external;
    function setAttributeString(uint256 attributeId, uint256 index, string memory value) external;
    function batchSetAttributeStrings(uint256 attributeId, uint256[] memory indices, string[] memory values) external;
}