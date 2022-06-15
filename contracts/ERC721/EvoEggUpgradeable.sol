// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "../ERC20/IEvoToken.sol";

/**
* @title Evo Egg v1.0.0
* @author @DirtyCajunRice
*/
contract EvoEggUpgradeable is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable,
PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using StringsUpgradeable for uint256;

    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    address private constant _BURN_ADDRESS = 0x0000000000000000000000000000000000000001;

    CountersUpgradeable.Counter private _tokenIdCounter;

    EnumerableSetUpgradeable.UintSet private result0;
    EnumerableSetUpgradeable.UintSet private result1;
    EnumerableSetUpgradeable.UintSet private result2;

    IEvoToken private EVO;

    address public treasuryAddress;

    uint256 public cap;

    uint256 private startTime;
    uint256 private unlockedPrice;
    uint256 private lockedPrice;

    uint256 private basisPoints;
    uint256 private result0Points;
    uint256 private result1Points;

    string public imageBaseURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    function initialize() public initializer {
        __ERC721_init("ElvesTicket", "ETICKET");
        __ERC721Enumerable_init();
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CONTRACT_ROLE, msg.sender);
        _grantRole(UPDATER_ROLE, msg.sender);

        treasuryAddress = address(0xE8D94E683338ba3Fa3b36C4FF2401Bc5772Db67f);

        if (_tokenIdCounter.current() == 0) {
            _tokenIdCounter.increment();
        }
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        require(startTime >= block.timestamp, "Mint has not started yet");
        require(tokenId < cap, "Sold out");

        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        processMinted(tokenId);
    }

    function mint(address to, bool useLocked) public nonReentrant whenNotPaused {
        uint256 price = useLocked ? lockedPrice : unlockedPrice;
        uint256 balance = useLocked ? EVO.balanceOf(_msgSender()) : EVO.lockOf(_msgSender());
        address destination = useLocked ? _BURN_ADDRESS : treasuryAddress;
        require(EVO.allowance(_msgSender(), address(this)) >= price, "Insufficient EVO allowance");
        require(balance >= price, "Insufficient balance");
        if (useLocked) {
            EVO.unlockForUser(_msgSender(), lockedPrice);
        }
        EVO.transferFrom(_msgSender(), destination, price);
        safeMint(to);
    }

    function batchMint(address to, uint256 amount) public {
        for (uint256 i = 0; i < amount; i++) {
            mint(to, false);
        }
    }

    function processMinted(uint256 tokenId) internal {
        bytes32 randBase = vrf();
        uint256 rand = uint256(keccak256(abi.encodePacked(randBase, tokenId, block.number, block.timestamp)));
        uint256 outcome = rand % basisPoints;
        if (outcome >= result0Points) {
            result0.add(tokenId);
        } else if (outcome >= result1Points && outcome < result0Points) {
            result1.add(tokenId);
        } else {
            result2.add(tokenId);
        }
    }

    function resultOf(uint256 tokenId) public view returns(uint256 result) {
        require(super._exists(tokenId), "Discount query for nonexistent token");
        require(_tokenIdCounter.current() == cap, "Minting is still live");
        if (result0.contains(tokenId)) {
            return 0;
        } else if (result1.contains(tokenId)) {
            return 1;
        } else {
            return 2;
        }
    }

    function batchResultOf(uint256[] memory tokenIds) public view returns(uint256[] memory results) {
        results = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            results[i] = resultOf(tokenIds[i]);
        }
        return results;
    }

    function tokensOfOwner(address _address) public view returns(uint256[] memory) {
        uint256 total = super.balanceOf(_address);
        uint256[] memory tokens = new uint256[](total);
        for (uint256 i = 0; i < total; i++) {
            tokens[i] = super.tokenOfOwnerByIndex(_address, i);
        }
        return tokens;
    }

    //function tokensAndResultsOfOwner(address _address) public view
    //returns(uint256[] memory tokens, uint256[] memory results) {
    //    return (tokensOfOwner(_address), batchResultOf(_address));
//
    //}

    //function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //    uint256 discount = discountOf(tokenId);
    //    string memory discountStr = _tokenIdCounter.current() == totalTickets
    //    ? string(abi.encodePacked(discount.toString(), '%'))
    //    : "pending";
    //    string memory imageURI = string(abi.encodePacked(imageBaseURI, discount.toString()));
    //    bytes memory dataURI = abi.encodePacked(
    //        '{',
    //          '"name": "Evo Egg #', tokenId.toString(), '",',
    //          '"image": "', imageURI, '",',
    //          '"attributes": [',
    //            '{',
    //              '"trait_type": "discount",',
    //              '"value": "',  discountStr, '"',
    //            '}',
    //          ']'
    //        '}'
    //    );
    //    return string(
    //        abi.encodePacked(
    //            "data:application/json;base64,",
    //            Base64Upgradeable.encode(dataURI)
    //        )
    //    );
    //}

    // Admin

    function setStartTime(uint256 time) public onlyRole(UPDATER_ROLE) {
        startTime = time;
    }

    function setPrices(uint256 unlocked, uint256 locked) public onlyRole(UPDATER_ROLE) {
        unlockedPrice = unlocked;
        lockedPrice = locked;
    }

    function setCap(uint256 _cap) public onlyRole(UPDATER_ROLE) {
        cap = _cap;
    }

    function vrf() internal view returns (bytes32 result) {
        uint[1] memory bn;
        bn[0] = block.number;
        assembly {
            let memPtr := mload(0x40)
            if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
                invalid()
            }
            result := mload(memPtr)
        }
    }

    /**
    * @notice Pause token upgrades and transfers
    *
    * @dev Allows the owner of the contract to stop the execution of
    *      upgradeAll and transferFrom functions
    */
    function pause() external onlyRole(UPDATER_ROLE) {
        _pause();
    }

    /**
    * @notice Unpause token upgrades and transfers
    *
    * @dev Allows the owner of the contract to resume the execution of
    *      upgradeAll and transferFrom functions
    */
    function unpause() external onlyRole(UPDATER_ROLE) {
        _unpause();
    }

    // Overrides

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}