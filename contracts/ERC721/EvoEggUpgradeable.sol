// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./extensions/ERC721EnumerableExtendedUpgradeable.sol";
import "./extensions/ERC721BlacklistUpgradeable.sol";
import "../ERC20/interfaces/IcEVOUpgradeable.sol";
import "../deprecated/OldTokenConstants.sol";

/**
* @title Evo Egg v1.0.0
* @author @DirtyCajunRice
*/
contract EvoEggUpgradeable is Initializable, ERC721Upgradeable, ERC721EnumerableExtendedUpgradeable, PausableUpgradeable,
AccessControlEnumerableUpgradeable, OldTokenConstants, ERC721BlacklistUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using StringsUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdCounter;

    IcEVOUpgradeable private EVO;
    IcEVOUpgradeable private cEVO;

    address private treasury;

    uint256 public cap;

    uint256 private startTime;
    uint256 private unlockedPrice;
    uint256 private lockedPrice;
    uint256 private treatPrice;

    uint256 private _evoSpent;
    uint256 private _evoTreatedSpent;
    uint256 private _cEvoSpent;

    CountersUpgradeable.Counter private _unlockedMinted;
    CountersUpgradeable.Counter private _lockedMinted;
    CountersUpgradeable.Counter private _eggsTreated;

    string public imageBaseURI;

    mapping(address => uint256) public lockedMintsRemaining;
    mapping(uint256 => bool) private _treated;

    event PricesUpdated(uint256 unlocked, uint256 locked, uint256 treat);
    event EggTreated(address indexed from, uint256 indexed tokenId);
    event EggMinted(address indexed from, uint256 indexed tokenId, bool withLocked);

    modifier teamTransferCheck(address from, address to, uint256 tokenId) {
        address teamProxyWallet = 0x2F52Abfca2074b99759b58345Bb984419D304243;
        require(
            tokenId > 50
            || from == address(0)
            || to == address(0)
            || from == teamProxyWallet // Team proxy wallet
            || to == teamProxyWallet
            || from == treasury
            || to == treasury
        ,"Team Eggs are non-transferable"
        );
        _;
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("Evo Egg Gen0", "EVOEGGGEN0");
        __ERC721EnumerableExtended_init();
        __ERC721Blacklist_init();
        __Pausable_init();
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        treasury = 0x39Af60141b91F7941Eb13AedA2124a61a953b7C0;
        EVO = IcEVOUpgradeable(0x42006Ab57701251B580bDFc24778C43c9ff589A1);
        cEVO =IcEVOUpgradeable(0x7B5501109c2605834F7A4153A75850DB7521c37E);
        cap = 3050;
        startTime = 1657303200;
        if (_tokenIdCounter.current() == 0) {
            _tokenIdCounter.increment();
        }
    }

    function mint() public nonReentrant whenNotPaused {
        EVO.transferFrom(_msgSender(), treasury, unlockedPrice);
        _evoSpent += unlockedPrice;
        _unlockedMinted.increment();
        safeMint(_msgSender());
    }

    function mintLocked() public nonReentrant whenNotPaused {
        require(lockedMintsRemaining[_msgSender()] < 2, "No locked mints remaining");
        lockedMintsRemaining[_msgSender()]++;
        cEVO.useLocked(_msgSender(), lockedPrice);
        _cEvoSpent += lockedPrice;
        _lockedMinted.increment();
        safeMint(_msgSender());
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        require(startTime <= block.timestamp, "Mint has not started yet");
        require(tokenId <= cap, "Sold out");

        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function treat(uint256 tokenId) public onlyRole(ADMIN_ROLE) {
        require(ownerOf(tokenId) == _msgSender(), "Not owner");
        require(!_treated[tokenId], "Egg already treated!");
        EVO.transferFrom(_msgSender(), treasury, treatPrice);
        _treated[tokenId] = true;
        _evoTreatedSpent += treatPrice;
        _eggsTreated.increment();
        emit EggTreated(_msgSender(), tokenId);
    }

    function hatch(address spender, uint256[] memory tokenIds) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_isApprovedOrOwner(spender, tokenIds[i]), "Not approved or owner");
            _burn(tokenIds[i]);
        }
    }
    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable) returns (string memory) {
        string memory imageURI = string(abi.encodePacked(imageBaseURI, (tokenId % 4).toString(), '.png'));
        string memory animationURI = string(abi.encodePacked(imageBaseURI, (tokenId % 4).toString(), '.webm'));
        bytes memory dataURIGeneral = abi.encodePacked(
            '"name": "Evo Egg #', tokenId.toString(), '", ',
            '"description": "EvoVerses Gen0 Egg", ',
            '"image": "', imageURI, '", ',
            '"animation_url": "', animationURI, '", ',
            '"animation_type": "webm/mp4", '
        );

        string memory staffAttribute = string(abi.encodePacked(tokenId <= 50 ? '{"value": "staff"},' : ''));
        string memory treatedAttribute = _treated[tokenId]
        ? string(abi.encodePacked('{"value": "treated"},'))
        : '';

        bytes memory dataURIAttributes = abi.encodePacked(
            '"attributes": [',
                staffAttribute,
                treatedAttribute,
                '{"trait_type": "generation", "display_type": "number", "value": 0}',
            ']'
        );

        bytes memory dataURI = abi.encodePacked('{', string(dataURIGeneral), string(dataURIAttributes), '}');

        return string(abi.encodePacked("data:application/json;base64,", Base64Upgradeable.encode(dataURI)));
    }

    function batchTokenURI(uint256[] memory tokenIds) public view returns(string[] memory) {
        string[] memory uris = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uris[i] = tokenURI(tokenIds[i]);
        }
        return uris;
    }

    function batchTransferFrom(address from, address to, uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            transferFrom(from, to, tokenIds[i]);
        }
    }

    function getMintCounts() public view returns (uint256 unlocked, uint256 locked, uint256 treated) {
        unlocked = _unlockedMinted.current();
        locked = _lockedMinted.current();
        treated = _eggsTreated.current();
    }

    function getMintValues() public view returns (uint256 unlocked, uint256 locked, uint256 treated) {
        unlocked = _evoSpent;
        locked = _cEvoSpent;
        treated = _evoTreatedSpent;
    }

    function getMintPrices() public view returns (uint256 unlocked, uint256 locked, uint256 treated) {
        unlocked = unlockedPrice;
        locked = lockedPrice;
        treated = treatPrice;
    }

    function checkTreated(uint256[] memory tokenIds) public view returns(bool[] memory) {
        bool[] memory treated = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            treated[i] = _treated[tokenIds[i]];
        }
        return treated;
    }
    // Admin

    function setStartTime(uint256 time) public onlyRole(ADMIN_ROLE) {
        startTime = time;
    }

    function setPrices(uint256 dollarOfEvo) public onlyRole(ADMIN_ROLE) {
        unlockedPrice = dollarOfEvo * 200;
        lockedPrice = dollarOfEvo * 800;
        treatPrice = dollarOfEvo * 10;
    }

    function setCap(uint256 _cap) public onlyRole(ADMIN_ROLE) {
        cap = _cap;
    }

    function setImageBaseUri(string memory imageBaseUri) public onlyRole(ADMIN_ROLE) {
        imageBaseURI = imageBaseUri;
    }

    function lastMinted() public view returns(uint256) {
        return _tokenIdCounter.current() - 1;
    }

    function updateAttribute(uint256[] memory tokenIds) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (!_treated[tokenIds[i]]) {
                _treated[tokenIds[i]] = true;
                _eggsTreated.increment();
                emit EggTreated(_msgSender(), tokenIds[i]);
            }
        }
    }

    function transferTeamEgg(address from, address to, uint256 tokenId) public onlyRole(ADMIN_ROLE) {
        require(tokenId <= 50);
        _transfer(from, to, tokenId);
    }

    function transferTeamEggs(address from, address to, uint256[] memory tokenIds) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] <= 50);
            _transfer(from, to, tokenIds[i]);
        }
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
    teamTransferCheck(from, to, tokenId)
    override(ERC721Upgradeable, ERC721EnumerableExtendedUpgradeable, ERC721BlacklistUpgradeable)
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
        ERC721BlacklistUpgradeable
    )
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}