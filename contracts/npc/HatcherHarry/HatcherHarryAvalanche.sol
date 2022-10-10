// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";

import "../../ERC721/interfaces/EvoStructs.sol";
import "../../utils/chainlink/ChainlinkVRFConsumerUpgradeableV2.sol";
import "../../ERC721/EvoEgg/IEvoEggGen0.sol";
import "../../ERC721/interfaces/IEvo.sol";
import "../../utils/constants/NpcConstants.sol";

/**
* @title Hatcher Harry v1.0.0
* @author @DirtyCajunRice
*/
contract HatcherHarryAvalanche is Initializable, EvoStructs, PausableUpgradeable,
AccessControlEnumerableUpgradeable, ChainlinkVRFConsumerUpgradeableV2, NpcConstants {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToUintMap;
    using StringsUpgradeable for uint256;

    IEvoEggGen0 private _egg;
    IEvo private _evo;

    // Hatch storage
    mapping (address => PendingHatch) private _pendingHatches;
    EnumerableSetUpgradeable.AddressSet private _pendingHatchAddresses;
    mapping (uint256 => address) private _requestIdToAddress;

    // Base gene storage
    // speciesId -> param -> value
    mapping(uint256 => EnumerableMapUpgradeable.UintToUintMap) private _speciesBase;
    // set of configured species
    EnumerableSetUpgradeable.UintSet private _speciesIds;

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

        _egg = IEvoEggGen0(0x75dDd2b19E6f7BEd3Bfe9D2D21dd226C38C0CbC4);
        _evo = IEvo(0x454a0E479ac78e508a95880216C06F50bf3C321C);
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function incubate(uint256[] memory tokenIds) public {
        require(tokenIds.length <= 5, "Maximum 5 per hatch");

        PendingHatch memory pending;
        (pending,) = getPendingHatch(_msgSender());
        require(pending.requestId == 0, "Existing hatch in progress");

        PendingHatch storage ph = _pendingHatches[_msgSender()];
        _egg.hatch(_msgSender(), tokenIds);

        ph.requestId = requestRandomWords(uint32(tokenIds.length));
        ph.ids = tokenIds;

        _requestIdToAddress[ph.requestId] = _msgSender();
        _pendingHatchAddresses.add(_msgSender());
    }

    function hatch() external {
        PendingHatch memory ph;
        bool migrated;
        (ph, migrated)= getPendingHatch(_msgSender());

        require(ph.requestId > 0, "No pending hatch in progress");
        require(ph.words.length > 0, "Results still pending");

        Evo[] memory evo = _hatch(ph);
        _evo.batchMint(_msgSender(), evo);

        if (migrated) {
            _evo.clearPendingHatch(_msgSender());
        } else {
            delete _requestIdToAddress[_pendingHatches[_msgSender()].requestId];
            delete _pendingHatches[_msgSender()];
            _pendingHatchAddresses.remove(_msgSender());
        }
    }

    function _hatch(PendingHatch memory ph) internal view returns(Evo[] memory evo) {
        bool[] memory treated = _egg.checkTreated(ph.ids);
        uint256[] memory speciesIds;
        uint256[] memory minRarity;
        uint256 totalRarity;

        (speciesIds, minRarity, totalRarity) = rarityConfig();
        evo = new Evo[](ph.ids.length);

        for (uint256 i = 0; i < ph.ids.length; i++) {
            uint256 tokenId = ph.ids[i];
            uint256[] memory randomChunks = chunkWord(ph.words[i], 10_000, 14);
            uint256 speciesId = speciesRoll(randomChunks[0], minRarity, speciesIds, totalRarity);
            evo[i] = geneRoll(tokenId, treated[i], speciesId, randomChunks);
        }
    }

    function simulateHatch(address _address) public view onlyRole(ADMIN_ROLE) returns(Evo[] memory) {
        PendingHatch memory ph;
        (ph,) = getPendingHatch(_address);
        return _hatch(ph);
    }

    function speciesRoll(
        uint256 randomChunk,
        uint256[] memory minRarity,
        uint256[] memory speciesIds,
        uint256 totalRarity
    ) internal pure returns(uint256 speciesId) {
        speciesId = speciesIds[speciesIds.length - 1];
        uint256 speciesResult = randomChunk % totalRarity;
        for (uint256 i = 0; i < minRarity.length; i++) {
            if (speciesResult > minRarity[i]) {
                continue;
            }
            speciesId = speciesIds[i];
            break;
        }
    }

    function geneRoll(uint256 tokenId, bool treated, uint256 speciesId, uint256[] memory randomChunks)
    internal view returns (Evo memory evo) {
        bool epic = (randomChunks[1] % (treated ? 3000 : 5000)) < (treated ? 9 : 1);
        bool chroma = (randomChunks[1] % (treated ? 3000 : 1000)) < (treated ? 45 : 1);
        uint256 rarity = epic ? 2 : (chroma ? 1 : 0);

        uint256 gender = (randomChunks[2] % 100) < _speciesBase[speciesId].get(2) ? 1 : 0;
        uint256 primaryType = _speciesBase[speciesId].get(3);
        uint256 secondaryType = _speciesBase[speciesId].get(4);
        uint256 nature = randomChunks[3] % 21;
        uint256[] memory battle = new uint256[](5);

        for (uint256 i = 0; i < battle.length; i++) {
            battle[i] = randomChunks[i + 4] % 51;
        }
        evo = Evo({
            tokenId: tokenId,
            species: speciesId,
            generation: 0,
            experience: 0,
            breeds: Breeds(0, 0, 0),
            attributes: Attributes(gender, rarity, primaryType, secondaryType, nature, 10),
            stats: Stats(50, battle[0], battle[1], battle[2], battle[3], battle[4]),
            moves: Moves(0, 0, 0, 0)
        });
    }

    function rarityConfig() public view returns (uint256[] memory, uint256[] memory, uint256) {
        uint256[] memory speciesIds = _speciesIds.values();
        uint256[] memory minRarity = new uint256[](speciesIds.length);
        uint256 totalRarity = 0;
        for (uint256 i = 0; i < speciesIds.length; i++) {
            if (_speciesBase[speciesIds[i]].get(0) == 0) {
                continue;
            }
            minRarity[i] = totalRarity;
            totalRarity += _speciesBase[speciesIds[i]].get(1);
        }
        return (speciesIds, minRarity, totalRarity);
    }
    function pendingHatch() public view returns(bool exists, bool ready, uint256[] memory ids) {
        return pendingHatchOf(_msgSender());
    }

    function pendingHatchOf(address _address) public view returns(bool exists, bool ready, uint256[] memory ids) {
        PendingHatch memory ph = _pendingHatches[_address];
        if (ph.requestId == 0) {
            ph = _evo.getPendingHatchFor(_address);
        }
        return (ph.requestId != 0, ph.words.length > 0, ph.ids);
    }

    function getPendingHatch(address _address) public view returns(PendingHatch memory ph, bool migrated) {
        ph = _pendingHatches[_address];
        migrated = false;
        if (ph.requestId == 0) {
            ph = _evo.getPendingHatchFor(_address);
            migrated = true;
        }
    }

    function adminReIncubate(address _address, uint256[] memory tokenIds) public {
        require(tokenIds.length <= 5, "Maximum 5 per hatch");

        PendingHatch memory pending;
        (pending,) = getPendingHatch(_address);
        require(pending.requestId == 0, "Existing hatch in progress");

        PendingHatch storage ph = _pendingHatches[_address];

        ph.requestId = requestRandomWords(uint32(tokenIds.length));
        ph.ids = tokenIds;

        _requestIdToAddress[ph.requestId] = _address;
        _pendingHatchAddresses.add(_address);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _pendingHatches[_requestIdToAddress[requestId]].words = randomWords;
    }

    function setBaseAttributes(uint256[] memory speciesIds, uint256[][] memory _baseAttributes) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < speciesIds.length; i++) {
            _speciesIds.add(speciesIds[i]);
            for (uint256 j = 0; j < _baseAttributes[i].length; j++) {
                _speciesBase[speciesIds[i]].set(j, _baseAttributes[i][j]);
            }
        }
    }
}