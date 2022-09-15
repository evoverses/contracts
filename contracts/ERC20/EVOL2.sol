// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../utils/constants/TokenConstants.sol";
import "./extensions/ERC20L2.sol";

/**
* @title EVO (L2) v1.0.0
* @author @DirtyCajunRice
*/
contract EVOL2 is Initializable, ERC20Upgradeable, IERC20L2, ERC20BurnableUpgradeable, ERC20CappedUpgradeable,
PausableUpgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable, TokenConstants {
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    address public l1Token;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("EVO", "EVO");
        __ERC20Burnable_init();
        __ERC20Capped_init(600_000_000 ether);
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init("EVO");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BRIDGE_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(BRIDGE_ROLE) {
        _mint(to, amount);
    }

    function burn(address _from, uint256 _amount) public onlyRole(BRIDGE_ROLE) {
        _burn(_from, _amount);
    }

    function setL1Token(address _l1Token) public onlyRole(ADMIN_ROLE) {
        l1Token = _l1Token;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Overrides
    function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControlUpgradeable) returns (bool) {
        bytes4 bridge = IERC20L2.l1Token.selector ^ IERC20L2.mint.selector ^ IERC20L2.burn.selector;
        return interfaceId == bridge || super.supportsInterface(interfaceId);
    }
}