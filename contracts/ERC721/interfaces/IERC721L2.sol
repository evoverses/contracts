// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title ERC721 L2 Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
interface IERC721L2 is IERC721Upgradeable {
    function l1Contract() external returns (address);

    function mint(address _to, uint256 _tokenId, bytes memory _data) external;

    function burn(uint256 _tokenId) external;

    function bridgeExtraData(uint256 tokenId) external returns(bytes memory);
}