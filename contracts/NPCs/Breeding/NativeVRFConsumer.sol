// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @dev Native-payment subset of Chainlink's IVRFV2PlusWrapper, contracts-v1.4.0.
/// ABI source: https://github.com/smartcontractkit/chainlink-evm/blob/contracts-v1.4.0/contracts/src/v0.8/vrf/dev/interfaces/IVRFV2PlusWrapper.sol
interface INativeVRFWrapper {
    function calculateRequestPriceNative(uint32 callbackGasLimit, uint32 numWords) external view returns (uint256);
    function estimateRequestPriceNative(uint32 callbackGasLimit, uint32 numWords, uint256 gasPriceWei)
        external view returns (uint256);
    function requestRandomWordsInNative(uint32 callbackGasLimit, uint16 confirmations, uint32 numWords, bytes calldata extraArgs)
        external payable returns (uint256);
}

/// @notice Direct funding: each user pays the wrapper's current native-token quote.
/// No admin can replace the wrapper or overwrite/re-request a committed random result.
abstract contract NativeVRFConsumer is AccessManaged, Pausable, ReentrancyGuard {
    struct Randomness { bool requested; bool fulfilled; uint256 word; }
    INativeVRFWrapper public immutable vrfWrapper;
    uint16 public immutable requestConfirmations;
    uint32 public constant CALLBACK_GAS_LIMIT = 100_000;
    address public constant TREASURY = 0x9F64C4bECa7BBda647B9A755B29F7F9687bc4303;
    mapping(uint256 => Randomness) public randomness;
    mapping(address => uint256) public nativeCredit;
    uint256 public totalNativeCredit;
    bool public vrfSubsidised;

    error InvalidConfiguration();
    error InsufficientNativePayment(uint256 required, uint256 supplied);
    error OnlyWrapper();
    error NativeTransferFailed();
    error DuplicateVRFRequest();
    event RandomnessRequested(uint256 indexed requestId, address indexed payer, uint256 vrfCost, bool subsidised);
    event RandomnessReady(uint256 indexed requestId, uint256 word);
    event NativeCreditWithdrawn(address indexed account, address indexed recipient, uint256 amount);
    event SubsidyChanged(bool enabled);

    constructor(address authority_, address wrapper_, uint16 confirmations_) AccessManaged(authority_) {
        if (authority_.code.length == 0 || wrapper_.code.length == 0 || confirmations_ < 3 || confirmations_ > 200) revert InvalidConfiguration();
        vrfWrapper = INativeVRFWrapper(wrapper_);
        requestConfirmations = confirmations_;
    }

    function quoteVrf(uint256 gasPriceWei) external view returns (uint256) {
        return vrfSubsidised ? 0 : vrfWrapper.estimateRequestPriceNative(CALLBACK_GAS_LIMIT, 1, gasPriceWei);
    }

    function _requestRandomness(address payer) internal returns (uint256 id) {
        uint256 price = vrfWrapper.calculateRequestPriceNative(CALLBACK_GAS_LIMIT, 1);
        uint256 charged = vrfSubsidised ? 0 : price;
        if (msg.value < charged) revert InsufficientNativePayment(charged, msg.value);
        if (vrfSubsidised && address(this).balance - totalNativeCredit - msg.value < price) {
            revert InsufficientNativePayment(price, address(this).balance - totalNativeCredit - msg.value);
        }
        uint256 surplus = msg.value - charged;
        nativeCredit[payer] += surplus;
        totalNativeCredit += surplus;
        // Chainlink VRFV2PlusClient.EXTRA_ARGS_V1_TAG / ExtraArgsV1(nativePayment=true).
        bytes memory args = abi.encodeWithSelector(bytes4(keccak256("VRF ExtraArgsV1")), true);
        id = vrfWrapper.requestRandomWordsInNative{value: price}(CALLBACK_GAS_LIMIT, requestConfirmations, 1, args);
        if (randomness[id].requested) revert DuplicateVRFRequest();
        randomness[id].requested = true;
        emit RandomnessRequested(id, payer, price, vrfSubsidised);
    }

    /// @dev Storage only; no transfers, minting, external calls, or pause gate in the callback.
    function rawFulfillRandomWords(uint256 id, uint256[] calldata words) external {
        if (msg.sender != address(vrfWrapper)) revert OnlyWrapper();
        Randomness storage r = randomness[id];
        if (!r.requested || r.fulfilled || words.length != 1) return;
        r.word = words[0];
        r.fulfilled = true;
        emit RandomnessReady(id, words[0]);
    }

    function withdrawNativeCredit(address payable recipient) external nonReentrant {
        if (recipient == address(0)) revert InvalidConfiguration();
        uint256 amount = nativeCredit[msg.sender];
        nativeCredit[msg.sender] = 0;
        totalNativeCredit -= amount;
        (bool ok,) = recipient.call{value: amount}("");
        if (!ok) revert NativeTransferFailed();
        emit NativeCreditWithdrawn(msg.sender, recipient, amount);
    }

    function setVrfSubsidised(bool enabled) external restricted {
        vrfSubsidised = enabled;
        emit SubsidyChanged(enabled);
    }
    function withdrawUnusedSubsidy() external restricted nonReentrant {
        (bool ok,) = payable(TREASURY).call{value: address(this).balance - totalNativeCredit}("");
        if (!ok) revert NativeTransferFailed();
    }
    function pause() external restricted { _pause(); }
    function unpause() external restricted { _unpause(); }
    receive() external payable {}
}
