// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
* @title Emergency Withdrawal Reimbursement v1.0.0
* @author @DirtyCajunRice
*/
contract EmergencyWithdrawalReimbursementUpgradeable is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SCRIBE_ROLE = keccak256("SCRIBE_ROLE");

    uint256 public GENESIS_REFUND_FROM_BLOCK;
    uint256 public LAST_SNAPSHOT_BLOCK;
    IERC20Upgradeable public REFUND_TOKEN;
    uint256 public TOTAL_FEES;
    uint256 public TOTAL_REFUNDED;
    uint256 public TOTAL_TO_REFUND;

    struct Refund {
        address _address;
        uint256 withdrawn;
        string txHash;
        uint256 block;
        uint256 time;
        uint256 fee;
        bool paid;
    }

    mapping (address => Refund[]) public refunds;

    EnumerableSetUpgradeable.AddressSet private _wallets;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(SCRIBE_ROLE, _msgSender());

        GENESIS_REFUND_FROM_BLOCK = 25481041;
        LAST_SNAPSHOT_BLOCK = 25481041;
        REFUND_TOKEN = IERC20Upgradeable(0x5b747e23a9E4c509dd06fbd2c0e3cB8B846e398F);
        TOTAL_FEES = 0;
        TOTAL_REFUNDED = 0;
        TOTAL_TO_REFUND = 0;
    }

    function addRefund(Refund memory refund) public onlyRole(SCRIBE_ROLE) {
        Refund[] storage _refunds = refunds[_msgSender()];
        bool exists = false;
        for (uint256 i = 0; i < _refunds.length; i++) {
            if (compareStrings(_refunds[i].txHash, refund.txHash)) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            _refunds[_refunds.length] = refund;
            _wallets.add(refund._address);
            TOTAL_FEES += refund.fee;
            TOTAL_TO_REFUND += refund.fee;
            if (LAST_SNAPSHOT_BLOCK < refund.block) {
                LAST_SNAPSHOT_BLOCK = refund.block;
            }
        }
    }

    function batchAddRefunds(Refund[] memory _refunds) public onlyRole(SCRIBE_ROLE) {
        for (uint256 i = 0; i < _refunds.length; i++) {
            addRefund(_refunds[i]);
        }
    }

    function refundsByAddress(address _address) public view returns (Refund[] memory) {
        return refunds[_address];
    }

    function pendingRefundsByAddress(address _address) public view returns (Refund[] memory) {
        Refund[] memory _refunds;
        for (uint256 i = 0; i < refunds[_address].length; i++) {
            if (!refunds[_address][i].paid) {
                _refunds[_refunds.length] = refunds[_address][i];
            }
        }
        return _refunds;
    }

    function claimRefund() public nonReentrant whenNotPaused {
        require(pendingRefundsByAddress(_msgSender()).length > 0, "No pending refunds");
        Refund[] storage _refunds = refunds[_msgSender()];
        for (uint256 i = 0; i < _refunds.length; i++) {
            if (!_refunds[i].paid) {
                uint256 funds = REFUND_TOKEN.balanceOf(address(this));
                require(funds > _refunds[i].fee, "Insufficient contract balance to refund. Notify in discord");
                _refunds[i].paid = true;
                TOTAL_REFUNDED += _refunds[i].fee;
                TOTAL_TO_REFUND -= _refunds[i].fee;
                REFUND_TOKEN.safeTransfer(_msgSender(), _refunds[i].fee);
            }
        }
    }

    function allAffectedAddresses() public view onlyRole(ADMIN_ROLE) returns(address[] memory) {
        return _wallets.values();
    }

    function allRefunds() public view onlyRole(ADMIN_ROLE) returns(Refund[][] memory) {
        Refund[][] memory _refunds;
        address[] memory _addresses = allAffectedAddresses();
        for (uint256 i = 0; i < _addresses.length; i++) {
            for (uint256 j = 0; j < refunds[_addresses[i]].length; j++) {
                _refunds[i][j] = refunds[_addresses[i]][j];
            }
        }
        return _refunds;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}