// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../utils/constants/TokenConstants.sol";
import "../interfaces/EvoStructs.sol";

/**
* @title Attribute Storage v1.0.0
* @author @DirtyCajunRice
*/
abstract contract AttributeStorage is Initializable, AccessControlEnumerableUpgradeable, TokenConstants, EvoStructs {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToUintMap;

    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");

    /// Evo Attribute storage
    // tokenId to attribute id for uint value of attribute
    mapping(uint256 => EnumerableMapUpgradeable.UintToUintMap) private _attributes;
    // attribute id to index for string value of attribute
    mapping (uint256 => mapping(uint256 => string)) private _attributeStrings;

    event EvoAttributeUpdated(uint256 indexed tokenId, uint256 attributeId, uint256 value);
    event EvoAttributesUpdated(uint256 indexed tokenId, uint256[] attributeId, uint256[] value);
    event EvoAttributeStringUpdated(uint256 indexed tokenId, uint256 attributeId, string value);
    event EvoAttributeStringsUpdated(uint256 indexed tokenId, uint256[] attributeIds, string[] value);

    // Upgradeable
    function __AttributeStorage_init() internal onlyInitializing {
        __AttributeStorage_init_unchained();
    }

    function __AttributeStorage_init_unchained() internal onlyInitializing {
        __AccessControlEnumerable_init();
    }

    function setAttribute(uint256 tokenId, uint256 attributeId, uint256 value) public onlyRole(CONTRACT_ROLE) {
        _attributes[tokenId].set(attributeId, value);
        emit EvoAttributeUpdated(tokenId, attributeId, value);
    }

    function batchSetAttribute(
        uint256 tokenId,
        uint256[] memory attributeIds,
        uint256[] memory values
    ) public onlyRole(CONTRACT_ROLE) {
        for (uint256 i = 0; i < attributeIds.length; i++) {
            _attributes[tokenId].set(attributeIds[i], values[i]);
        }
        emit EvoAttributesUpdated(tokenId, attributeIds, values);
    }

    function addToAttribute(uint256 tokenId, uint256 attributeId, uint256 value) public onlyRole(CONTRACT_ROLE) {
        uint256 currentValue = _attributes[tokenId].get(attributeId);
        uint256 updatedValue = currentValue + value;
        _attributes[tokenId].set(attributeId, updatedValue);
        emit EvoAttributeUpdated(tokenId, attributeId, updatedValue);
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
        emit EvoAttributesUpdated(tokenId, attributeIds, updatedValues);
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

    function _setEvoAttributes(Evo memory evo) internal {
        _attributes[evo.tokenId].set(0, evo.species);
        _attributes[evo.tokenId].set(1, evo.attributes.rarity);
        _attributes[evo.tokenId].set(2, evo.attributes.gender);
        _attributes[evo.tokenId].set(3, evo.generation);
        _attributes[evo.tokenId].set(4, evo.attributes.primaryType);
        _attributes[evo.tokenId].set(5, evo.attributes.secondaryType);
        _attributes[evo.tokenId].set(6, evo.breeds.total);
        _attributes[evo.tokenId].set(7, evo.experience);
        _attributes[evo.tokenId].set(8, evo.attributes.nature);
        _attributes[evo.tokenId].set(9, evo.stats.attack);
        _attributes[evo.tokenId].set(10, evo.stats.defense);
        _attributes[evo.tokenId].set(11, evo.stats.special);
        _attributes[evo.tokenId].set(12, evo.stats.resistance);
        _attributes[evo.tokenId].set(13, evo.stats.speed);
        _attributes[evo.tokenId].set(14, evo.attributes.size);
        _attributes[evo.tokenId].set(15, evo.breeds.lastBreedTime);
    }

    function getEvoAttributes(uint256 tokenId) internal view returns(Evo memory) {
        Moves memory moves = Moves(
            {
                move0: 0,
                move1: 0,
                move2: 0,
                move3: 0
            }
        );
        Attributes memory attributes = Attributes(
            {
                gender: _attributes[tokenId].get(2),
                rarity: _attributes[tokenId].get(1),
                primaryType: _attributes[tokenId].get(4),
                secondaryType: _attributes[tokenId].get(5),
                nature: _attributes[tokenId].get(8),
                size: _attributes[tokenId].get(14)
            }
        );
        Stats memory stats = Stats(
            {
                health: 50,
                attack: _attributes[tokenId].get(9),
                defense: _attributes[tokenId].get(10),
                special: _attributes[tokenId].get(11),
                resistance: _attributes[tokenId].get(12),
                speed: _attributes[tokenId].get(13)
            }
        );
        Breeds memory breeds = Breeds(
            {
                total: _attributes[tokenId].get(6),
                remaining: getRemainingSummons(tokenId),
                lastBreedTime: _attributes[tokenId].get(15)
            }
        );
        Evo memory evo = Evo(
            {
                tokenId: tokenId,
                species: _attributes[tokenId].get(0),
                generation: _attributes[tokenId].get(3),
                experience: _attributes[tokenId].get(7),
                attributes: attributes,
                stats: stats,
                breeds: breeds,
                moves: moves
            }
        );
        return evo;
    }

    function getRemainingSummons(uint256 tokenId) public view returns(uint256) {
        uint256 generation = _attributes[tokenId].get(3);
        if (generation == 0) {
            return 999;
        }
        uint256 total = _attributes[tokenId].get(6);
        if (total >= 5) {
            return 0;
        }
        return 5 - total;
    }

    function getAttribute(uint256 tokenId, uint256 attributeId) internal view returns(uint256) {
        return _attributes[tokenId].get(attributeId);
    }

    function getAttributeString(uint256 index, uint256 attributeId) internal view returns(string memory) {
        return _attributeStrings[index][attributeId];
    }

    uint256[47] private __gap;
}