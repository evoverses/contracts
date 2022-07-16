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

        EVO = ERC20Upgradeable(0x42006Ab57701251B580bDFc24778C43c9ff589A1);
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

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setBaseToken(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        EVO = ERC20Upgradeable(_address);
    }
}