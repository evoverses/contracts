// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../ERC721/interfaces/EvoStructs.sol";
import "../utils/chainlink/ChainlinkVRFConsumerUpgradeableV2.sol";
import "../ERC721/interfaces/IEvo.sol";
import "../utils/constants/NpcConstants.sol";

/**
* @title Healer Hayley v1.0.0
* @author @DirtyCajunRice
*/
contract HealerHayley is Initializable, EvoStructs, PausableUpgradeable,
AccessControlEnumerableUpgradeable, ChainlinkVRFConsumerUpgradeableV2, NpcConstants {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    IEvo private _evo;


    mapping (address => PendingHatch) private _pendingHeals;
    EnumerableSetUpgradeable.AddressSet private _pendingHealAddresses;
    mapping (uint256 => address) private _requestIdToAddress;

    EnumerableSetUpgradeable.UintSet private _affected;
    EnumerableSetUpgradeable.UintSet private _healed;

    event HealRequested(address indexed from, uint256 indexed requestId, uint256[] tokenIds);
    event HealRequestFulfilled(uint256 indexed requestId, uint256[] randomWords);
    event Healed(address indexed from, uint256 indexed requestId, uint256 tokenId, uint256[] values);
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {

        __Pausable_init();
        __AccessControlEnumerable_init();

        address chainlinkCoordinator = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
        bytes32 keyHash = 0x83250c5584ffa93feb6ee082981c5ebe484c865196750b39835ad4f13780435d;
        uint64 subscriptionId = 29;
        uint16 confirmations = 3;

        __ChainlinkVRFConsumer_init(chainlinkCoordinator, keyHash, subscriptionId, confirmations);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(CONTRACT_ROLE, _msgSender());

        _evo = IEvo(0x454a0E479ac78e508a95880216C06F50bf3C321C);
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function requestHeal(uint256[] memory tokenIds) public {
        require(tokenIds.length <= 10, "Maximum 10 per heal");
        require(tokenIds.length > 0, "No tokenIds sent");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_affected.contains(tokenIds[i]), "Invalid tokenId");
        }

        PendingHatch storage ph = _pendingHeals[_msgSender()];
        require(ph.requestId == 0, "Existing heal in progress");

        ph.requestId = requestRandomWords(uint32(tokenIds.length));
        ph.ids = tokenIds;

        _requestIdToAddress[ph.requestId] = _msgSender();
        _pendingHealAddresses.add(_msgSender());

        emit HealRequested(_msgSender(), ph.requestId, ph.ids);
    }

    function heal() external {
        PendingHatch storage ph = _pendingHeals[_msgSender()];
        require(ph.requestId > 0, "No pending hatch in progress");
        require(ph.words.length > 0, "Results still pending");

        _heal(_msgSender());

        delete _requestIdToAddress[_pendingHeals[_msgSender()].requestId];
        delete _pendingHeals[_msgSender()];
        _pendingHealAddresses.remove(_msgSender());

    }

    function _heal(address _address) internal {
        PendingHatch storage ph = _pendingHeals[_address];

        uint256[] memory attributeIds = new uint256[](5);
        for (uint256 i = 9; i < 14; i++) {
            attributeIds[i-9] = i;
        }
        for (uint256 i = 0; i < ph.ids.length; i++) {
            uint256[] memory randomChunks = chunkWord(ph.words[i], 10_000, 5);
            _affected.remove(ph.ids[i]);
            _healed.add(ph.ids[i]);
            uint256[] memory values = _healRoll(randomChunks);
            _evo.batchAddToAttribute(ph.ids[i], attributeIds, values);
            emit Healed(_address, ph.requestId, ph.ids[i], values);
        }
    }

    function _healRoll(uint256[] memory randomChunks) internal pure returns (uint256[] memory) {
        uint256[] memory heals = new uint256[](5);

        for (uint256 i = 0; i < heals.length; i++) {
            heals[i] = randomChunks[i] % 2;
        }
        return heals;
    }

    function pendingHealOf(address _address) public view returns(bool exists, bool ready, uint256[] memory ids) {
        PendingHatch storage ph = _pendingHeals[_address];
        return (ph.requestId != 0, ph.words.length > 0, ph.ids);
    }

    function checkAffected(uint256[] memory affected) public view returns(bool[] memory) {
        bool[] memory isAffected = new bool[](affected.length);
        for (uint256 i = 0; i < affected.length; i++) {
            isAffected[i] = _affected.contains(affected[i]);
        }
        return isAffected;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _pendingHeals[_requestIdToAddress[requestId]].words = randomWords;
        emit HealRequestFulfilled(requestId, randomWords);
    }

    function setAffected(uint256[] memory affected) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < affected.length; i++) {
            if (!_healed.contains(affected[i])) {
                _affected.add(affected[i]);
            }
        }
    }

    function clearHealRequestOf(address _address) public onlyRole(ADMIN_ROLE) {
        PendingHatch memory ph = _pendingHeals[_address];
        delete _requestIdToAddress[ph.requestId];
        delete _pendingHeals[_address];
        _pendingHealAddresses.remove(_address);
    }
}