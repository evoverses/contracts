// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
* @title ETH Receiver v1.0.0
* @author @DirtyCajunRice
*/

abstract contract ETHReceiver is Initializable {
    event ETHReceived(address from, uint256 amount);

    function __ETHReceiver_init() internal onlyInitializing {
    }

    receive() external payable virtual {
        emit ETHReceived(msg.sender, msg.value);
    }

    uint256[50] private __gap;
}