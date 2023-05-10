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
import "./IL2BillingContract.sol";
import "../common/INFTBridge.sol";

/* Library Imports */
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

// add is interface
contract L2NFTBridge is Initializable, INFTBridge, CrossDomainEnabledBobaAvax, ReentrancyGuardUpgradeable,
PausableUpgradeable, StandardAccessControl {

    /********************************
     * External Contract References *
     ********************************/

    address public NFTBridge;
    uint256 public extraGasRelay;
    uint32 public exitGas;

    // Maps NFT address to NFTInfo
    mapping(address => PairNFTInfo) public pairNFTInfo;

    // billing contract address
    address public billingContract;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __CrossDomainEnabled_init(0x4200000000000000000000000000000000000007);
        NFTBridge = 0x18505CeC943EcB79999262c2dEb5127157c104CC;
        exitGas = 100000;
        billingContract = 0xc71411f3FDE3a34cDe5668cC4156841629321904;
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
    ) external payable override nonReentrant whenNotPaused {
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
     * @dev Performs the logic for withdrawals by burning the token and informing the L1 NFT Gateway
     * of the withdrawal.
     * @param nft Address of L2 NFT where bridge was initiated.
     * @param from Account to bridge from on L2.
     * @param to Account to bridge to on L1.
     * @param tokenId ID of the token to withdraw.
     * @param amount Amount of the token to withdraw.
     * @param gas Unused, but included for potential forward compatibility considerations.
     * @param nftType Enum of NFT type
     * @param data Data/metadata to forward to L1. This data is extraBridgeData
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
        // Load billingContract contract
        IL2BillingContract billing = IL2BillingContract(billingContract);
        uint256 exitFee = billing.exitFee();
        // Check Boba amount
        require(msg.value >= exitFee, "NFTBridge::Insufficient Boba amount");
        // Collect the exit fee
        billing.collectFee{value: exitFee}();

        PairNFTInfo storage pairNFT = pairNFTInfo[nft];
        require(pairNFT.l1Nft != address(0), "NFTBridge::NFT is not configured for bridging");
        require(
            pairNFT.l1Nft == IStandardERC721(nft).bridgeContract(),
            "NFTBridge::L1 NFT contract address mismatch"
        );
        // When a withdrawal is initiated, we burn the NFT to prevent subsequent usage
        if (nftType == NFTType.ERC1155) {
            IStandardERC1155(nft).burn(msg.sender, tokenId, amount);
        } else if (nftType == NFTType.ERC721) {
            IStandardERC721(nft).burn(tokenId);
        } else {
            IStandardERC20(nft).burn(msg.sender, amount);
        }

        //  Construct calldata for NFTBridge.finalize and Send message up to L1 bridge
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
        // verify the bridged token from L1 matches the L2 token representation here
        if (isBridgeCompliant(l2Nft, nftType) && pairNFTInfo[l2Nft].l1Nft == l1Nft) {
            // When a deposit is finalized, we credit the account on L2 with the same amount of
            // tokens.
            if (nftType == NFTType.ERC721) {
                IStandardERC721(l2Nft).mint(to, tokenId, data);
            } else if (nftType == NFTType.ERC1155) {
                IStandardERC1155(l2Nft).mint(to, tokenId, amount, data);
            } else {
                IStandardERC20(l2Nft).mint(to, amount, data);
            }
            emit BridgeFinalized(l1Nft, l2Nft, from, to, tokenId, amount, nftType, data);
        } else {
            // Either the L2 token which is being bridged-into disagrees about the correct address
            // of its L1 token, or does not support the correct interface.
            // This should only happen if there is a  malicious L2 token, or if a user somehow
            // specified the wrong L2 token address to bridge to.
            // In either case, we stop the process here and construct a withdrawal
            // message so that users can get their funds out in some cases.
            // There is no way to prevent malicious token contracts altogether, but this does limit
            // user error and mitigate some forms of malicious contract behavior.

            // Send message up to L1 bridge
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
        require(isBridgeCompliant(l2Nft, nftType), "NFTBridge::NFT is not bridgeable");
        // l1 NFT address equal to zero, then pair is not registered yet.
        PairNFTInfo storage pair = pairNFTInfo[l2Nft];
        require(pair.l1Nft == address(0), "NFTBridge::L1 NFT address already registered");
        pairNFTInfo[l2Nft] = PairNFTInfo(l1Nft, l2Nft, nftType);
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
     * @param _exitGas default finalized bridge L1 Gas
     */
    function updateGas(uint32 _exitGas) external onlyAdmin {
        require(_exitGas > 0, "NFTBridge::Exit Gas must be greater than 0");
        exitGas = _exitGas;
    }

    /**
     * @dev Update billing contract address.
     *
     * @param _billingContract billing contract address
     */
    function updateBillingContract(address _billingContract) external onlyAdmin {
        require(_billingContract != address(0), "NFTBridge::Billing contract cannot be zero address");
        billingContract = _billingContract;
    }

    /**
     * @dev Update NFT Bridge
     *
     * @param _nftBridge L1 NFT bridge address
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