// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface EvoStructs {
    struct Moves {
        uint256 move0;
        uint256 move1;
        uint256 move2;
        uint256 move3;
    }

    struct Breeds {
        uint256 total;
        uint256 remaining;
        uint256 lastBreedTime;
    }

    struct Stats {
        uint256 health;
        uint256 attack;
        uint256 defense;
        uint256 special;
        uint256 resistance;
        uint256 speed;
    }

    struct Attributes {
        uint256 gender;
        uint256 rarity;
        uint256 primaryType;
        uint256 secondaryType;
        uint256 nature;
        uint256 size;
    }

    struct Evo {
        uint256 tokenId;
        uint256 species;
        uint256 generation;
        uint256 experience;
        Attributes attributes;
        Stats stats;
        Breeds breeds;
        Moves moves;
    }

    struct PendingHatch {
        uint256[] ids;
        uint256 requestId;
        uint256[] words;
    }

    struct Egg {
        uint256 tokenId;
        uint256 species;
        uint256 generation;
        uint256 parent1;
        uint256 parent2;
        uint256 treated;
    }
}