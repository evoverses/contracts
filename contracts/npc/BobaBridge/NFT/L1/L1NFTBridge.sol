// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* Abstract Imports */
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../../../../utils/boba/CrossDomain/CrossDomainEnabled.sol";
import "../../../../utils/access/StandardAccessControl.sol";

/* Interface Imports */
import "../common/IStandardERC20.sol";
import "../common/IStandardERC1155.sol";
import "../common/IStandardERC721.sol";
import "../common/INFTBridge.sol";

/* Library Imports */
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

// add is interface
contract L1NFTBridge is Initializable, INFTBridge, CrossDomainEnabledBobaAvax, ReentrancyGuardUpgradeable,
PausableUpgradeable, StandardAccessControl {

    /********************************
     * External Contract References *
     ********************************/

    address public NFTBridge;
    uint256 public extraGasRelay;
    uint32 public exitGas;

    // Maps NFT address to NFTInfo
    mapping(address => PairNFTInfo) public pairNFTInfo;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __CrossDomainEnabled_init(0x0fc742332ae6D447d6619D93985Aa288B81CBb0C);
        NFTBridge = 0x0E1455D86920b399369a7C871be8d26F585af440;
        exitGas = 1400000;
        __Pausable_init();
        __ReentrancyGuard_init();
        __StandardAccessControl_init();
    }

    /**
     * @inheritdoc INFTBridge
     */
    function bridge(
        address nft,
        address to,
        uint256 tokenId,
        uint256 amount,
        NFTType nftType,
        uint32 gas
    ) external payable nonReentrant whenNotPaused {
        bytes memory extraData;
        if (nftType == NFTType.ERC1155) {
            extraData = IStandardERC1155(nft).bridgeExtraData(tokenId, amount);
        } else if (nftType == NFTType.ERC721) {
            extraData = IStandardERC721(nft).bridgeExtraData(tokenId);
        } else {
            extraData = "";
        }
        _initiateBridge(nft, msg.sender, to, tokenId, amount, gas, nftType, extraData);
    }

    /**
     * @dev Performs the logic for withdrawals by burning the token and informing the L2 NFT Gateway of the withdrawal.
     * @param nft Address of L1 where bridge was initiated.
     * @param from Account to bridge from on L1.
     * @param to Account to bridge to on L2.
     * @param tokenId ID of the token to withdraw.
     * @param amount Amount of the token to withdraw.
     * @param gas Unused, but included for potential forward compatibility considerations.
     * @param nftType Enum of NFT type
     * @param data Data/metadata to forward to L2. This data is extraBridgeData
     */
    function _initiateBridge(
        address nft,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint32 gas,
        NFTType nftType,
        bytes memory data
    ) internal {
        PairNFTInfo storage pairNFT = pairNFTInfo[nft];
        require(pairNFT.l2Nft != address(0), "NFTBridge::NFT is not configured for bridging");
        require(
            pairNFT.l2Nft == IStandardERC721(nft).bridgeContract(),
            "NFTBridge::L2 NFT contract address mismatch"
        );
        // When a withdrawal is initiated, we burn the NFT to prevent subsequent usage
        if (nftType == NFTType.ERC1155) {
            IStandardERC1155(nft).burn(msg.sender, tokenId, amount);
        } else if (nftType == NFTType.ERC721) {
            IStandardERC721(nft).burn(tokenId);
        } else {
            IStandardERC20(nft).burn(msg.sender, amount);
        }

        //  Construct calldata for NFTBridge.finalize and Send message down to L2 bridge
        sendCrossDomainMessage(
            NFTBridge,
            gas,
            abi.encodeWithSelector(
                INFTBridge.finalize.selector,
                pairNFT.l1Nft,
                pairNFT.l2Nft,
                from,
                to,
                tokenId,
                amount,
                nftType,
                data
            )
        );

        emit BridgeInitiated(pairNFT.l1Nft, pairNFT.l2Nft, from, to, tokenId, amount, nftType, data);
    }

    /*******************************************
     * Cross-chain Function: Finalizing Bridge *
     *******************************************/

    /**
     * @inheritdoc INFTBridge
     */
    function finalize(
        address l1Nft,
        address l2Nft,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        NFTType nftType,
        bytes memory data
    ) external virtual override onlyFromCrossDomainAccount(NFTBridge) {
        // Check the target token is compliant and
        // verify the bridged token on L2 matches the L1 bridged token representation here
        if (isBridgeCompliant(l1Nft, nftType) && pairNFTInfo[l1Nft].l2Nft == l2Nft) {
            // When a bridge is finalized, we credit the account on L1 with the same amount of tokens.
            if (nftType == NFTType.ERC721) {
                IStandardERC721(l1Nft).mint(to, tokenId, data);
            } else if (nftType == NFTType.ERC1155) {
                IStandardERC1155(l1Nft).mint(to, tokenId, amount, data);
            } else {
                IStandardERC20(l1Nft).mint(to, amount, data);
            }
            emit BridgeFinalized(l1Nft, l2Nft, from, to, tokenId, amount, nftType, data);
        } else {
            // Either the L1 token which is being bridged disagrees about the correct address
            // of its L2 token, or does not support the correct interface.
            // This should only happen if there is a  malicious L1 token, or if a user somehow
            // specified the wrong L1 token address to deposit into.
            // In either case, we stop the process here and construct a withdrawal
            // message so that users can get their funds out in some cases.
            // There is no way to prevent malicious token contracts altogether, but this does limit
            // user error and mitigate some forms of malicious contract behavior.

            // Send message down to L2 bridge
            sendCrossDomainMessage(
                NFTBridge,
                exitGas,
                abi.encodeWithSelector(
                    INFTBridge.finalize.selector,
                    l1Nft,
                    l2Nft,
                    to,   // switched the _to and _from here to bounce back the deposit to the sender
                    from,
                    tokenId,
                    amount,
                    nftType,
                    data
                )
            );
            emit BridgeFailed(l1Nft, l2Nft, from, to, tokenId, amount, nftType, data);
        }
    }

    /***
     * @dev Add the new NFT pair to the pool
     * DO NOT add the same NFT token more than once.
     *
     * @param l1Nft L1 NFT contract address
     * @param l2Nft L2 NFT contract address
     * @param nftType NFT contract type
     *
     */
    function registerNFTPair(address l1Nft, address l2Nft, NFTType nftType) external onlyAdmin {
        require(isBridgeCompliant(l1Nft, nftType), "NFTBridge::NFT is not bridgeable");
        // l2 NFT address equal to zero, then pair is not registered yet.
        PairNFTInfo storage pair = pairNFTInfo[l1Nft];
        require(pair.l2Nft == address(0), "NFTBridge::L2 NFT address already registered");
        pairNFTInfo[l1Nft] = PairNFTInfo(l1Nft, l2Nft, nftType);
    }

    function isBridgeCompliant(address nft, NFTType nftType) public view returns (bool) {
        if (nftType == NFTType.ERC721) {
            return ERC165CheckerUpgradeable.supportsInterface(nft, type(IStandardERC721).interfaceId);
        } else if (nftType == NFTType.ERC1155) {
            return ERC165CheckerUpgradeable.supportsInterface(nft, type(IStandardERC1155).interfaceId);
        } else {
            return ERC165CheckerUpgradeable.supportsInterface(nft, type(IStandardERC20).interfaceId);
        }
    }

    /**
     * @dev Update gas.
     *
     * @param _exitGas default finalized bridge L2 Gas
     */
    function updateGas(uint32 _exitGas) external onlyAdmin {
        require(_exitGas > 0, "NFTBridge::Exit Gas must be greater than 0");
        exitGas = _exitGas;
    }

    /**
     * @dev Update NFT Bridge
     *
     * @param _nftBridge L2 NFT bridge address
     */
    function updateNFTBridge(address _nftBridge) external onlyAdmin {
        require(_nftBridge != address(0), "NFTBridge::NFT Bridge cannot be zero address");
        NFTBridge = _nftBridge;
    }

    /******************
     *      Pause     *
     ******************/

    /**
     * Pause contract
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * UnPause contract
     */
    function unpause() external onlyAdmin {
        _unpause();
    }
}