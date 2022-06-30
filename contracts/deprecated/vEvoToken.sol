// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/Authorizable.sol";

/**
 * @author EvoVerses
 * @title vEvoToken
 */

/*
 * This token is the vested token for the private sale of the EvoVerses project. Since Evo tokens from the private sale are vested
 * and unlocked in a linear way (starting after the end of the public sale and finishing 11,664,000 blocks later
 * (9 months * 30 days each month * 24 hours each day * 60 minutes each hour * 60 seconds each minutes) / 2 seconds average block time).
 *
 * Vested Evo tokens can be swaped in exchange of Evo tokens following that vesting schedule in the EvoVerses website.
 * Vested tokens can not be transferred in any way but they can be staked in a special single token pool (available only for vEVO holders).
 * This pool has way less rewards than public pools but it allows private sale investors to still use their tokens for profit even
 * if they can't be transferred.
 */

contract vEvoToken is ERC20, Ownable, Authorizable, ReentrancyGuard {
    // It is a vested token, so you shouldn't be able to transfer it most of the time
    // But we need to allow users to transfer to some addresses
    // Like the single token farm or the claiming EVO token contract
    mapping(address => bool) _allowedTransferToAddresses;
    bool public mintingEnabled;

    // Events
    event AllowedTransfersListUpdated(address indexed addr, bool value);
    event EnabledMinting();
    event DisabledMinting();
    event TokenMinted(address indexed receiver, uint256 amount);
    //

    // Modifiers
    modifier onlyWithMintingEnabled() {
        require(mintingEnabled == true, "Minting is not enabled!");
        _;
    }

    //

    constructor() ERC20("vEVO", "vEVO") Ownable() {
        // We have to mint only the amount of vested tokens equivalent to the EVO tokens sold in the private sale
        // You can find the amount here: https://docs.evoverses.com/tokenomics/evo-token#token-distribution
        // We need to whitelist owner (msg.sender) address so we can send the minted tokens
        //addToAllowedTransfers(msg.sender);
        //_mint(msg.sender, 17000000 * (10**uint256(decimals())));
        // After that we should remove it from the whitelist
        //removeFromAllowedTransfers(msg.sender);
        mintingEnabled = true;
        emit EnabledMinting();
    }

    function enableMinting() public onlyAuthorized {
        require(mintingEnabled == false, "Minting is already enabled!");
        mintingEnabled = true;
        emit EnabledMinting();
    }

    function disableMinting() public onlyAuthorized {
        require(mintingEnabled == true, "Minting is already disabled!");
        mintingEnabled = false;
        emit DisabledMinting();
    }

    function mintTokenFor(address addr, uint256 amount)
    public
    onlyAuthorized
    nonReentrant
    onlyWithMintingEnabled
    {
        addToAllowedTransfers(addr);
        _mint(addr, amount);
        removeFromAllowedTransfers(addr);
        emit TokenMinted(addr, amount);
    }

    // Only the owner should be able to whitelist addresses for transfers
    function addToAllowedTransfers(address addr) public onlyAuthorized {
        _allowedTransferToAddresses[addr] = true;
        emit AllowedTransfersListUpdated(addr, true);
    }

    // The same applies for removing whitelisted transfer addresses
    function removeFromAllowedTransfers(address addr) public onlyAuthorized {
        _allowedTransferToAddresses[addr] = false;
        emit AllowedTransfersListUpdated(addr, false);
    }

    function isAllowedToTransferTo(address addrToTransferTo)
    public
    view
    returns (bool)
    {
        return _allowedTransferToAddresses[addrToTransferTo];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        require(
            isAllowedToTransferTo(to),
            "Token transfer refused. Receiver is not in the whitelist"
        );
        super._beforeTokenTransfer(from, to, amount);
    }
}