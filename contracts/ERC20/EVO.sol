// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {ERC20CappedUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
* @title EVO v2.0.0
* @author @DirtyCajunRice
*/
contract EVO is
Initializable,
ERC20Upgradeable,
ERC20BurnableUpgradeable,
ERC20CappedUpgradeable,
ERC20PausableUpgradeable,
AccessControlUpgradeable,
ERC20PermitUpgradeable,
AccessManagedUpgradeable
{
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 private _totalBurned;

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
    __AccessManaged_init(0x204fc7955F816352afDe77D84e4e8719D2C28A0A);

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  function pause() public onlyRole(ADMIN_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(ADMIN_ROLE) {
    _unpause();
  }

  function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE)  {
    _mint(to, amount);
  }

  function totalBurned() public view virtual returns (uint256) {
    return _totalBurned;
  }

  function burn(uint256 amount) public virtual override(ERC20BurnableUpgradeable) {
    _totalBurned += amount;
    _burn(msg.sender, amount);
  }

  function burnFrom(address account, uint256 amount) public virtual override(ERC20BurnableUpgradeable) {
    if (account != _msgSender()) {
      _spendAllowance(account, msg.sender, amount);
    }
    _totalBurned += amount;
    _burn(account, amount);
  }

  function cap() public view override(ERC20CappedUpgradeable) returns (uint256) {
    return super.cap() - totalBurned();
  }

  function _update(address from, address to, uint256 value) internal override(
  ERC20Upgradeable,
  ERC20PausableUpgradeable,
  ERC20CappedUpgradeable
  ) {
    super._update(from, to, value);
  }
}
