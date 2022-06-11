// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./IEvoToken.sol";

/**
* @title Compensation EVO v1.0.0
* @author @DirtyCajunRice
*/
contract cEVO is Initializable, ERC20Upgradeable, PausableUpgradeable, AccessControlUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IEvoToken public constant EVO = IEvoToken(0x5b747e23a9E4c509dd06fbd2c0e3cB8B846e398F);

    uint256 public constant DEFAULT_VESTING_PERIOD = 273 days; // ~9 months

    struct Disbursement {
        uint256 startTime;
        uint256 duration;
        uint256 amount;
        uint256 balance;
    }

    EnumerableSetUpgradeable.AddressSet private _globalWhitelist;

    mapping (address => EnumerableSetUpgradeable.AddressSet) private _whitelist;

    mapping (address => Disbursement[]) public disbursements;

    modifier onlyWhitelist(address from, address to) {
        require(
            _globalWhitelist.contains(to) || _whitelist[from].contains(to) || from == address(0),
            "cEVO is non-transferable"
        );
        _;
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC20_init("cEVO", "cEVO");
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 startTime, uint256 duration, uint256 amount) public onlyRole(MINTER_ROLE) {
        uint256 _startTime = startTime > 0 ? startTime : block.timestamp;
        uint256 _duration = duration > 0 ? duration : DEFAULT_VESTING_PERIOD;
        disbursements[to].push(
          Disbursement(
            {
              startTime: _startTime,
              duration: _duration,
              amount: amount,
              balance: amount
            }
          )
        );
        _mint(to, amount);
    }

    function batchMint(
        address[] memory to,
        uint256[] memory amount,
        uint256 startTime,
        uint256 duration
    ) public onlyRole(MINTER_ROLE) {
        require(to.length == amount.length, "to and amount arrays must match");
        for (uint256 i = 0; i < to.length; i++) {
            mint(to[i], startTime, duration, amount[i]);
        }
    }

    function claimPending() public whenNotPaused {
        uint256 totalPending = 0;
        for (uint256 i = 0; i < disbursements[_msgSender()].length; i++) {
            Disbursement storage d = disbursements[_msgSender()][i];
            uint256 pending = (d.amount / d.duration) - (d.amount - d.balance);
            d.balance -= pending;
            totalPending += pending;
        }
        if (EVO.balanceOf(address(this)) > totalPending) {
            EVO.transfer(_msgSender(), totalPending);
            return;
        }
        EVO.mint(_msgSender(), totalPending);
    }

    function pendingOf(address _address) public view returns(uint256) {
        uint256 totalPending = 0;
        for (uint256 i = 0; i < disbursements[_address].length; i++) {
            Disbursement storage d = disbursements[_address][i];
            uint256 pending = (d.amount / d.duration) - (d.amount - d.balance);
            totalPending += pending;
        }
        return totalPending;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal whenNotPaused override onlyWhitelist(from, to) {
        super._beforeTokenTransfer(from, to, amount);
    }
}