// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../utils/constants/TokenConstants.sol";
import "../interfaces/EvoStructs.sol";

/**
* @title Egg Attribute Storage v1.0.0
* @author @DirtyCajunRice
*/
abstract contract EggAttributeStorage is Initializable, AccessControlEnumerableUpgradeable, EvoStructs, TokenConstants {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToUintMap;

    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");

    /// Evo Attribute storage
    // tokenId to attribute id for uint value of attribute
    mapping(uint256 => EnumerableMapUpgradeable.UintToUintMap) private _attributes;
    // attribute id to index for string value of attribute
    mapping (uint256 => mapping(uint256 => string)) private _attributeStrings;

    event EggAttributeUpdated(uint256 indexed tokenId, uint256 attributeId, uint256 value);
    event EggAttributesUpdated(uint256 indexed tokenId, uint256[] attributeId, uint256[] value);
    event EggAttributeStringUpdated(uint256 indexed tokenId, uint256 attributeId, string value);
    event EggAttributeStringsUpdated(uint256 indexed tokenId, uint256[] attributeIds, string[] value);

    // Upgradeable
    function __EggAttributeStorage_init() internal onlyInitializing {
        __AccessControlEnumerable_init();
    }

    function setAttribute(uint256 tokenId, uint256 attributeId, uint256 value) public onlyRole(CONTRACT_ROLE) {
        _attributes[tokenId].set(attributeId, value);
        emit EggAttributeUpdated(tokenId, attributeId, value);
    }

    function batchSetAttribute(
        uint256 tokenId,
        uint256[] memory attributeIds,
        uint256[] memory values
    ) public onlyRole(CONTRACT_ROLE) {
        for (uint256 i = 0; i < attributeIds.length; i++) {
            _attributes[tokenId].set(attributeIds[i], values[i]);
        }
        emit EggAttributesUpdated(tokenId, attributeIds, values);
    }

    function addToAttribute(uint256 tokenId, uint256 attributeId, uint256 value) public onlyRole(CONTRACT_ROLE) {
        uint256 currentValue = _attributes[tokenId].get(attributeId);
        uint256 updatedValue = currentValue + value;
        _attributes[tokenId].set(attributeId, updatedValue);
        emit EggAttributeUpdated(tokenId, attributeId, updatedValue);
    }

    function batchAddToAttribute(
        uint256 tokenId,
        uint256[] memory attributeIds,
        uint256[] memory values
    ) public onlyRole(CONTRACT_ROLE) {
        uint256[] memory updatedValues = new uint256[](values.length);
        for (uint256 i = 0; i < attributeIds.length; i++) {
            uint256 currentValue = _attributes[tokenId].get(attributeIds[i]);
            uint256 updatedValue = currentValue + values[i];
            _attributes[tokenId].set(attributeIds[i], updatedValue);
            updatedValues[i] = updatedValue;
        }
        emit EggAttributesUpdated(tokenId, attributeIds, updatedValues);
    }

    function setAttributeString(uint256 attributeId, uint256 index, string memory value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _attributeStrings[attributeId][index] = value;
    }

    function batchSetAttributeStrings(
        uint256 attributeId,
        uint256[] memory indices,
        string[] memory values
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < indices.length; i++) {
            _attributeStrings[attributeId][indices[i]] = values[i];
        }
    }

    function _setEggAttributes(Egg memory egg) internal onlyRole(MINTER_ROLE) {
        _attributes[egg.tokenId].set(0, egg.species);
        _attributes[egg.tokenId].set(1, egg.generation);
        _attributes[egg.tokenId].set(2, egg.parent1);
        _attributes[egg.tokenId].set(3, egg.parent2);
        _attributes[egg.tokenId].set(4, egg.treated);
        _attributes[egg.tokenId].set(5, egg.createdAt);
    }

    function _getEggAttributes(uint256 tokenId) internal view returns (Egg memory) {
        return EvoStructs.Egg({
            tokenId: tokenId,
            species: _attributes[tokenId].get(0),
            generation: _attributes[tokenId].get(1),
            parent1: _attributes[tokenId].get(2),
            parent2: _attributes[tokenId].get(3),
            treated: _attributes[tokenId].get(4),
            createdAt: _attributes[tokenId].get(5)
        });
    }

    function getAttribute(uint256 tokenId, uint256 attributeId) internal view returns(uint256) {
        return _attributes[tokenId].get(attributeId);
    }

    function getAttributeString(uint256 index, uint256 attributeId) internal view returns(string memory) {
        return _attributeStrings[index][attributeId];
    }

    uint256[47] private __gap;
}