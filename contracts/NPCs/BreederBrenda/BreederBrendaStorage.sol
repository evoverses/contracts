// SPDX-License-Identifier: BUSL-1.0
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title BreederBrendaStorage
 */
abstract contract BreederBrendaStorage is Initializable {
  error InvalidRequestStatus();

  enum RequestStatus {
    INVALID,
    PENDING,
    APPROVED,
    DENIED
  }

  /// @custom:storage-location erc7201:evoverses.storage.BreederBrenda
  struct BreederBrendaStorageSlot {
    /// @notice evo ERC20 token used for breeding payments
    address evoToken;
    /// @notice evo ERC721 nft bred
    address evoNft;
    /// @notice evoverses treasury
    address treasury;
    /// @notice id of the request
    uint256 requestId;
    /// @notice request status map
    mapping(uint256 requestId => RequestStatus) requestStatus;
  }

  // keccak256(abi.encode(uint256(keccak256("evoverses.storage.BreederBrenda")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant BreederBrendaStorageLocation = 0x2a5d56c7913078c07dd3932545dd985c49f9f62a50a2553cdd89c34fe47a2c00;

  function __BreederBrendaStorage_init(address evoToken, address evoNft, address treasury) internal onlyInitializing {
    __BreederBrendaStorage_init_unchained(evoToken, evoNft, treasury);
  }

  function __BreederBrendaStorage_init_unchained(address evoToken, address evoNft, address treasury) internal onlyInitializing {
    BreederBrendaStorageSlot storage $ = _getBreederBrendaStorage();
    $.evoToken = evoToken;
    $.evoNft = evoNft;
    $.treasury = treasury;
  }

  function _getBreederBrendaStorage() private pure returns (BreederBrendaStorageSlot storage $) {
    assembly {
      $.slot := BreederBrendaStorageLocation
    }
  }

  function _getEvoToken() internal view returns (address) {
    return _getBreederBrendaStorage().evoToken;
  }

  function _getEvoNft() internal view returns (address) {
    return _getBreederBrendaStorage().evoNft;
  }

  function _getTreasury() internal view returns (address) {
    return _getBreederBrendaStorage().treasury;
  }

  function _setEvoToken(address evoToken) internal {
    BreederBrendaStorageSlot storage $ = _getBreederBrendaStorage();
    $.evoToken = evoToken;
  }

  function _setEvoNft(address evoNft) internal {
    BreederBrendaStorageSlot storage $ = _getBreederBrendaStorage();
    $.evoNft = evoNft;
  }

  function _setTreasury(address treasury) internal {
    BreederBrendaStorageSlot storage $ = _getBreederBrendaStorage();
    $.treasury = treasury;
  }

  function _getNextRequestId() internal returns (uint256) {
    BreederBrendaStorageSlot storage $ = _getBreederBrendaStorage();
    uint256 requestId = $.requestId;
    $.requestId++;
    return requestId;
  }

  function _setRequestStatus(uint256 requestId, RequestStatus status) internal {
    BreederBrendaStorageSlot storage $ = _getBreederBrendaStorage();
    RequestStatus rs = $.requestStatus[requestId];
    if (rs == RequestStatus.APPROVED || rs == RequestStatus.DENIED) {
      if (status != rs) revert InvalidRequestStatus();
    } else if (rs == RequestStatus.PENDING) {
      if (status != RequestStatus.APPROVED && status != RequestStatus.DENIED) {
        revert InvalidRequestStatus();
      }
    } else if (rs == RequestStatus.INVALID) {
      if (status != RequestStatus.PENDING) {
        revert InvalidRequestStatus();
      }
    }
    $.requestStatus[requestId] = status;
  }
}
