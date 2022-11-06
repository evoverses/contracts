// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title INFTBridge
 */
interface INFTBridge {

    enum NFTType { ERC1155, ERC721 }

    // Info of each NFT
    struct PairNFTInfo {
        address l1Nft;
        address l2Nft;
        NFTType nftType; // ERC1155 or ERC721
    }

    // add events
    event BridgeInitiated (
        address indexed l1Nft,
        address indexed l2Nft,
        address indexed from,
        address to,
        uint256 tokenId,
        uint256 amount,
        NFTType nftType,
        bytes data
    );

    event BridgeFinalized (
        address indexed l1Token,
        address indexed l2Token,
        address indexed from,
        address to,
        uint256 tokenId,
        uint256 amount,
        NFTType nftType,
        bytes data
    );

    event BridgeFailed (
        address indexed l1Token,
        address indexed l2Token,
        address indexed from,
        address to,
        uint256 tokenId,
        uint256 amount,
        NFTType nftType,
        bytes data
    );

    function bridge(address nft, address to, uint256 tokenId, uint256 amount, NFTType nftType, uint32 gas) external;
    function finalize(
        address l1Nft,
        address l2Nft,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        NFTType nftType,
        bytes calldata data
    ) external;
}