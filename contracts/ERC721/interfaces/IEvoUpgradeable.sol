// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IEvoStructsUpgradeable.sol";

interface IEvoUpgradeable is IEvoStructsUpgradeable {
    function mint(address _address, Evo memory evo) external;
    function batchMint(address _address, Evo[] memory evos) external;
    function getPendingHatchFor(address _address) external view returns(PendingHatch memory);
    function clearPendingHatch(address _address) external;
}