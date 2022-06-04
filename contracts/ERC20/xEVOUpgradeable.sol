// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
* @title xEVO v1.0.0
* @author @DirtyCajunRice
*/
contract xEVOUpgradeable is Initializable, PausableUpgradeable, AccessControlUpgradeable, ERC20Upgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");

    ERC20Upgradeable private EVO;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC20_init("xEVO", "xEVO");
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(CONTRACT_ROLE, _msgSender());

        EVO = ERC20Upgradeable(0x5b747e23a9E4c509dd06fbd2c0e3cB8B846e398F);
    }

    function deposit(uint256 amount) public whenNotPaused {
        uint256 balance = EVO.balanceOf(address(this));

        uint256 total = totalSupply();

        EVO.transferFrom(_msgSender(), address(this), amount);

        uint256 due = (total == 0 || balance == 0) ? amount : amount * total / balance;

        _mint(_msgSender(), due);
    }

    function withdraw(uint256 amount) public {
        uint256 balance = EVO.balanceOf(address(this));

        uint256 total = totalSupply();

        uint256 due = amount * balance / total;

        _burn(_msgSender(), due);

        EVO.transfer(_msgSender(), due);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}