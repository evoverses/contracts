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

    uint256 public TOTAL_FEES;
    uint256 public TOTAL_REFUNDED;
    uint256 public TOTAL_TO_REFUND;

    IERC20Upgradeable public REFUND_TOKEN;

    struct User {
        Refund[] refunds;
    }

    struct Refund {
        address _address;
        uint256 withdrawn;
        string txHash;
        uint256 block;
        uint256 time;
        uint256 fee;
        bool paid;
    }

    mapping (address => User) private users;

    EnumerableSetUpgradeable.AddressSet private _wallets;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();

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

    function addRefund(Refund memory _refund) public onlyRole(SCRIBE_ROLE) {
        User storage user = users[_refund._address];
        bool exists = false;
        for (uint256 i = 0; i < user.refunds.length; i++) {
            if (compareStrings(user.refunds[i].txHash, _refund.txHash)) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            Refund memory refund;

            refund._address = _refund._address;
            refund.withdrawn = _refund.withdrawn;
            refund.txHash = _refund.txHash;
            refund.block = _refund.block;
            refund.time = _refund.time;
            refund.fee = _refund.fee;
            refund.paid = _refund.paid;

            user.refunds.push(refund);

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
        return users[_address].refunds;
    }

    function pendingRefundsByAddress(address _address) public view returns (Refund[] memory) {
        User storage user = users[_address];
        Refund[] memory refunds;
        for (uint256 i = 0; i < user.refunds.length; i++) {
            if (! user.refunds[i].paid) {
                refunds[refunds.length] = user.refunds[i];
            }
        }
        return refunds;
    }

    function claimRefund() public nonReentrant whenNotPaused {
        require(pendingRefundsByAddress(_msgSender()).length > 0, "No pending refunds");
        User storage user = users[_msgSender()];
        for (uint256 i = 0; i < user.refunds.length; i++) {
            if (! user.refunds[i].paid) {
                uint256 funds = REFUND_TOKEN.balanceOf(address(this));
                require(funds > user.refunds[i].fee, "Insufficient contract balance to refund. Notify in discord");
                user.refunds[i].paid = true;
                TOTAL_REFUNDED += user.refunds[i].fee;
                TOTAL_TO_REFUND -= user.refunds[i].fee;
                REFUND_TOKEN.safeTransfer(_msgSender(), user.refunds[i].fee);
            }
        }
    }

    function allAffectedAddresses() public view onlyRole(ADMIN_ROLE) returns(address[] memory) {
        return _wallets.values();
    }

    function allRefunds() public view onlyRole(ADMIN_ROLE) returns(Refund[][] memory) {
        Refund[][] memory refunds;
        address[] memory _addresses = allAffectedAddresses();
        for (uint256 i = 0; i < _addresses.length; i++) {
            for (uint256 j = 0; j < users[_addresses[i]].refunds.length; j++) {
                refunds[i][j] = users[_addresses[i]].refunds[j];
            }
        }
        return refunds;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function updateRefundToken(IERC20Upgradeable refundToken) public onlyRole(ADMIN_ROLE) {
        REFUND_TOKEN = refundToken;
    }

    function updateGenesisBlock(uint256 genesisBlock) public onlyRole(ADMIN_ROLE) {
        GENESIS_REFUND_FROM_BLOCK = genesisBlock;
    }
}