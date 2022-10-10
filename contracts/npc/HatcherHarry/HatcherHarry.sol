// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../ERC721/interfaces/EvoStructs.sol";
import "../../utils/constants/NpcConstants.sol";
import "../../utils/boba/ITuringHelper.sol";
import "../../ERC721/interfaces/IEvo.sol";
import "../../ERC20/interfaces/IcEVO.sol";
import "../../ERC721/EvoEgg/IEvoEgg.sol";
import "../../ERC20/interfaces/IEVO.sol";
import "../../libraries/Numbers.sol";

/**
* @title Hatcher Harry v2.0.0
* @author @DirtyCajunRice
*/
contract HatcherHarry is Initializable, EvoStructs, PausableUpgradeable, AccessControlEnumerableUpgradeable,
NpcConstants {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToUintMap;
    using Numbers for uint256;

    ITuringHelper private _TuringHelper;
    IEvoEgg private _EvoEgg;
    IEvo private _Evo;
    IEVO private _EVO;
    IcEVO private _cEVO;

    address private treasury;

    uint256 public treatCost;

    // Base gene storage
    // speciesId -> param -> value
    mapping(uint256 => EnumerableMapUpgradeable.UintToUintMap) private _speciesBase;
    // set of configured species
    EnumerableSetUpgradeable.UintSet private _speciesIds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Pausable_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(CONTRACT_ROLE, _msgSender());

        _EVO = IEVO(0xc8849f32138de93F6097199C5721a9EfD91ceE01);
        _cEVO = IcEVO(address(0));

        _EvoEgg = IEvoEgg(0xa3b63C50F0518aAaCf5cF4720B773e1371D10eBF);
        _Evo = IEvo(0x3e9694a37846C864C67253af6F5d1F534ff3BF46);

        _TuringHelper = ITuringHelper(0x680e176b2bbdB2336063d0C82961BDB7a52CF13c);

        treasury = 0x2F52Abfca2074b99759b58345Bb984419D304243;

        treatCost = 250 ether;
    }

    function treat(uint256 tokenId) public {
        Egg memory egg = _EvoEgg.getEgg(tokenId);
        require(egg.treated == 0, "Egg already treated");
        _EVO.transferFrom(_msgSender(), treasury, treatCost);
        IEggAttributeStorage(address(_EvoEgg)).setAttribute(tokenId, 4, 1);
    }

    function hatch(uint256 tokenId) public {
        require(IERC721Upgradeable(address(_EvoEgg)).ownerOf(tokenId) == _msgSender(), "Not owner");

        Egg memory egg = _EvoEgg.getEgg(tokenId);
        require(block.timestamp + 3 days <= egg.createdAt, "Egg still incubating");

        uint256[] memory speciesIds;
        uint256[] memory minRarity;
        uint256 totalRarity;

        (speciesIds, minRarity, totalRarity) = rarityConfig();

        uint256 random = _TuringHelper.Random();
        uint256[] memory randomChunks = random.chunkUintX(10_000, 15);
        Evo memory evo = geneRoll(egg, randomChunks);
        _EvoEgg.hatch(tokenId);
        _Evo.mint(_msgSender(), evo);
    }

    function geneRoll(Egg memory egg, uint256[] memory randomChunks) internal view returns (Evo memory evo) {
        Evo memory p1 = _Evo.getEvo(egg.parent1);
        Evo memory p2 = _Evo.getEvo(egg.parent2);
        bool doubleGen0 = p1.generation == 0 && p2.generation == 0;

        evo = Evo({
            tokenId: egg.tokenId,
            species: egg.species,
            generation: egg.generation,
            experience: 0,
            breeds: Breeds(0, 0, 0),
            attributes: attributesRoll(egg, p1, p2, randomChunks),
            stats: statsRoll(p1.stats, p2.stats, doubleGen0, randomChunks),
            moves: Moves(0, 0, 0, 0)
        });
    }

    function attributesRoll(
        Egg memory egg,
        Evo memory p1,
        Evo memory p2,
        uint256[] memory randomChunks
    ) internal view returns(Attributes memory) {
        uint256 rarity = rarityRoll(p1.attributes.rarity, p2.attributes.rarity, egg.treated == 1, randomChunks[0]);
        uint256 gender = (randomChunks[1] % 100) < _speciesBase[egg.species].get(2) ? 1 : 0;
        uint256 primaryType = _speciesBase[egg.species].get(3);
        uint256 secondaryType = _speciesBase[egg.species].get(4);
        uint256 nature = natureRoll(p1.attributes.nature, p2.attributes.nature, randomChunks[2]);
        uint256 size = sizeRoll(p1.attributes.size, p2.attributes.size, randomChunks[3]);
        Attributes memory attributes = Attributes(gender, rarity, primaryType, secondaryType, nature, size);
        return attributes;
    }

    function rarityRoll(uint256 p1Rarity, uint256 p2Rarity, bool treated, uint256 rand) internal pure returns(uint256) {
        // Modifier Formula per parent, averaged: 100 + (Rarity * 50)
        uint256 parentModifier = ((100 + (p1Rarity * 50)) + (100 + (p2Rarity * 50))) / 2;
        // Rarity Formula modulus is rand modulus of (BaseModulus / ParentsModifier * 100) / 2 if treated
        bool epic = (rand % ((5000 / parentModifier * 100) / (treated ? 2 : 1))) < 1;
        bool chroma = (rand % ((1000 / parentModifier * 100) / (treated ? 2 : 1))) < 1;
        return epic ? 2 : (chroma ? 1 : 0);
    }

    function natureRoll(uint256 p1Nature, uint256 p2Nature, uint256 rand) internal pure returns(uint256) {
        uint256 outcome = rand % 4;
        if (outcome == 0) {
            return p1Nature;
        } else if (outcome == 1) {
            return p2Nature;
        } else {
            return rand % 21;
        }
    }

    function sizeRoll(uint256 p1Size, uint256 p2Size, uint256 rand) internal pure returns(uint256) {
        uint256 outcome = rand % 2;
        if (outcome == 0) {
            return (p1Size + p2Size) / 2;
        }
        return rand % 21;
    }

    function statsRoll(
        Stats memory p1Stats,
        Stats memory p2Stats,
        bool doubleGen0,
        uint256[] memory rand
    ) internal pure returns(Stats memory) {
         Stats memory stats = Stats({
            health: 50,
            attack: statRoll(p1Stats.attack, p2Stats.attack, doubleGen0, rand[4]),
            defense: statRoll(p1Stats.defense, p2Stats.defense, doubleGen0, rand[5]),
            special: statRoll(p1Stats.special, p2Stats.special, doubleGen0, rand[6]),
            resistance: statRoll(p1Stats.resistance, p2Stats.resistance, doubleGen0, rand[7]),
            speed: statRoll(p1Stats.speed, p2Stats.speed, doubleGen0, rand[8])
        });
        return stats;
    }

    function statRoll(uint256 p1Stat, uint256 p2Stat, bool doubleGen0, uint256 rand) internal pure returns(uint256) {
        if (doubleGen0) {
            uint256 parentModifier = (p1Stat / 10) + (p2Stat / 10);
            return (rand % (51 - parentModifier)) + parentModifier;
        } else {
            uint256 outcome = rand % 4;
            if (outcome == 0) {
                return p1Stat;
            } else if (outcome == 1) {
                return p2Stat;
            } else {
                return rand % 51;
            }
        }
    }

    function rarityConfig() public view returns (uint256[] memory, uint256[] memory, uint256) {
        uint256[] memory speciesIds = _speciesIds.values();
        uint256[] memory minRarity = new uint256[](speciesIds.length);
        uint256 totalRarity = 0;
        for (uint256 i = 0; i < speciesIds.length; i++) {
            if (_speciesBase[speciesIds[i]].get(0) == 0) {
                continue;
            }
            minRarity[i] = totalRarity;
            totalRarity += _speciesBase[speciesIds[i]].get(1);
        }
        return (speciesIds, minRarity, totalRarity);
    }

    function speciesRoll(uint256 rand) public view returns(uint256 speciesId) {
        uint256[] memory speciesIds;
        uint256[] memory minRarity;
        uint256 totalRarity;
        (speciesIds, minRarity, totalRarity) = rarityConfig();
        speciesId = speciesIds[speciesIds.length - 1];
        uint256 speciesResult = rand % totalRarity;
        for (uint256 i = 0; i < minRarity.length; i++) {
            if (speciesResult > minRarity[i]) {
                continue;
            }
            speciesId = speciesIds[i];
            break;
        }
    }

    function setBaseAttributes(uint256[] memory speciesIds, uint256[][] memory _baseAttributes) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < speciesIds.length; i++) {
            _speciesIds.add(speciesIds[i]);
            for (uint256 j = 0; j < _baseAttributes[i].length; j++) {
                _speciesBase[speciesIds[i]].set(j, _baseAttributes[i][j]);
            }
        }
    }

    function setTreatCost(uint256 cost) external onlyRole(ADMIN_ROLE) {
        treatCost = cost;
    }

    function setTreasury(address newTreasury) external onlyRole(ADMIN_ROLE) {
        treasury = newTreasury;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}