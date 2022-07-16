// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../ERC20/interfaces/IcEVOUpgradeable.sol";
import "../../ERC20/interfaces/IMintable.sol";

/**
* @title Migration Mike Ingress v1.0.0
* @author @DirtyCajunRice
*/
contract MigrationMikeIngressUpgradeable is Initializable, AccessControlUpgradeable, PausableUpgradeable {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    mapping (address => bool) public bridgeable;

    event BridgedToken(address indexed from, address indexed token, uint256 amount);
    event BridgedTokens(address indexed from, address[] indexed tokens, uint256[] amounts);
    event BridgedNFT(address indexed from, address indexed nft, uint256 id);
    event BridgedNFTs(address indexed from, address indexed nft, uint256[] ids);
    event BridgedDisbursement(address indexed from, uint256 startTime, uint256 duration, uint256 amount, uint256 balance);
    event BridgedTokenWithLocked(address indexed from, address indexed token, uint256 unlocked, uint256 locked);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __AccessControl_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
    }

    function bridgeToken(address to, address _token, uint256 _amount) public whenNotPaused onlyRole(RELAYER_ROLE) {
        require(bridgeable[_token], "Invalid token");
        require(_amount > 0, "Amount must be greater than zero");
        IMintable(_token).mint(to, _amount);

        emit BridgedToken(to, _token, _amount);
    }

    function batchBridgeToken(address to, address[] memory _tokens, uint256[] memory _amounts) public whenNotPaused onlyRole(RELAYER_ROLE) {
        require(_tokens.length > 0, "Missing tokens");
        require(_tokens.length == _amounts.length, "Tokens and amounts must match");

        for (uint256 i = 0; i < _tokens.length; i++) {
            require(bridgeable[_tokens[i]], "Invalid token");
            IMintable(_tokens[i]).mint(to, _amounts[i]);
        }

        emit BridgedTokens(to, _tokens, _amounts);
    }

    function bridgeNFT(address to, address _nft, uint256 _id) public whenNotPaused onlyRole(RELAYER_ROLE) {
        require(bridgeable[_nft], "Invalid asset");
        IMintable(_nft).mint(to, _id);
        emit BridgedNFT(to, _nft, _id);
    }

    function batchBridgeNFT(address to, address _nft, uint256[] memory _ids) public whenNotPaused onlyRole(RELAYER_ROLE) {
        require(bridgeable[_nft], "Invalid NFT");
        IMintable(_nft).batchMint(to, _ids);
        emit BridgedNFTs(to, _nft, _ids);
    }

    function bridgeCEVODisbursement(address to, uint256 startTime, uint256 duration, uint256 amount, uint256 balance) public whenNotPaused onlyRole(RELAYER_ROLE) {
        IcEVOUpgradeable cEVO = IcEVOUpgradeable(0x7B5501109c2605834F7A4153A75850DB7521c37E);
        cEVO.bridgeMintDisbursement(to, startTime, duration, amount, balance);
        emit BridgedDisbursement(to, startTime, duration, amount, balance);
    }

    function enableAsset(address _address) public onlyRole(ADMIN_ROLE) {
        bridgeable[_address] = true;
    }

    function disableAsset(address _address) public onlyRole(ADMIN_ROLE) {
        bridgeable[_address] = false;
    }

    function enabled(address _address) public view returns(bool) {
        return bridgeable[_address];
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}