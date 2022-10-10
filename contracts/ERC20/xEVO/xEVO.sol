// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../utils/constants/TokenConstants.sol";

/**
* @title xEVO v2.0.0
* @author @DirtyCajunRice
*/
contract xEVO is Initializable, ERC20Upgradeable, PausableUpgradeable, AccessControlEnumerableUpgradeable, TokenConstants {

    ERC20Upgradeable private constant EVO = ERC20Upgradeable(0xc8849f32138de93F6097199C5721a9EfD91ceE01);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("xEVO", "xEVO");
        __Pausable_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function deposit(uint256 amount) public whenNotPaused {
        uint256 totalGovernanceToken = EVO.balanceOf(address(this));

        uint256 totalShares = totalSupply();

        if (totalShares == 0 || totalGovernanceToken == 0) {
            _mint(_msgSender(), amount);
        } else {
            uint256 what = amount * totalShares / totalGovernanceToken;
            _mint(_msgSender(), what);
        }

        EVO.transferFrom(_msgSender(), address(this), amount);
    }

    function withdraw(uint256 amount) public whenNotPaused {
        uint256 totalShares = totalSupply();

        uint256 what = amount * EVO.balanceOf(address(this)) / totalShares;

        _burn(_msgSender(), amount);

        EVO.transfer(_msgSender(), what);
    }

    function batchMint(address[] memory to, uint256[] memory amount) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], amount[i]);
        }
    }

    function batchBurn(address[] memory to, uint256[] memory amount) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < to.length; i++) {
            _burn(to[i], amount[i]);
        }
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}