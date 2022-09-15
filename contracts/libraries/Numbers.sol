// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Numbers {
    function chunkUintEq(uint256 number, uint256 count) internal pure returns(uint256[] memory chunks) {
        // uint256 has 77 digits, so to ensure chunks are equal, we will remove remainder
        uint256 numChunks = 77 / count;
        uint256 mod = numChunks > 1 ? 10**(numChunks-1) : 1;
        chunks = new uint256[](numChunks);
        uint256 n = number;
        for (uint256 i = 0; i < numChunks; i++) {
            uint256 chunk = uint256(n % mod);
            n = n / mod;
            chunks[i] = chunk;
        }
    }
    function chunkUintX(uint256 number, uint256 mod, uint256 count) internal pure returns(uint256[] memory chunks) {
        chunks = new uint256[](count);
        uint256 n = number;
        for (uint256 i = 0; i < count; i++) {
            uint256 chunk = uint256(n % mod);
            n = n / mod;
            chunks[i] = chunk;
        }
    }
}