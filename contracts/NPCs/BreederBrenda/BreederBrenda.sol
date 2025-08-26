// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";

import {IEvo} from "../../ERC721/Evo/IEvo.sol";
import {BreederBrendaStorage} from "./BreederBrendaStorage.sol";
/**
 * @title BreederBrenda
 * @notice Upgradable UUPS contract for breeding Evo NFTs using EVO ERC20 tokens as payment.
 *         Accepts breed requests by transferring EVO tokens and emitting events. Off-chain
 *         services validate breed rules and call mintApprovedBreed to mint new Evo NFTs.
 */
contract BreederBrenda is
Initializable,
PausableUpgradeable,
AccessManagedUpgradeable,
UUPSUpgradeable,
BreederBrendaStorage
{

  /// @notice Custom errors
  error ZeroAddress();
  error AsexualReproduction();
  error NotOwner(address account, uint256 tokenId);

  /// @notice Emitted when a breed request is submitted
  /// @param breeder Address of the breeder (msg.sender)
  /// @param nft Address of the NFT
  /// @param parent1 Token ID of the first parent
  /// @param parent2 Token ID of the second parent
  /// @param amountPaid Amount of EVO tokens transferred
  event BreedRequested(
    uint256 indexed requestId,
    address breeder,
    address nft,
    uint256 parent1,
    uint256 parent2,
    uint256 amountPaid
  );

  /// @notice Emitted when an approved breed is minted
  /// @param to Recipient of the newly minted Evo NFT
  /// @param nft Address of the NFT
  /// @param tokenId Token ID of the new Evo NFT
  /// @param mintedBy Address that executed the mint (caller)
  event BreedMinted(
    uint256 indexed requestId,
    address to,
    address nft,
    address mintedBy,
    uint256 tokenId
  );

  event BreedDenied(uint256 indexed requestId);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initialize the EvoBreeder contract
  function initialize() public initializer {
    __Pausable_init();
    __AccessManaged_init(0x204fc7955F816352afDe77D84e4e8719D2C28A0A);
    __UUPSUpgradeable_init();
    __BreederBrendaStorage_init(
      0x42006Ab57701251B580bDFc24778C43c9ff589A1,
      0x4151b8afa10653d304FdAc9a781AFccd45EC164c,
      0x9F64C4bECa7BBda647B9A755B29F7F9687bc4303
    );
  }

  /// @notice Request a breed by transferring EVO tokens and emitting an event
  /// @param parent1 Token ID of the first parent
  /// @param parent2 Token ID of the second parent
  /// @param amount Amount of EVO tokens to pay
  function requestBreed(
    uint256 parent1,
    uint256 parent2,
    uint256 amount
  ) external whenNotPaused {
    if (parent1 == parent2) revert AsexualReproduction();

    // Verify breeder owns both parents
    IERC721 nft = IERC721(_getEvoNft());
    if (nft.ownerOf(parent1) != msg.sender) revert NotOwner(msg.sender, parent1);
    if (nft.ownerOf(parent2) != msg.sender) revert NotOwner(msg.sender, parent2);

    // Transfer EVO tokens
    IERC20(_getEvoToken()).transferFrom(msg.sender, _getTreasury(), amount);
    uint256 requestId = _getNextRequestId();
    _setRequestStatus(requestId, RequestStatus.PENDING);

    emit BreedRequested(requestId, msg.sender, address(nft), parent1, parent2, amount);
  }

  /// @notice Mint a new Evo NFT after off-chain approval
  /// @param to Address to mint the Evo NFT to
  /// @param tokenId Token ID of the resulting nft
  function mintApprovedBreed(
    uint256 requestId,
    address to,
    uint256 tokenId
  ) external whenNotPaused restricted {
    if (to == address(0)) revert ZeroAddress();
    IEvo nft = IEvo(_getEvoNft());
    _setRequestStatus(requestId, RequestStatus.APPROVED);
    nft.mintTo(to, tokenId);
    emit BreedMinted(requestId, to, address(nft), msg.sender, tokenId);
  }

  function denyBreed(uint256 requestId) external whenNotPaused restricted {
    _setRequestStatus(requestId, RequestStatus.DENIED);
    emit BreedDenied(requestId);
  }

  function pause() external restricted {
    _pause();
  }

  function unpause() external restricted {
    _unpause();
  }

  function treasury() external view returns (address) {
    return _getTreasury();
  }

  function evoToken() external view returns (address) {
    return _getEvoToken();
  }

  function evoNft() external view returns (address) {
    return _getEvoNft();
  }

  /// @notice UUPS upgrade authorization with admin role
  /// @param newImplementation Address of the new implementation
  function _authorizeUpgrade(address newImplementation) internal override restricted {}

}
