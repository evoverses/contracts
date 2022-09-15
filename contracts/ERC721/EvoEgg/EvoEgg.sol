// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "../extensions/ERC721EnumerableExtendedUpgradeable.sol";
import "../../utils/constants/TokenConstants.sol";
import "../extensions/ERC721URITokenJSON.sol";
import "../extensions/ERC721Blacklist.sol";
import "./EggAttributeStorage.sol";
import "./IEvoEgg.sol";

/**
* @title Evo Egg v2.0.0
* @author @DirtyCajunRice
*/
contract EvoEgg is Initializable, ERC721Upgradeable, ERC721EnumerableExtendedUpgradeable, PausableUpgradeable,
AccessControlEnumerableUpgradeable, TokenConstants, ERC721Blacklist, IEvoEgg, EggAttributeStorage, ERC721URITokenJSON {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("Evo Egg", "EVOEGG");
        __ERC721EnumerableExtended_init();
        __ERC721Blacklist_init();
        __Pausable_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        if (_tokenIdCounter.current() <= 3050) {
            _tokenIdCounter._value = 3051;
        }
    }

    function incubate(address to, Egg memory egg) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        egg.tokenId = tokenId;
        _setEggAttributes(egg);
    }

    function hatch(uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URITokenJSON, ERC721Upgradeable) returns(string memory) {
        uint256 speciesId = getAttribute(tokenId, 0);
        string memory name = getAttributeString(0, speciesId);
        uint256 attributeCount = 5;
        Attribute[] memory attributes = new Attribute[](attributeCount);
        for (uint256 i = 0; i < attributeCount; i++) {
            attributes[i] = Attribute(getAttributeString(0, i), '', getAttribute(tokenId, i).toString(), true);
        }

        return _makeJSON(tokenId, name, 'EvoVerses Egg', attributes);
    }
    function setImageBaseURI(string memory _imageBaseURI) public onlyRole(ADMIN_ROLE) {
        _setImageBaseURI(_imageBaseURI);
    }

    function getEgg(uint256 tokenId) public view returns (Egg memory egg) {
        require(_exists(tokenId), "Non-existent token");
        return _getEggAttributes(tokenId);
    }

    function checkTreated(uint256[] memory tokenIds) public view returns(bool[] memory) {
        bool[] memory treated = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            treated[i] = getAttribute(tokenIds[i], 4) == 1;
        }
        return treated;
    }

    /**
    * @notice Pause token upgrades and transfers
    *
    * @dev Allows the owner of the contract to stop the execution of
    *      upgradeAll and transferFrom functions
    */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
    * @notice Unpause token upgrades and transfers
    *
    * @dev Allows the owner of the contract to resume the execution of
    *      upgradeAll and transferFrom functions
    */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Overrides

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721Upgradeable, ERC721EnumerableExtendedUpgradeable, ERC721Blacklist)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(
    ERC721Upgradeable,
    ERC721EnumerableExtendedUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721Blacklist
    )
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}