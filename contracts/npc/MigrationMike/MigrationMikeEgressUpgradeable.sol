// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../ERC20/interfaces/IcEVOUpgradeable.sol";
import "../../ERC20/interfaces/IMintable.sol";

/**
* @title Migration Mike Egress v1.1.0
* @author @DirtyCajunRice
*/
contract MigrationMikeEgressUpgradeable is Initializable, AccessControlUpgradeable,
ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    address private constant _BURN_ADDRESS = 0x0000000000000000000000000000000000000001;

    mapping (address => bool) public bridgeable;

    bool private maintenanceMode;

    EnumerableSetUpgradeable.AddressSet private burnable;

    event BridgedToken(address indexed from, address indexed token, uint256 amount);
    event BridgedTokens(address indexed from, address[] indexed tokens, uint256[] amounts);
    event BridgedNFT(address indexed from, address indexed nft, uint256 id);
    event BridgedNFTs(address indexed from, address[] indexed nfts, uint256[] ids);
    event BridgedDisbursement(address indexed from, uint256 startTime, uint256 duration, uint256 amount, uint256 balance);

    modifier whenNotInMaintenance() {
        require(!maintenanceMode || hasRole(ADMIN_ROLE, _msgSender()), "Maintenance Mode");
        _;
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
    }

    function bridgeToken(address _token, uint256 _amount) public whenNotPaused nonReentrant whenNotInMaintenance {
        require(bridgeable[_token], "Invalid token");
        require(_amount > 0, "Amount must be greater than zero");
        if (burnable.contains(_token)) {
            IMintable(_token).burn(_msgSender(), _amount);
        } else {
            IERC20Upgradeable(_token).safeTransferFrom(_msgSender(), _BURN_ADDRESS, _amount);
        }
        emit BridgedToken(_msgSender(), _token, _amount);
    }

    function batchBridgeToken(address[] memory _tokens, uint256[] memory _amounts) public
    whenNotPaused nonReentrant whenNotInMaintenance {
        require(_tokens.length > 0, "Missing tokens");
        require(_tokens.length == _amounts.length, "Tokens and amounts must match");

        for (uint256 i = 0; i < _tokens.length; i++) {
            require(bridgeable[_tokens[i]], "Invalid token");
            require(_amounts[i] > 0, "Amount must be greater than zero");
            if (burnable.contains(_tokens[i])) {
                IMintable(_tokens[i]).burn(_msgSender(), _amounts[i]);
            } else {
                IERC20Upgradeable(_tokens[i]).safeTransferFrom(_msgSender(), _BURN_ADDRESS, _amounts[i]);
            }
        }

        emit BridgedTokens(_msgSender(), _tokens, _amounts);
    }

    function bridgeNFT(address _nft, uint256 _id) public whenNotPaused nonReentrant whenNotInMaintenance {
        require(bridgeable[_nft], "Invalid asset");
        IERC721Upgradeable nft = IERC721Upgradeable(_nft);
        nft.safeTransferFrom(_msgSender(), _BURN_ADDRESS, _id);
        emit BridgedNFT(_msgSender(), _nft, _id);
    }

    function batchBridgeNFT(address[] memory _nfts, uint256[] memory _ids) public
    whenNotPaused nonReentrant whenNotInMaintenance {
        require(_nfts.length > 0, "Missing NFTs");
        require(_nfts.length == _ids.length, "NFTs and ids must match");

        for (uint256 i = 0; i < _nfts.length; i++) {
            require(bridgeable[_nfts[i]], "Invalid NFT");
            IERC721Upgradeable nft = IERC721Upgradeable(_nfts[i]);
            nft.safeTransferFrom(_msgSender(), _BURN_ADDRESS, _ids[i]);
        }

        emit BridgedNFTs(_msgSender(), _nfts, _ids);
    }

    function bridgeCEVODisbursement() public {
        IcEVOUpgradeable cEVO = IcEVOUpgradeable(0x465d89df3e9B1AFB6957B58Be6137feeBB8e9f61);
        uint256 startTime;
        uint256 duration;
        uint256 amount;
        uint256 balance;
        (startTime, duration, amount, balance) = cEVO.disbursementOf(_msgSender());
        cEVO.removeDisbursement(_msgSender(), 0);
        emit BridgedDisbursement(_msgSender(), startTime, duration, amount, balance);

    }

    function enableAsset(address _address) public onlyRole(ADMIN_ROLE) {
        bridgeable[_address] = true;
    }

    function disableAsset(address _address) public onlyRole(ADMIN_ROLE) {
        bridgeable[_address] = false;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function startMaintenance() public onlyRole(ADMIN_ROLE) {
        maintenanceMode = true;
    }

    function finishMaintenance() public onlyRole(ADMIN_ROLE) {
        maintenanceMode = false;
    }

    function addBurnable(address _address) public onlyRole(ADMIN_ROLE) {
        burnable.add(_address);
    }

    function removeBurnable(address _address) public onlyRole(ADMIN_ROLE) {
        burnable.remove(_address);
    }
}