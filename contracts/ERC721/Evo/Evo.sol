// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.20;

import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {ERC721PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import {ERC721BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {ERC721RoyaltyUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC4906, IERC165} from "@openzeppelin/contracts/interfaces/IERC4906.sol";

/// @custom:security-contact security@evoverses.com
contract Evo is
Initializable,
ERC721Upgradeable,
ERC721EnumerableUpgradeable,
ERC721PausableUpgradeable,
AccessManagedUpgradeable,
ERC721BurnableUpgradeable,
ERC721RoyaltyUpgradeable,
IERC4906,
UUPSUpgradeable
{

  uint256 private _nextTokenId;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  error InvalidTokenId(uint256 tokenId, uint256 nextTokenId);

  function initialize() initializer public {
    __ERC721_init("Evo", "Evo");
    __ERC721Enumerable_init();
    __ERC721Pausable_init();
    __AccessManaged_init(0x204fc7955F816352afDe77D84e4e8719D2C28A0A);
    __ERC721Burnable_init();
    __ERC721Royalty_init();
    __UUPSUpgradeable_init();

    _nextTokenId = 5109;
  }

  function _baseURI() internal pure override returns (string memory) {
    return "https://api.evoverses.com/metadata/evo/";
  }

  function contractURI() external pure returns (string memory) {
    return "https://api.evoverses.com/metadata/evo";
  }

  function pause() public restricted {
    _pause();
  }

  function unpause() public restricted {
    _unpause();
  }

  function mintNew(address to) public restricted {
    uint256 tokenId = _nextTokenId++;
    _safeMint(to, tokenId);
  }

  function batchMintNew(address[] calldata to) public restricted {
    for (uint256 i = 0; i < to.length; i++) {
      uint256 tokenId = _nextTokenId++;
      _safeMint(to[i], tokenId);
    }
  }

  function mintTo(address to, uint256 tokenId) public restricted {
    if (tokenId >= _nextTokenId) revert InvalidTokenId(tokenId, _nextTokenId);
    _safeMint(to, tokenId);
  }

  function batchMintTo(address[] calldata to, uint256[] calldata tokenIds) public restricted {
    for (uint i = 0; i < to.length; i++) {
      if (tokenIds[i] >= _nextTokenId) revert InvalidTokenId(tokenIds[i], _nextTokenId);
      _safeMint(to[i], tokenIds[i]);
    }
  }

  function adminTransfer(address[] calldata from, address[] calldata to, uint256[] calldata tokenIds) external restricted {
    for (uint i = 0; i < to.length; i++) {
      _safeTransfer(from[i], to[i], tokenIds[i]);
    }
  }

  function requestMetadataUpdate(uint256 _tokenId) external {
    emit MetadataUpdate(_tokenId);
  }

  function requestBatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId) external {
    emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
  }

  function _authorizeUpgrade(address newImplementation) internal restricted override {}

  // The following functions are overrides required by Solidity.

  function _update(address to, uint256 tokenId, address auth) internal override(
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  ERC721PausableUpgradeable
  )
  returns (address)
  {
    return super._update(to, tokenId, auth);
  }

  function _increaseBalance(address account, uint128 value) internal override(
  ERC721Upgradeable, ERC721EnumerableUpgradeable
  ) {
    super._increaseBalance(account, value);
  }

  function supportsInterface(bytes4 interfaceId) public view override(
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  ERC721RoyaltyUpgradeable,
  IERC165
  ) returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
