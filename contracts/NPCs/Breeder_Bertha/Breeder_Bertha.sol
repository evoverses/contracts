// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IEvoBreedingMint} from "../Breeding/IEvoBreedingMint.sol";
import {NativeVRFConsumer} from "../Breeding/NativeVRFConsumer.sol";
import {Hatcher_Hermann} from "../Hatcher_Hermann/Hatcher_Hermann.sol";

/// @notice New deployment, NOT an implementation upgrade for Brenda's proxy.
/// EVO remains escrowed until minting; committed VRF requests cannot be cancelled or rerolled.
contract Breeder_Bertha is NativeVRFConsumer {
    using SafeERC20 for IERC20;
    enum Status { NONE, PREPARED, RANDOM_PENDING, COMPLETE, CANCELLED }
    struct Request {
        address breeder;
        uint256 parent1;
        uint256 parent2;
        uint256 amount;
        uint256 speciesVersion;
        uint256 committedAt;
        uint256 vrfRequestId;
        uint256 tokenId;
        Status status;
    }
    IERC20 public immutable evoToken;
    IEvoBreedingMint public immutable evoNft;
    Hatcher_Hermann public immutable hatcher;
    uint256 public nextRequestId = 1;
    uint256 public escrowedEvo;
    mapping(uint256 => Request) public requests;

    error InvalidRequestState();
    error NotRequester();
    error PriceExceedsLimit(uint256 price, uint256 limit);
    error UnsupportedTokenTransfer();
    error RandomnessNotReady();
    event BreedPrepared(uint256 indexed requestId, address indexed breeder, uint256 parent1, uint256 parent2, uint256 amount);
    event BreedCommitted(uint256 indexed requestId, uint256 indexed vrfRequestId);
    event BreedCancelled(uint256 indexed requestId, address indexed breeder, uint256 refund);
    event BreedCompleted(uint256 indexed requestId, uint256 indexed tokenId, address indexed breeder, uint256 amount);

    constructor(address authority_, address hatcher_, address wrapper_, uint16 confirmations_)
        NativeVRFConsumer(authority_, wrapper_, confirmations_)
    {
        if (hatcher_.code.length == 0) revert InvalidConfiguration();
        hatcher = Hatcher_Hermann(payable(hatcher_));
        evoToken = hatcher.evoToken();
        evoNft = hatcher.evoNft();
    }

    /// @notice Atomic convenience entry: reserve, escrow EVO and pay only THIS breed's VRF surcharge.
    function breed(uint256 parent1, uint256 parent2, uint256 maxEvoCost)
        external payable whenNotPaused nonReentrant returns (uint256 id)
    {
        id = _prepare(parent1, parent2, maxEvoCost);
        _commit(id);
    }

    /// @notice Optional two-step preparation; refundable only until randomness is committed.
    function prepareBreed(uint256 parent1, uint256 parent2, uint256 maxEvoCost)
        external whenNotPaused nonReentrant returns (uint256)
    {
        return _prepare(parent1, parent2, maxEvoCost);
    }

    function _prepare(uint256 parent1, uint256 parent2, uint256 maxEvoCost) private returns (uint256 id) {
        id = nextRequestId++;
        (uint256 cost, uint256 version) = hatcher.reserveParents(parent1, parent2, msg.sender, id);
        if (cost > maxEvoCost) revert PriceExceedsLimit(cost, maxEvoCost);
        requests[id] = Request(msg.sender, parent1, parent2, cost, version, 0, 0, 0, Status.PREPARED);
        escrowedEvo += cost;
        uint256 balance = evoToken.balanceOf(address(this));
        evoToken.safeTransferFrom(msg.sender, address(this), cost);
        if (evoToken.balanceOf(address(this)) - balance != cost) revert UnsupportedTokenTransfer();
        emit BreedPrepared(id, msg.sender, parent1, parent2, cost);
    }

    function commitBreed(uint256 id) external payable whenNotPaused nonReentrant { _commit(id); }

    function _commit(uint256 id) private {
        Request storage r = requests[id];
        if (r.status != Status.PREPARED) revert InvalidRequestState();
        if (r.breeder != msg.sender) revert NotRequester();
        if (!_stillOwned(r)) revert NotRequester();
        r.status = Status.RANDOM_PENDING;
        r.committedAt = block.timestamp;
        r.vrfRequestId = _requestRandomness(r.breeder);
        emit BreedCommitted(id, r.vrfRequestId);
    }

    /// @notice Refund only BEFORE VRF commitment. Also frees parents sold/burned before commitment.
    /// Once VRF starts there is no expiry refund, denial, replacement seed or admin reroll.
    function cancelBreed(uint256 id) external nonReentrant {
        Request storage r = requests[id];
        if (r.status != Status.PREPARED) revert InvalidRequestState();
        if (msg.sender != r.breeder && _stillOwned(r)) revert NotRequester();
        r.status = Status.CANCELLED;
        escrowedEvo -= r.amount;
        hatcher.releaseParents(r.parent1, r.parent2, id);
        evoToken.safeTransfer(r.breeder, r.amount);
        emit BreedCancelled(id, r.breeder, r.amount);
    }

    /// @notice Permissionless recovery of a failed mint, always with the original wallet and VRF word.
    function completeBreed(uint256 id) external whenNotPaused nonReentrant returns (uint256 tokenId) {
        Request storage r = requests[id];
        if (r.status != Status.RANDOM_PENDING) revert InvalidRequestState();
        Randomness storage random = randomness[r.vrfRequestId];
        if (!random.fulfilled) revert RandomnessNotReady();
        r.status = Status.COMPLETE;
        escrowedEvo -= r.amount;
        tokenId = evoNft.mintNewWithId(r.breeder);
        r.tokenId = tokenId;
        hatcher.recordEgg(tokenId, r.parent1, r.parent2, r.speciesVersion, id, r.committedAt, random.word);
        evoToken.safeTransfer(TREASURY, r.amount);
        emit BreedCompleted(id, tokenId, r.breeder, r.amount);
        evoNft.requestMetadataUpdate(tokenId);
    }

    function _stillOwned(Request storage r) private view returns (bool) {
        try evoNft.ownerOf(r.parent1) returns (address owner) {
            if (owner != r.breeder) return false;
        } catch { return false; }
        try evoNft.ownerOf(r.parent2) returns (address owner) {
            return owner == r.breeder;
        } catch { return false; }
    }
}
