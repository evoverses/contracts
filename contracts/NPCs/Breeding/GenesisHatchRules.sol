// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {EvoBreedingRules as Rules} from "./EvoBreedingRules.sol";

/// @notice Genesis Harry rules, preserving chunk order, integer/modulo boundaries and species order.
library GenesisHatchRules {
    function hatch(Rules.Species[] memory pool, bool treated, uint256 word)
        internal pure returns (uint256 speciesId, Rules.Attributes memory attributes, Rules.Stats memory stats)
    {
        uint256[9] memory chunks;
        for (uint256 i; i < chunks.length; ++i) { chunks[i] = word % 10_000; word /= 10_000; }
        speciesId = Rules.speciesRoll(pool, chunks[0]);
        Rules.Species memory species;
        for (uint256 i; i < pool.length; ++i) if (pool[i].id == speciesId) { species = pool[i]; break; }
        bool epic = chunks[1] % (treated ? 3000 : 5000) < (treated ? 9 : 1);
        bool chroma = chunks[1] % (treated ? 3000 : 1000) < (treated ? 45 : 1);
        attributes = Rules.Attributes(chunks[2] % 100 < species.malePercentage ? 1 : 0,
            epic ? 2 : (chroma ? 1 : 0), species.primaryType, species.secondaryType, chunks[3] % 21, 10);
        stats = Rules.Stats(50, chunks[4] % 51, chunks[5] % 51, chunks[6] % 51, chunks[7] % 51, chunks[8] % 51);
    }
}
