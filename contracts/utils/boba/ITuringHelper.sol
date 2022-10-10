// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITuringHelper {
    function TuringTx(string memory _url, bytes memory _payload) external returns (bytes memory);
    function APICall(string memory _url, bytes memory _payload) external returns (bytes memory);
    function Random() external returns (uint256);

    event OffchainResponse(uint256 version, bytes responseData);
    event OnChainRandom(uint256 version, uint256 random);
}