// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* Interface Imports */
import "./ICrossDomainMessenger.sol";

/* External Imports */
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title CrossDomainEnabled
 * @dev Helper contract for contracts performing cross-domain communications
 *
 * Compiler used: defined by inheriting contract
 * Runtime target: defined by inheriting contract
 */
abstract contract CrossDomainEnabledBobaAvax is Initializable {
    /*************
     * Variables *
     *************/

    // Messenger contract used to send and receive messages from the other domain.
    address public messenger;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @param _messenger Address of the CrossDomainMessenger on the current layer.
     */
    function __CrossDomainEnabled_init(address _messenger) internal onlyInitializing {
        messenger = _messenger;
    }

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Enforces that the modified function is only callable by a specific cross-domain account.
     * @param _sourceDomainAccount The only account on the originating domain which is
     *  authenticated to call this function.
     */
    modifier onlyFromCrossDomainAccount(address _sourceDomainAccount) {
        require(msg.sender == address(getCrossDomainMessenger()), "OVM_XCHAIN: messenger contract unauthenticated");
        require(
            getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount,
            "OVM_XCHAIN: wrong sender of cross-domain message"
        );
        _;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Gets the messenger, usually from storage. This function is exposed in case a child contract
     * needs to override.
     * @return The address of the cross-domain messenger contract which should be used.
     */
    function getCrossDomainMessenger() internal virtual returns (ICrossDomainMessenger) {
        return ICrossDomainMessenger(messenger);
    }

    /**
     * Sends a message to an account on another domain
     * @param _crossDomainTarget The intended recipient on the destination domain
     * @param _message The data to send to the target (usually calldata to a function with
     *  `onlyFromCrossDomainAccount()`)
     * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
     */
    function sendCrossDomainMessage(address _crossDomainTarget, uint32 _gasLimit, bytes memory _message) internal {
        getCrossDomainMessenger().sendMessage(_crossDomainTarget, _message, _gasLimit);
    }

    function _setCrossDomainMessenger(address _messenger) internal {
        messenger = _messenger;
    }

    uint256[49] private __gap;
}