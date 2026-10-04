// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IEvoBreedingMint} from "../Breeding/IEvoBreedingMint.sol";
import {EvoBreedingRules as Rules} from "../Breeding/EvoBreedingRules.sol";
import {NativeVRFConsumer} from "../Breeding/NativeVRFConsumer.sol";

interface IBerthaWiring {
    function hatcher() external view returns (address);
    function evoNft() external view returns (address);
    function evoToken() external view returns (address);
}

/// @notice V2 egg state, immutable imported adult traits, and Harry's hatch rules.
/// Eggs and adults share the existing Evo NFT collection and retain their token ID.
contract Hatcher_Hermann is NativeVRFConsumer {
    using SafeERC20 for IERC20;
    enum EggStatus { NONE, INCUBATING, RANDOM_PENDING, HATCHED }
    struct Egg {
        uint256 parent1;
        uint256 parent2;
        uint256 speciesVersion;
        uint256 createdAt;
        bool treated;
        EggStatus status;
        uint256 vrfRequestId;
    }
    IERC20 public immutable evoToken;
    IEvoBreedingMint public immutable evoNft;
    address public breeder;
    uint256 public constant TREAT_COST = 250 ether;
    uint256 public constant INCUBATION_TIME = 3 days;
    uint256 public speciesVersion;
    mapping(uint256 => Rules.Species[]) private _speciesPools;
    mapping(uint256 => mapping(uint256 => Rules.Species)) private _species;
    mapping(uint256 => mapping(uint256 => bool)) private _configured;
    mapping(uint256 => Rules.Adult) private _adults;
    mapping(uint256 => bool) public known;
    mapping(uint256 => Egg) public eggs;
    mapping(uint256 => uint256) public parentReservation;

    error OnlyBreeder();
    error InvalidAdult();
    error InvalidSpeciesPool();
    error AlreadyKnown();
    error NotAdult();
    error NotOwner();
    error ParentUnavailable();
    error IncompatibleParents();
    error InvalidEggState();
    error StillIncubating();
    error RandomnessNotReady();
    error WrongReservation();
    event BreederConfigured(address indexed breeder);
    event SpeciesConfigured(uint256 indexed version);
    event AdultImported(uint256 indexed tokenId, bytes32 snapshotHash);
    event EggRecorded(uint256 indexed tokenId, uint256 parent1, uint256 parent2, uint256 species, uint256 generation);
    event EggTreated(uint256 indexed tokenId, address indexed payer);
    event HatchRequested(uint256 indexed tokenId, uint256 indexed vrfRequestId, address indexed payer);
    event EggHatched(uint256 indexed tokenId, uint256 indexed vrfRequestId, bytes32 traitsHash);

    constructor(address authority_, address token_, address nft_, address wrapper_, uint16 confirmations_)
        NativeVRFConsumer(authority_, wrapper_, confirmations_)
    {
        if (token_.code.length == 0 || nft_.code.length == 0) revert InvalidConfiguration();
        evoToken = IERC20(token_);
        evoNft = IEvoBreedingMint(nft_);
    }

    function setBreeder(address breeder_) external restricted {
        if (breeder != address(0) || breeder_.code.length == 0) revert InvalidConfiguration();
        IBerthaWiring b = IBerthaWiring(breeder_);
        if (b.hatcher() != address(this) || b.evoNft() != address(evoNft) || b.evoToken() != address(evoToken)) {
            revert InvalidConfiguration();
        }
        breeder = breeder_;
        emit BreederConfigured(breeder_);
    }

    /// @notice Each configuration creates a new immutable version; pending eggs retain the old one.
    function configureSpecies(Rules.Species[] calldata pool) external restricted {
        if (pool.length == 0 || pool.length > 256) revert InvalidSpeciesPool();
        uint256 version = ++speciesVersion;
        uint256 total;
        for (uint256 i; i < pool.length; ++i) {
            Rules.Species calldata s = pool[i];
            if (_configured[version][s.id] || s.malePercentage > 100) revert InvalidSpeciesPool();
            if (s.enabled) {
                if (s.weight == 0) revert InvalidSpeciesPool();
                total += s.weight;
            }
            _configured[version][s.id] = true;
            _species[version][s.id] = s;
            _speciesPools[version].push(s);
        }
        if (total == 0) revert InvalidSpeciesPool();
        emit SpeciesConfigured(version);
    }

    function getSpeciesPool(uint256 version) external view returns (Rules.Species[] memory) {
        return _speciesPools[version];
    }

    /// @notice Trusted, one-time import of verified existing V2 metadata. Never overwrites an egg/adult.
    function importAdult(uint256 tokenId, Rules.Adult calldata adult) external restricted {
        if (known[tokenId]) revert AlreadyKnown();
        if (!Rules.validAdult(adult) || adult.lastBreedTime > block.timestamp ||
            !_configured[speciesVersion][adult.species]) revert InvalidAdult();
        evoNft.ownerOf(tokenId); // Cannot import a nonexistent or burned NFT.
        _adults[tokenId] = adult;
        known[tokenId] = true;
        emit AdultImported(tokenId, keccak256(abi.encode(adult)));
    }

    function adultOf(uint256 tokenId) public view returns (Rules.Adult memory) {
        if (!known[tokenId] || (eggs[tokenId].status != EggStatus.NONE && eggs[tokenId].status != EggStatus.HATCHED)) {
            revert NotAdult();
        }
        return _adults[tokenId];
    }

    function previewBreed(uint256 parent1, uint256 parent2, address owner)
        external view returns (uint256 cost, uint256 version)
    {
        (Rules.Adult memory a, Rules.Adult memory b) = _checkParents(parent1, parent2, owner);
        return (Rules.cost(a) + Rules.cost(b), speciesVersion);
    }

    function _checkParents(uint256 parent1, uint256 parent2, address owner)
        private view returns (Rules.Adult memory a, Rules.Adult memory b)
    {
        if (parent1 == parent2) revert IncompatibleParents();
        if (evoNft.ownerOf(parent1) != owner || evoNft.ownerOf(parent2) != owner) revert NotOwner();
        a = adultOf(parent1);
        b = adultOf(parent2);
        if (parentReservation[parent1] != 0 || parentReservation[parent2] != 0 ||
            (a.generation != 0 && a.totalBreeds >= 5) || (b.generation != 0 && b.totalBreeds >= 5) ||
            block.timestamp < a.lastBreedTime + Rules.cooldown(a.generation) ||
            block.timestamp < b.lastBreedTime + Rules.cooldown(b.generation)) revert ParentUnavailable();
        if (!Rules.compatible(a.attributes, b.attributes)) revert IncompatibleParents();
        if (!_configured[speciesVersion][a.species] || !_configured[speciesVersion][b.species]) {
            revert InvalidSpeciesPool();
        }
    }

    function reserveParents(uint256 parent1, uint256 parent2, address owner, uint256 requestId)
        external whenNotPaused returns (uint256 cost, uint256 version)
    {
        _onlyBreeder();
        if (requestId == 0) revert WrongReservation();
        (Rules.Adult memory a, Rules.Adult memory b) = _checkParents(parent1, parent2, owner);
        parentReservation[parent1] = requestId;
        parentReservation[parent2] = requestId;
        return (Rules.cost(a) + Rules.cost(b), speciesVersion);
    }

    function releaseParents(uint256 parent1, uint256 parent2, uint256 requestId) external {
        _onlyBreeder();
        _releaseParents(parent1, parent2, requestId);
    }

    function _releaseParents(uint256 parent1, uint256 parent2, uint256 requestId) private {
        if (parentReservation[parent1] != requestId || parentReservation[parent2] != requestId) revert WrongReservation();
        delete parentReservation[parent1];
        delete parentReservation[parent2];
    }

    function recordEgg(uint256 tokenId, uint256 parent1, uint256 parent2, uint256 version,
        uint256 requestId, uint256 committedAt, uint256 random) external whenNotPaused
    {
        _onlyBreeder();
        if (known[tokenId]) revert AlreadyKnown();
        Rules.Adult memory a = adultOf(parent1);
        Rules.Adult memory b = adultOf(parent2);
        _releaseParents(parent1, parent2, requestId);
        uint256 species = Rules.childSpecies(a, b, _speciesPools[version], random);
        uint256 generation = (a.generation > b.generation ? a.generation : b.generation) + 1;
        _adults[tokenId].species = species;
        _adults[tokenId].generation = generation;
        known[tokenId] = true;
        eggs[tokenId] = Egg(parent1, parent2, version, block.timestamp, false, EggStatus.INCUBATING, 0);
        _adults[parent1].totalBreeds++;
        _adults[parent2].totalBreeds++;
        _adults[parent1].lastBreedTime = committedAt;
        _adults[parent2].lastBreedTime = committedAt;
        emit EggRecorded(tokenId, parent1, parent2, species, generation);
    }

    function treat(uint256 tokenId) external whenNotPaused nonReentrant {
        Egg storage egg = eggs[tokenId];
        if (evoNft.ownerOf(tokenId) != msg.sender) revert NotOwner();
        if (egg.status != EggStatus.INCUBATING || egg.treated) revert InvalidEggState();
        egg.treated = true;
        evoToken.safeTransferFrom(msg.sender, TREASURY, TREAT_COST);
        emit EggTreated(tokenId, msg.sender);
        evoNft.requestMetadataUpdate(tokenId);
    }

    function requestHatch(uint256 tokenId) external payable whenNotPaused nonReentrant returns (uint256 id) {
        Egg storage egg = eggs[tokenId];
        if (evoNft.ownerOf(tokenId) != msg.sender) revert NotOwner();
        if (egg.status != EggStatus.INCUBATING) revert InvalidEggState();
        if (block.timestamp < egg.createdAt + INCUBATION_TIME) revert StillIncubating();
        egg.status = EggStatus.RANDOM_PENDING; // Treatment is locked BEFORE requesting the rarity roll.
        id = _requestRandomness(msg.sender);
        egg.vrfRequestId = id;
        emit HatchRequested(tokenId, id, msg.sender);
    }

    /// @notice Anyone may complete a ready hatch; the existing NFT and its owner remain unchanged.
    function completeHatch(uint256 tokenId) external whenNotPaused nonReentrant {
        Egg storage egg = eggs[tokenId];
        if (egg.status != EggStatus.RANDOM_PENDING) revert InvalidEggState();
        Randomness storage r = randomness[egg.vrfRequestId];
        if (!r.fulfilled) revert RandomnessNotReady();
        Rules.Adult storage adult = _adults[tokenId];
        (adult.attributes, adult.stats) = Rules.hatch(adultOf(egg.parent1), adultOf(egg.parent2),
            _species[egg.speciesVersion][adult.species], egg.treated, r.word);
        egg.status = EggStatus.HATCHED;
        emit EggHatched(tokenId, egg.vrfRequestId, keccak256(abi.encode(adult)));
        evoNft.requestMetadataUpdate(tokenId);
    }

    function _onlyBreeder() private view {
        if (msg.sender != breeder) revert OnlyBreeder();
    }
}
