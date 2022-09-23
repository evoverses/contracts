// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title ERC721 L2 Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
interface IERC721L1 is IERC721Upgradeable {
    function l2Contract() external returns (address);

    function bridgeExtraData(uint256 tokenId) external returns(bytes memory);
}