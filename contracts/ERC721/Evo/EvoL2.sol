// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "../extensions/ERC721EnumerableExtendedUpgradeable.sol";
import "../extensions/ERC721BurnableUpgradeable.sol";
import "../extensions/ERC721URITokenJSON.sol";
import "../extensions/ERC721Blacklist.sol";
import "../extensions/ERC721L2.sol";
import "../interfaces/IEvo.sol";
import "./AttributeStorage.sol";

/**
* @title Evo (L2) v1.0.0
* @author @DirtyCajunRice
*/
contract EvoL2 is Initializable, ERC721Upgradeable, ERC721EnumerableExtendedUpgradeable,
PausableUpgradeable, AccessControlEnumerableUpgradeable, ERC721BurnableUpgradeable, TokenConstants,
ERC721Blacklist, ERC721URITokenJSON, AttributeStorage, ERC721L2 {
    using StringsUpgradeable for uint256;

    modifier teamTransferCheck(address from, address to, uint256 tokenId) {
        address bridge = 0x1A0245f23056132fEcC7098bB011C5C303aE0625;
        require(
            tokenId > 50
            || from == address(0)
            || to == address(0)
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
        __ERC721URITokenJSON_init(
            "https://github.com/EvoVerses/public-assets/raw/main/nfts/Evo/",
            "https://github.com/EvoVerses/public-assets/raw/main/nfts/Evo/"
        );
        __AttributeStorage_init();
        __ERC721L2_init(0x454a0E479ac78e508a95880216C06F50bf3C321C);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(CONTRACT_ROLE, _msgSender());
        _grantRole(BRIDGE_ROLE, _msgSender());
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function mint(address _address, EvoStructs.Evo memory evo) public onlyRole(MINTER_ROLE) {
        _setEvoAttributes(evo);
        _safeMint(_address, evo.tokenId);
        _removeBurnedId(evo.tokenId);
    }

    function batchMint(address _address, EvoStructs.Evo[] memory evos) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < evos.length; i++) {
            _setEvoAttributes(evos[i]);
            _safeMint(_address, evos[i].tokenId);
            _removeBurnedId(evos[i].tokenId);
        }
    }

    // ERC721L2
    function mint(address to, uint256 tokenId, bytes memory _data) public override(ERC721L2) onlyRole(BRIDGE_ROLE) {
        (EvoStructs.Evo memory evo) = abi.decode(_data, (EvoStructs.Evo));
        _setEvoAttributes(evo);
        _safeMint(to, tokenId);
        _removeBurnedId(tokenId);
    }

    function burn(uint256 tokenId) public override(ERC721L2, ERC721BurnableUpgradeable) {
        bool allowed = _isApprovedOrOwner(_msgSender(), tokenId) || hasRole(BRIDGE_ROLE, _msgSender());
        require(allowed, "ERC721: caller is not token owner nor approved");
        _addBurnedId(tokenId);
        super._burn(tokenId);
    }

    function bridgeExtraData(uint256 tokenId) public view override(ERC721L2) returns(bytes memory) {
        EvoStructs.Evo memory evo = getEvoAttributes(tokenId);
        return abi.encode(evo);
    }

    function getEvo(uint256 tokenId) public view returns(EvoStructs.Evo memory) {
        return getEvoAttributes(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URITokenJSON, ERC721Upgradeable) returns(string memory) {
        uint256 speciesId = getAttribute(tokenId, 0);
        string memory name = getAttributeString(0, speciesId);
        uint256 attributeCount = 16;
        Attribute[] memory attributes = new Attribute[](attributeCount);

        for (uint256 i = 0; i < attributeCount; i++) {
            attributes[i] = Attribute(getAttributeString(999, i), '', getAttribute(tokenId, i).toString(), true);
        }

        return _makeJSON(tokenId, name, 'EvoVerses Evo', attributes);
    }
    function setImageBaseURI(string memory _imageBaseURI) public onlyRole(ADMIN_ROLE) {
        _setImageBaseURI(_imageBaseURI);
    }

    function setAnimationBaseURI(string memory _animationBaseURI) public onlyRole(ADMIN_ROLE) {
        _setAnimationBaseURI(_animationBaseURI);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    notBlacklisted(from)
    notBlacklisted(to)
    teamTransferCheck(from, to, tokenId)
    override(ERC721Upgradeable, ERC721EnumerableExtendedUpgradeable, ERC721Blacklist)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override notBlacklisted(to) {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override notBlacklisted(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(
    ERC721Upgradeable,
    ERC721EnumerableExtendedUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721Blacklist,
    ERC721L2
    )
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}