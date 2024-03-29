// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";

import "../extensions/ERC721EnumerableExtendedUpgradeable.sol";
import "../../utils/chainlink/ChainlinkVRFConsumerUpgradeable.sol";
import "../extensions/ERC721BlacklistUpgradeable.sol";
import "../extensions/ERC721BurnableUpgradeable.sol";
import "../../deprecated/OldTokenConstants.sol";
import "../interfaces/EvoStructs.sol";
import "../EvoEgg/IEvoEgg.sol";
import "../interfaces/IERC721L1.sol";

/**
* @title Evo v1.0.0
* @author @DirtyCajunRice
*/
contract Evo is Initializable, EvoStructs, ERC721Upgradeable, ERC721EnumerableExtendedUpgradeable,
PausableUpgradeable, AccessControlEnumerableUpgradeable, ERC721BurnableUpgradeable, OldTokenConstants,
ERC721BlacklistUpgradeable, ChainlinkVRFConsumerUpgradeable, IERC721L1 {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToUintMap;
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;

    IEvoEgg private EGG;

    // Hatch storage
    mapping (address => PendingHatch) private _pendingHatches;
    EnumerableSetUpgradeable.AddressSet private _pendingHatchAddresses;
    mapping (uint256 => address) private _requestIdToAddress;

    // Base gene storage
    // speciesId -> param -> value
    mapping(uint256 => EnumerableMapUpgradeable.UintToUintMap) private _speciesBase;
    // set of configured species
    EnumerableSetUpgradeable.UintSet private _speciesIds;

    // Evo Attribute storage
    // map speciesId to attribute id for value of attribute
    mapping(uint256 => EnumerableMapUpgradeable.UintToUintMap) private _attributes;
    mapping (uint256 => mapping(uint256 => string)) private _attributeStrings;

    string public imageBaseURI;
    string public animationBaseURI;

    uint256[] private _unused;

    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    address public l2Contract;

    modifier teamTransferCheck(address from, address to, uint256 tokenId) {
        address teamProxyWallet = 0x2F52Abfca2074b99759b58345Bb984419D304243;
        address treasury = 0x39Af60141b91F7941Eb13AedA2124a61a953b7C0;
        address bridge = 0x328eb74673Eaa1D2d90A48E8137b015F1B6Ed35d;
        require(
            tokenId > 50
            || from == address(0)
            || to == address(0)
            || from == teamProxyWallet
            || to == teamProxyWallet
            || from == treasury
            || to == treasury
            || from == bridge
            || to == bridge
            ,"Team Evo are non-transferable"
        );
        _;
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("Evo", "Evo");
        __ERC721EnumerableExtended_init();
        __Pausable_init();
        __AccessControlEnumerable_init();
        __ERC721Burnable_init();
        __ERC721Blacklist_init();

        address chainlinkCoordinator = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
        bytes32 keyHash = 0x83250c5584ffa93feb6ee082981c5ebe484c865196750b39835ad4f13780435d;
        uint64 subscriptionId = 29;
        uint16 confirmations = 3;

        __ChainlinkVRFConsumer_init(chainlinkCoordinator, keyHash, subscriptionId, confirmations);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());

        imageBaseURI = "https://github.com/EvoVerses/public-assets/raw/main/nfts/Evo/";
        EGG = IEvoEgg(0x75dDd2b19E6f7BEd3Bfe9D2D21dd226C38C0CbC4);
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function getAttribute(uint256 tokenId, uint256 attributeId) public view onlyRole(MINTER_ROLE) returns(uint256) {
        (,uint256 v) = _attributes[tokenId].tryGet(attributeId);
        return v;
    }

    function setAttribute(uint256 tokenId, uint256 attributeId, uint256 value) public onlyRole(MINTER_ROLE) {
        _attributes[tokenId].set(attributeId, value);
    }

    function batchSetAttribute(
        uint256 tokenId,
        uint256[] memory attributeIds,
        uint256[] memory values
    ) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < attributeIds.length; i++) {
            _attributes[tokenId].set(attributeIds[i], values[i]);
        }
    }

    function batchAddToAttribute(
        uint256 tokenId,
        uint256[] memory attributeIds,
        uint256[] memory values
    ) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < attributeIds.length; i++) {
            uint256 value = _attributes[tokenId].get(attributeIds[i]);
            _attributes[tokenId].set(attributeIds[i], value + values[i]);
        }
    }

    function mint(address _address, EvoStructs.Evo memory evo) public onlyRole(MINTER_ROLE) {
        _attributes[evo.tokenId].set(0, evo.species);
        _attributes[evo.tokenId].set(1, evo.attributes.rarity);
        _attributes[evo.tokenId].set(2, evo.attributes.gender);
        _attributes[evo.tokenId].set(3, evo.generation);
        _attributes[evo.tokenId].set(4, evo.attributes.primaryType);
        _attributes[evo.tokenId].set(5, evo.attributes.secondaryType);
        _attributes[evo.tokenId].set(6, evo.breeds.total);
        _attributes[evo.tokenId].set(7, evo.experience);
        _attributes[evo.tokenId].set(8, evo.attributes.nature);
        _attributes[evo.tokenId].set(9, evo.stats.attack);
        _attributes[evo.tokenId].set(10, evo.stats.defense);
        _attributes[evo.tokenId].set(11, evo.stats.special);
        _attributes[evo.tokenId].set(12, evo.stats.resistance);
        _attributes[evo.tokenId].set(13, evo.stats.speed);
        _safeMint(_address, evo.tokenId);
    }

    function batchMint(address _address, EvoStructs.Evo[] memory evos) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < evos.length; i++) {
            mint(_address, evos[i]);
        }
    }

    function getGeneralAttributes(uint256 tokenId) internal view returns (string memory) {
        string memory species = _attributeStrings[0][_attributes[tokenId].get(0)];
        string memory rarity = _attributeStrings[1][_attributes[tokenId].get(1)];
        string memory gender = _attributes[tokenId].get(2) == 0 ? 'Male' : 'Female';
        uint256 generation = _attributes[tokenId].get(3);

        return string(abi.encodePacked(
                '{"trait_type":"species","value":"',  species, '"},',
                '{"trait_type":"rarity","value":"',  rarity, '"},',
                '{"trait_type":"gender","value":"',  gender, '"},',
                '{"trait_type":"generation","value":',  generation.toString(), '},'
            ));
    }

    function getExtraAttributes(uint256 tokenId) internal view returns (string memory) {
        string memory primaryType = _attributeStrings[3][_attributes[tokenId].get(4)];
        string memory secondaryType = _attributeStrings[3][_attributes[tokenId].get(5)];
        uint256 breedCount = _attributes[tokenId].get(6);
        uint256 experience = _attributes[tokenId].get(7);
        return string(abi.encodePacked(
                '{"trait_type":"primaryType","value":"',  primaryType, '"},',
                '{"trait_type":"SecondaryType","value":"',  secondaryType, '"},',
                '{"trait_type":"breedCount","value":', breedCount.toString(), '},',
                '{"trait_type":"availableBreeds","value":',  '-1', '},',
                '{"trait_type":"experience","value":',  experience.toString(), '},'
            ));
    }

    function getBattleAttributes(uint256 tokenId) internal view returns (string memory) {
        string memory nature = _attributeStrings[4][_attributes[tokenId].get(8)];
        uint256 attack = _attributes[tokenId].get(9);
        uint256 defense = _attributes[tokenId].get(10);
        uint256 special = _attributes[tokenId].get(11);
        uint256 specialDefense = _attributes[tokenId].get(12);
        uint256 speed = _attributes[tokenId].get(13);
        bytes memory attributesA = abi.encodePacked(
            '{"trait_type":"nature","value":"',  nature, '"},',
            '{"trait_type":"attack","value":',  attack.toString(), '},',
            '{"trait_type":"defense","value":',  defense.toString(), '},'
        );
        bytes memory attributesB = abi.encodePacked(
            '{"trait_type":"special","value":',  special.toString(), '},',
            '{"trait_type":"resistance","value":',  specialDefense.toString(), '},',
            '{"trait_type":"speed","value":',  speed.toString(), '}'
        );
        return string(abi.encodePacked(attributesA, attributesB));
    }

    function getAttributesURI(uint256 tokenId) internal view returns (string memory) {
        string memory generalAttributes = getGeneralAttributes(tokenId);
        string memory extraAttributes = getExtraAttributes(tokenId);
        string memory battleAttributes = getBattleAttributes(tokenId);
        bytes memory attributesA = abi.encodePacked('"attributes": [', generalAttributes);
        bytes memory attributesB = abi.encodePacked(extraAttributes, battleAttributes, ']');
        return string(abi.encodePacked(string(attributesA), string(attributesB)));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        uint256 speciesId = _attributes[tokenId].get(0);
        string memory species = _attributeStrings[0][speciesId];
        string memory rarity = _attributeStrings[1][_attributes[tokenId].get(1)];
        string memory imageURI = string(abi.encodePacked(imageBaseURI, species, "/", rarity));
        string memory owner = ownerOf(tokenId).toHexString();
        string memory dataURIGeneral = string(abi.encodePacked(
                '"name":"', species, ' #', tokenId.toString(), '",',
                '"description":"EvoVerses Evo",',
                '"image":"', imageURI, '",',
                '"owner":"', owner, '",',
                '"tokenId":', tokenId.toString(), ','
            ));
        string memory attributesURI = getAttributesURI(tokenId);
        bytes memory dataURI = abi.encodePacked('{', dataURIGeneral, attributesURI, '}');
        return string(abi.encodePacked("data:application/json;base64,", Base64Upgradeable.encode(dataURI)));
    }

    function batchTokenURI(uint256[] memory tokenIds) public view returns(string[] memory) {
        string[] memory uris = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uris[i] = tokenURI(tokenIds[i]);
        }
        return uris;
    }

    function tokenURIRaw(uint256 tokenId) internal view virtual returns (string memory) {
        uint256 speciesId = _attributes[tokenId].get(0);
        string memory species = _attributeStrings[0][speciesId];
        string memory imageURI = string(abi.encodePacked(imageBaseURI, speciesId.toString()));
        string memory animationURI = string(abi.encodePacked(animationBaseURI, tokenId.toString()));

        string memory dataURIGeneral = string(abi.encodePacked(
                '"name":"', species, ' #', tokenId.toString(), '",',
                '"description":"EvoVerses Evo",',
                '"image":"', imageURI, '.png",',
                '"animation_url":"', animationURI, '",'
            ));
        string memory attributesURI = getAttributesURI(tokenId);
        return string(abi.encodePacked('{', dataURIGeneral, attributesURI, '}'));
    }

    function batchTokenUriJson(uint256[] memory tokenIds) public view returns(string[] memory) {
        string[] memory uris = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uris[i] = tokenURIRaw(tokenIds[i]);
        }
        return uris;
    }

    function setImageBaseURI(string memory _imageBaseURI) public onlyRole(ADMIN_ROLE) {
        imageBaseURI = _imageBaseURI;
    }

    function setAnimationBaseURI(string memory _animationBaseURI) public onlyRole(ADMIN_ROLE) {
        animationBaseURI = _animationBaseURI;
    }

    function setBaseAttributeStrings(uint256 attributeId, uint256[] memory indexes, string[] memory strings) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < indexes.length; i++) {
            _attributeStrings[attributeId][indexes[i]] = strings[i];
        }
    }

    // Used before HatcherHarry was created
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _pendingHatches[_requestIdToAddress[requestId]].words = randomWords;
    }

    // HatcherHarry migration
    function getPendingHatchFor(address _address) public view onlyRole(MINTER_ROLE) returns(PendingHatch memory) {
        return _pendingHatches[_address];
    }

    function clearPendingHatch(address _address) public onlyRole(MINTER_ROLE) {
        delete _requestIdToAddress[_pendingHatches[_address].requestId];
        delete _pendingHatches[_address];
        _pendingHatchAddresses.remove(_address);
    }

    function getPendingHatchWallets() public view onlyRole(ADMIN_ROLE) returns(address[] memory) {
        return _pendingHatchAddresses.values();
    }

    function setL2Contract(address _address) public onlyRole(ADMIN_ROLE) {
        l2Contract = _address;
    }

    function bridgeExtraData(uint256 tokenId) external view returns(bytes memory) {
        Attributes memory attributes = Attributes({
            gender: _attributes[tokenId].get(2),
            rarity: _attributes[tokenId].get(1),
            primaryType: _attributes[tokenId].get(4),
            secondaryType: _attributes[tokenId].get(5),
            nature: _attributes[tokenId].get(8),
            size: 0 // _attributes[tokenId].get(14)
        });
        Stats memory stats = Stats({
            health: 50,
            attack: _attributes[tokenId].get(9),
            defense: _attributes[tokenId].get(10),
            special: _attributes[tokenId].get(11),
            resistance: _attributes[tokenId].get(12),
            speed: _attributes[tokenId].get(13)
        });
        Evo memory evo = Evo({
            tokenId: tokenId,
            species: _attributes[tokenId].get(0),
            generation: _attributes[tokenId].get(3),
            experience: _attributes[tokenId].get(7),
            attributes: attributes,
            stats: stats,
            breeds: Breeds(_attributes[tokenId].get(6), 0, 0),
            moves: Moves(0, 0, 0, 0)
        });
        return abi.encode(evo);
    }

    // The following functions are overrides required by Solidity.

    function tokensOfOwner(address owner) public view virtual
    override(ERC721EnumerableExtendedUpgradeable) returns(uint256[] memory) {
        return super.tokensOfOwner(owner);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    teamTransferCheck(from, to, tokenId)
    override(ERC721Upgradeable, ERC721EnumerableExtendedUpgradeable, ERC721BlacklistUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _exists(uint256 tokenId) internal view virtual
    override(ERC721Upgradeable) returns (bool) {
        return super._exists(tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721Upgradeable, IERC721Upgradeable) notBlacklisted(to) {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721Upgradeable, IERC721Upgradeable) notBlacklisted(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(
        IERC165Upgradeable,
        ERC721Upgradeable,
        ERC721EnumerableExtendedUpgradeable,
        AccessControlEnumerableUpgradeable,
        ERC721BlacklistUpgradeable
    )
    returns (bool) {
        return interfaceId == 0x9b9284f9 || super.supportsInterface(interfaceId);
    }
}