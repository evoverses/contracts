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

    // upgrade below for additional storage
    struct ExtendedRefund {
        IERC20Upgradeable refundToken;
        uint256 totalFees;
        uint256 totalRefunded;
        uint256 totalToRefund;
    }

    // txHash to poolId retroactive
    mapping (string => uint256) private txHashPoolId;
    // poolId to RefundToken retroactive
    mapping (uint256 => ExtendedRefund) private extendedRefund;
    // wallets that have been upgraded
    EnumerableSetUpgradeable.AddressSet private _walletsUpgaded;

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
        REFUND_TOKEN = IERC20Upgradeable(0xD6e76742962379e234E9Fd4E73768cEF779f38B5);
        TOTAL_FEES = 0;
        TOTAL_REFUNDED = 0;
        TOTAL_TO_REFUND = 0;
    }

    function addRefund(Refund memory _refund, uint256 poolId) public onlyRole(SCRIBE_ROLE) {
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

            if (!_walletsUpgaded.contains(_refund._address)) {
                upgradeRefundValuesByAddress(_refund._address);
            } else {
                extendedRefund[poolId].totalFees += _refund.fee;
                extendedRefund[poolId].totalToRefund += _refund.fee;
            }

            txHashPoolId[_refund.txHash] = poolId;

            if (LAST_SNAPSHOT_BLOCK < refund.block) {
                LAST_SNAPSHOT_BLOCK = refund.block;
            }
        }
    }

    function upgradeRefundValuesByAddress(address _address) public onlyRole(ADMIN_ROLE) {
        if (_walletsUpgaded.contains(_address)) {
            return;
        }

        Refund[] memory refunds = refundsByAddress(_address);
        for (uint256 i = 0; i < refunds.length; i++) {
            uint256 poolId = txHashPoolId[refunds[i].txHash];
            extendedRefund[poolId].totalFees += refunds[i].fee;
            extendedRefund[poolId].totalToRefund += refunds[i].fee;
        }
        _walletsUpgaded.add(_address);

    }

    function batchAddRefunds(Refund[] memory _refunds, uint256[] memory poolIds) public onlyRole(SCRIBE_ROLE) {
        require(_refunds.length == poolIds.length, "Refund length must match poolId length");
        require(_refunds.length > 0, "Empty input");
        for (uint256 i = 0; i < _refunds.length; i++) {
            addRefund(_refunds[i], poolIds[i]);
        }
    }

    function refundsByAddress(address _address) public view returns (Refund[] memory) {
        return users[_address].refunds;
    }

    function pendingRefundsByAddress(address _address) public view returns (Refund[] memory) {
        Refund[] memory refunds = refundsByAddress(_address);
        uint256 count = 0;
        for (uint256 i = 0; i < refunds.length; i++) {
            if (refunds[i].paid == false) {
                count++;
            }
        }
        Refund[] memory pending = new Refund[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < refunds.length; i++) {
            if (refunds[i].paid == false) {
                pending[index] = refunds[i];
                index++;
            }
        }
        return pending;
    }

    function claimRefund() public nonReentrant whenNotPaused {
        require(pendingRefundsByAddress(_msgSender()).length > 0, "No pending refunds");
        User storage user = users[_msgSender()];
        for (uint256 i = 0; i < user.refunds.length; i++) {
            if (! user.refunds[i].paid) {
                uint256 poolId = txHashPoolId[user.refunds[i].txHash];
                ExtendedRefund storage eRefund = extendedRefund[poolId];

                uint256 funds = eRefund.refundToken.balanceOf(address(this));
                require(funds > user.refunds[i].fee, "Insufficient contract balance to refund. Notify in discord");

                user.refunds[i].paid = true;
                eRefund.totalRefunded += user.refunds[i].fee;
                if (eRefund.totalToRefund >= user.refunds[i].fee) {
                    eRefund.totalToRefund -= user.refunds[i].fee;
                }
                eRefund.refundToken.safeTransfer(_msgSender(), user.refunds[i].fee);
            }
        }
    }

    function claimRefundByIndex(uint256 index) public nonReentrant whenNotPaused {
        User storage user = users[_msgSender()];
        require(user.refunds[index].time > 0, "Invalid index");
        require(user.refunds[index].paid == false, "Already paid");


        uint256 poolId = txHashPoolId[user.refunds[index].txHash];
        ExtendedRefund storage eRefund = extendedRefund[poolId];

        uint256 funds = eRefund.refundToken.balanceOf(address(this));
        require(funds > user.refunds[index].fee, "Insufficient contract balance to refund. Notify in discord");

        user.refunds[index].paid = true;
        eRefund.totalRefunded += user.refunds[index].fee;
        if (eRefund.totalToRefund >= user.refunds[index].fee) {
            eRefund.totalToRefund -= user.refunds[index].fee;
        }
        eRefund.refundToken.safeTransfer(_msgSender(), user.refunds[index].fee);
    }

    function claimForAddressByIndex(address _address, uint256 index) public nonReentrant whenNotPaused onlyRole(ADMIN_ROLE) {
        require(pendingRefundsByAddress(_address).length > 0, "No pending refunds for user");
        User storage user = users[_address];
        if (! user.refunds[index].paid) {
            uint256 poolId = txHashPoolId[user.refunds[index].txHash];
            ExtendedRefund storage eRefund = extendedRefund[poolId];

            uint256 funds = eRefund.refundToken.balanceOf(address(this));
            require(funds > user.refunds[index].fee, "Insufficient contract balance to refund. Notify in discord");

            user.refunds[index].paid = true;
            eRefund.totalRefunded += user.refunds[index].fee;
            if (eRefund.totalToRefund >= user.refunds[index].fee) {
                eRefund.totalToRefund -= user.refunds[index].fee;
            }
            eRefund.refundToken.safeTransfer(_address, user.refunds[index].fee);
        }
    }

    function reviseRefund(address _address, uint256 index, bool paid) public nonReentrant whenNotPaused onlyRole(ADMIN_ROLE) {
        users[_address].refunds[index].paid = paid;
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

    function updateGenesisBlock(uint256 genesisBlock) public onlyRole(ADMIN_ROLE) {
        GENESIS_REFUND_FROM_BLOCK = genesisBlock;
    }

    function setExtendedRefund(uint256 poolId, ExtendedRefund memory eRefund) public onlyRole(ADMIN_ROLE) {
        extendedRefund[poolId].refundToken = eRefund.refundToken;
        extendedRefund[poolId].totalFees = eRefund.totalFees;
        extendedRefund[poolId].totalRefunded = eRefund.totalRefunded;
        extendedRefund[poolId].totalToRefund = eRefund.totalToRefund;
    }

    function upgradeExistingRefunds(string[] memory txHashes, uint256[] memory poolIds) public onlyRole(ADMIN_ROLE) {
        require(txHashes.length == poolIds.length, "txHashes length must match poolIds length");
        require(txHashes.length > 0, "Empty input");
        for (uint256 i = 0; i < txHashes.length; i++) {
            txHashPoolId[txHashes[i]] = poolIds[i];
        }
    }

    function getExtendedRefund(uint256 poolId) public view returns (ExtendedRefund memory) {
        return extendedRefund[poolId];
    }

    function getPoolIdByTxHash(string memory txHash) public view returns(uint256) {
        return txHashPoolId[txHash];
    }

    function getExtendedRefundByTxHash(string memory txHash) public view returns(ExtendedRefund memory) {
        return extendedRefund[txHashPoolId[txHash]];
    }
}