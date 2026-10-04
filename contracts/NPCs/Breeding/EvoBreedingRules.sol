// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice Betty/Harry game rules, with the agreed 500 EVO breeding base.
library EvoBreedingRules {
    struct Attributes {
        uint256 gender;
        uint256 rarity;
        uint256 primaryType;
        uint256 secondaryType;
        uint256 nature;
        uint256 size;
    }
    struct Stats {
        uint256 health;
        uint256 attack;
        uint256 defense;
        uint256 special;
        uint256 resistance;
        uint256 speed;
    }
    struct Adult {
        uint256 species;
        uint256 generation;
        uint256 totalBreeds;
        uint256 lastBreedTime;
        Attributes attributes;
        Stats stats;
    }
    struct Species {
        uint256 id;
        bool enabled;
        uint256 weight;
        uint256 malePercentage;
        uint256 primaryType;
        uint256 secondaryType;
    }

    function cost(Adult memory parent) internal pure returns (uint256) {
        uint256 breeds = parent.totalBreeds;
        if (parent.generation == 0 && breeds > 4) breeds = 4;
        return 500 ether * (2 ** parent.generation) * (breeds + 1);
    }

    function cooldown(uint256 generation) internal pure returns (uint256) {
        return generation < 6 ? (7 - generation) * 1 days : 1 days;
    }

    function compatible(Attributes memory a, Attributes memory b) internal pure returns (bool) {
        return a.gender != b.gender && (
            a.primaryType == b.primaryType ||
            (a.secondaryType > 0 && a.secondaryType == b.primaryType) ||
            (b.secondaryType > 0 && b.secondaryType == a.primaryType) ||
            (a.secondaryType > 0 && b.secondaryType > 0 && a.secondaryType == b.secondaryType)
        );
    }

    function validAdult(Adult calldata adult) internal pure returns (bool) {
        Attributes calldata a = adult.attributes;
        Stats calldata s = adult.stats;
        return a.gender <= 1 && a.rarity <= 2 && a.nature <= 20 && a.size <= 20 &&
            s.attack <= 50 && s.defense <= 50 && s.special <= 50 && s.resistance <= 50 && s.speed <= 50 &&
            (adult.generation == 0 || adult.totalBreeds <= 5);
    }

    /// @dev Preserves Harry's integer boundaries, configured order and disabled entries.
    /// These legacy quirks are documented rather than silently changing probabilities.
    function speciesRoll(Species[] memory pool, uint256 random) internal pure returns (uint256) {
        uint256[] memory thresholds = new uint256[](pool.length);
        uint256 total;
        for (uint256 i; i < pool.length; ++i) {
            if (!pool[i].enabled) continue;
            thresholds[i] = total;
            total += pool[i].weight;
        }
        uint256 outcome = random % total;
        for (uint256 i; i < pool.length; ++i) {
            if (outcome <= thresholds[i]) return pool[i].id;
        }
        return pool[pool.length - 1].id;
    }

    function childSpecies(Adult memory a, Adult memory b, Species[] memory pool, uint256 random)
        internal pure returns (uint256)
    {
        uint256 outcome = random % 1000;
        if (a.species == b.species && outcome <= 500) return a.species;
        if (outcome < 125) return a.species;
        if (outcome < 250) return b.species;
        return speciesRoll(pool, random);
    }

    function hatch(Adult memory a, Adult memory b, Species memory species, bool treated, uint256 random)
        internal pure returns (Attributes memory attributes, Stats memory stats)
    {
        uint256[9] memory chunks;
        for (uint256 i; i < chunks.length; ++i) {
            chunks[i] = random % 10_000;
            random /= 10_000;
        }
        uint256 modifier_ = ((100 + a.attributes.rarity * 50) + (100 + b.attributes.rarity * 50)) / 2;
        bool epic = chunks[0] % ((5000 / modifier_ * 100) / (treated ? 2 : 1)) < 1;
        bool chroma = chunks[0] % ((1000 / modifier_ * 100) / (treated ? 2 : 1)) < 1;
        uint256 natureOutcome = chunks[2] % 4;
        attributes = Attributes({
            gender: chunks[1] % 100 < species.malePercentage ? 1 : 0,
            rarity: epic ? 2 : (chroma ? 1 : 0),
            primaryType: species.primaryType,
            secondaryType: species.secondaryType,
            nature: natureOutcome == 0 ? a.attributes.nature : (natureOutcome == 1 ? b.attributes.nature : chunks[2] % 21),
            size: chunks[3] % 2 == 0 ? (a.attributes.size + b.attributes.size) / 2 : chunks[3] % 21
        });
        bool doubleGen0 = a.generation == 0 && b.generation == 0;
        stats = Stats(50,
            statRoll(a.stats.attack, b.stats.attack, doubleGen0, chunks[4]),
            statRoll(a.stats.defense, b.stats.defense, doubleGen0, chunks[5]),
            statRoll(a.stats.special, b.stats.special, doubleGen0, chunks[6]),
            statRoll(a.stats.resistance, b.stats.resistance, doubleGen0, chunks[7]),
            statRoll(a.stats.speed, b.stats.speed, doubleGen0, chunks[8])
        );
    }

    function statRoll(uint256 a, uint256 b, bool doubleGen0, uint256 random) internal pure returns (uint256) {
        if (doubleGen0) {
            uint256 modifier_ = a / 10 + b / 10;
            return random % (51 - modifier_) + modifier_;
        }
        uint256 outcome = random % 4;
        return outcome == 0 ? a : (outcome == 1 ? b : random % 51);
    }
}
