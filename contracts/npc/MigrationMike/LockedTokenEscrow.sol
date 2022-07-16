// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../ERC20/interfaces/IcEVOUpgradeable.sol";
import "../../ERC20/interfaces/IMintable.sol";

/**
* @title Locked Token Escrow v1.0.0
* @author @DirtyCajunRice
*/
contract LockedTokenEscrow is Ownable {
    address private constant _BURN_ADDRESS = 0x0000000000000000000000000000000000000001;

    address public beneficiary;
    IERC20 public token;

    uint256 public unlocked;
    uint256 public locked;

    constructor (address _beneficiary, address _token) {
        beneficiary = _beneficiary;
        token = IERC20(_token);
    }

    function finalize() public onlyOwner {
        IMintable(address(token)).transferAll(_BURN_ADDRESS);
        selfdestruct(payable(beneficiary));
    }

    function setBalances() public onlyOwner {
        unlocked = token.balanceOf(address(this));
        locked = IMintable(address(token)).lockOf(address(this));
    }

    function getBalances() public view returns(uint256 _unlocked, uint256 _locked) {
        _unlocked = unlocked;
        _locked = locked;
    }
}