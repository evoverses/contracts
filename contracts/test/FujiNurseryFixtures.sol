// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import {INativeVRFWrapper} from "../NPCs/Breeding/NativeVRFConsumer.sol";

/// @notice Fuji test assets only. No value or ownership is imported from mainnet.
contract FujiTestEVO is ERC20 {
    address public immutable administrator;
    constructor(address administrator_) ERC20("Fuji Test EVO", "tEVO") {
        require(block.chainid == 43113 || block.chainid == 31337, "test networks only");
        administrator = administrator_;
    }
    function mint(address to, uint256 amount) external { require(msg.sender == administrator, "administrator only"); _mint(to, amount); }
}
contract FujiTestEvoNFT is ERC721Enumerable, AccessManaged {
    uint256 public nextId = 5109;
    event MetadataUpdate(uint256 tokenId);
    constructor(address authority_) ERC721("Fuji Test Evos", "tEVO-NFT") AccessManaged(authority_) {
        require(block.chainid == 43113 || block.chainid == 31337, "test networks only");
    }
    function mintTo(address to, uint256 id) external restricted { require(id < nextId); _safeMint(to, id); }
    function mintNew(address to) external restricted { uint256 id = nextId++; _safeMint(to, id); }
    function mintNewWithId(address to) external restricted returns (uint256 id) { id = nextId++; _safeMint(to, id); }
    function requestMetadataUpdate(uint256 id) external { ownerOf(id); emit MetadataUpdate(id); }
}
interface IFujiRandomnessConsumer { function rawFulfillRandomWords(uint256 id, uint256[] calldata words) external; }
/// @notice Administrator-controlled test oracle. This DOES NOT test Chainlink VRF or its fees.
contract FujiTestRandomnessWrapper is INativeVRFWrapper {
    address public immutable administrator;
    uint256 public nextId = 1;
    mapping(uint256 => address) public consumers;
    mapping(uint256 => bool) public fulfilled;
    event TestRandomnessRequested(uint256 indexed id, address indexed consumer);
    event TestRandomnessFulfilled(uint256 indexed id, uint256 word);
    constructor(address administrator_) {
        require(block.chainid == 43113 || block.chainid == 31337, "test networks only");
        administrator = administrator_;
    }
    function calculateRequestPriceNative(uint32, uint32) external pure returns (uint256) { return 0; }
    function estimateRequestPriceNative(uint32, uint32, uint256) external pure returns (uint256) { return 0; }
    function requestRandomWordsInNative(uint32 gasLimit, uint16 confirmations, uint32 words, bytes calldata extraArgs) external payable returns (uint256 id) {
        require(msg.value == 0 && gasLimit == 100000 && confirmations >= 3 && words == 1, "invalid test request");
        require(keccak256(extraArgs) == keccak256(abi.encodeWithSelector(bytes4(keccak256("VRF ExtraArgsV1")), true)), "invalid args");
        id = nextId++; consumers[id] = msg.sender; emit TestRandomnessRequested(id, msg.sender);
    }
    function fulfill(uint256 id, uint256 word) external {
        require(msg.sender == administrator, "administrator only");
        require(consumers[id] != address(0) && !fulfilled[id], "invalid request");
        fulfilled[id] = true;
        uint256[] memory words = new uint256[](1); words[0] = word;
        IFujiRandomnessConsumer(consumers[id]).rawFulfillRandomWords{gas:100000}(id, words);
        emit TestRandomnessFulfilled(id, word);
    }
}
