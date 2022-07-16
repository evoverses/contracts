// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IEvoStructsUpgradeable {
    struct Summons {
        uint256 total;
        uint256 remaining;
    }

    struct BattleStats {
        uint256 health;
        uint256 attack;
        uint256 defense;
        uint256 special;
        uint256 resistance;
        uint256 speed;
    }

    struct Stats {
        uint256 gender;
        uint256 rarity;
        uint256 primaryType;
        uint256 secondaryType;
        uint256 nature;
    }

    struct Evo {
        uint256 tokenId;
        uint256 species;
        uint256 generation;
        uint256 experience;
        Stats stats;
        BattleStats battle;
        Summons summons;
    }

    struct PendingHatch {
        uint256[] ids;
        uint256 requestId;
        uint256[] words;
    }
}