// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.20;

import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
* @title xEVO v3.0.0
* @author @DirtyCajunRice
* @custom:security-contact security@evoverses.com
*/
contract xEVO is
Initializable,
ERC20Upgradeable,
ERC20BurnableUpgradeable,
ERC20PausableUpgradeable,
AccessManagedUpgradeable,
UUPSUpgradeable
{

  ERC20Upgradeable private constant EVO = ERC20Upgradeable(0x42006Ab57701251B580bDFc24778C43c9ff589A1);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() initializer public {
    __ERC20_init("xEVO", "xEVO");
    __ERC20Burnable_init();
    __ERC20Pausable_init();
    __AccessManaged_init(0x204fc7955F816352afDe77D84e4e8719D2C28A0A);
    __UUPSUpgradeable_init();
  }

  function pause() public restricted {
    _pause();
  }

  function unpause() public restricted {
    _unpause();
  }

  function deposit(uint256 amount) public whenNotPaused {
    uint256 totalGovernanceToken = EVO.balanceOf(address(this));

    uint256 totalShares = totalSupply();

    if (totalShares == 0 || totalGovernanceToken == 0) {
      _mint(msg.sender, amount);
    } else {
      uint256 what = amount * totalShares / totalGovernanceToken;
      _mint(msg.sender, what);
    }

    EVO.transferFrom(msg.sender, address(this), amount);
  }

  function withdraw(uint256 amount) public whenNotPaused {
    uint256 totalShares = totalSupply();

    uint256 what = amount * EVO.balanceOf(address(this)) / totalShares;

    _burn(msg.sender, amount);

    EVO.transfer(msg.sender, what);
  }

  function batchMint(address[] memory to, uint256[] memory amount) public restricted {
    for (uint256 i = 0; i < to.length; i++) {
      _mint(to[i], amount[i]);
    }
  }

  function batchBurn(address[] memory to, uint256[] memory amount) public restricted {
    for (uint256 i = 0; i < to.length; i++) {
      _burn(to[i], amount[i]);
    }
  }

  function _authorizeUpgrade(address newImplementation) internal restricted override {}

  // The following functions are overrides required by Solidity.

  function _update(address from, address to, uint256 value) internal override(
  ERC20Upgradeable,
  ERC20PausableUpgradeable
  ) {
    super._update(from, to, value);
  }
}
