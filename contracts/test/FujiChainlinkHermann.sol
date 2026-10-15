// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {Hatcher_Hermann} from "../NPCs/Hatcher_Hermann/Hatcher_Hermann.sol";

/// @notice Accelerated incubation is restricted to Fuji and disposable local test chains.
/// The immutable wrapper is the real Chainlink Fuji VRF v2.5 wrapper on Fuji.
contract FujiChainlinkHermann is Hatcher_Hermann {
    address public constant FUJI_CHAINLINK_WRAPPER = 0x327B83F409E1D5f13985c6d0584420FA648f1F56;
    constructor(address authority_, address token_, address nft_, address wrapper_, uint16 confirmations_)
        Hatcher_Hermann(authority_, token_, nft_, wrapper_, confirmations_)
    {
        require(block.chainid == 43113 || block.chainid == 31337, "test networks only");
        require(wrapper_ == FUJI_CHAINLINK_WRAPPER, "official Fuji wrapper only");
    }
    function INCUBATION_TIME() public pure override returns (uint256) { return 2 minutes; }
}
