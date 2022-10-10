//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ITuringHelper.sol";
import "./IBobaTuringCredit.sol";

/**
* @title Turing Helper v1.0.0
* @author @DirtyCajunRice
* @dev Modified from Boba Network's default Turing Helper
*/
contract TuringHelper is ITuringHelper, Initializable, PausableUpgradeable, AccessControlEnumerableUpgradeable {
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");

    TuringHelper Self;
    IBobaTuringCredit private _turingCredit;

    uint256 private txCost;

    modifier onlySelf() {
        require(msg.sender == address(this), "Turing:GetResponse:msg.sender != address(this)");
        _;
    }

    modifier onlyR2(uint32 rType) {
        require(rType == 2, string(GetErrorCode(rType))); // l2geth can pass values here to provide debug information
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Pausable_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(CONTRACT_ROLE, _msgSender());

        Self = TuringHelper(address(this));
        _turingCredit = IBobaTuringCredit(0x4200000000000000000000000000000000000020);
    }

    function GetErrorCode(uint32 rType) internal pure returns (string memory) {
        if(rType ==  1) return "TURING: Geth intercept failure";
        if(rType == 10) return "TURING: Incorrect input state";
        if(rType == 11) return "TURING: Calldata too short";
        if(rType == 12) return "TURING: URL >64 bytes";
        if(rType == 13) return "TURING: Server error";
        if(rType == 14) return "TURING: Could not decode server response";
        if(rType == 15) return "TURING: Could not create rpc client";
        if(rType == 16) return "TURING: RNG failure";
        if(rType == 17) return "TURING: API Response >322 chars";
        if(rType == 18) return "TURING: API Response >160 bytes";
        if(rType == 19) return "TURING: Insufficient credit";
        if(rType == 20) return "TURING: Missing cache entry";
        return '';
    }

    /* This is the interface to the off-chain mechanism. Although
       marked as "public", it is only to be called by TuringCall()
       or TuringTX().
       The _payload parameter is overloaded to represent either the
       request parameters or the off-chain response, with the rType
       parameter indicating which is which.
       When called as a request (rType == 1), it starts the offchain call,
       which, if all all goes well, results in the rType changing to 2.
       This response is then passed back to the caller.
    */
    function GetResponse(uint32 rType, string memory _url, bytes memory _payload) public onlySelf onlyR2(rType) returns(bytes memory) {
        require (_payload.length > 0, "Turing:GetResponse:no payload");
        require (rType == 2, string(GetErrorCode(rType)));
        return _payload;
    }

    function GetRandom(uint32 rType, uint256 _random) public onlySelf onlyR2(rType) returns(uint256) {
        require (rType == 2, string(GetErrorCode(rType)));
        return _random;
    }

    function TuringTx(string memory _url, bytes memory _payload) public onlySelf returns (bytes memory) {
        require (_payload.length > 0, "Turing:TuringTx: no payload");
        bytes memory response = Self.GetResponse(1, _url, _payload);
        emit OffchainResponse(1, response);
        return response;
    }
    /* Called from the external contract. It takes an api endpoint URL
       and an abi-encoded request payload. The URL and the list of allowed
       methods are supplied when the contract is created. In the future
       some of this registration might be moved into l2geth, allowing for
       security measures such as TLS client certificates. A configurable timeout
       could also be added.
       Logs the offchain response so that a future verifier or fraud prover
       can replay the transaction and ensure that it results in the same state
       root as during the initial execution. Note - a future version might
       need to include a timestamp and/or more details about the
       offchain interaction.
    */
    function APICall(string memory _url, bytes memory _payload) public whenNotPaused onlyRole(CONTRACT_ROLE) returns (bytes memory) {
        require (_payload.length > 0, "Turing:APICall:no payload");
        bytes memory response = Self.GetResponse(1, _url, _payload);
        emit OffchainResponse(1, response);
        return response;
    }

    function Random() public whenNotPaused onlyRole(CONTRACT_ROLE) returns (uint256) {
        uint256 response = Self.GetRandom(1, 0);
        emit OnChainRandom(1, response);
        return response;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // ERC165 check interface
    function supportsInterface(bytes4 interfaceId) public view override(AccessControlEnumerableUpgradeable) returns (bool) {
        return interfaceId == ITuringHelper.TuringTx.selector || super.supportsInterface(interfaceId);
    }
}