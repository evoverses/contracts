// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {INativeVRFWrapper} from "../NPCs/Breeding/NativeVRFConsumer.sol";

contract MockEVO is ERC20 {
    bool public failTransfers;
    constructor() ERC20("Mock EVO", "EVO") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
    function setFailTransfers(bool value) external { failTransfers = value; }
    function transfer(address to, uint256 amount) public override returns (bool) {
        if (failTransfers) return false;
        return super.transfer(to, amount);
    }
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (failTransfers) return false;
        return super.transferFrom(from, to, amount);
    }
}

contract MockEvoNFT is ERC721, AccessManaged {
    uint256 public nextId = 5109;
    bool public failMint;
    event MetadataUpdate(uint256 tokenId);
    constructor(address authority_) ERC721("Mock Evo", "Evo") AccessManaged(authority_) {}
    function mintTo(address to, uint256 id) external restricted { require(id < nextId); _safeMint(to, id); }
    function mintNewWithId(address to) external restricted returns (uint256 id) {
        require(!failMint, "mint unavailable");
        id = nextId++;
        _safeMint(to, id);
    }
    function setFailMint(bool value) external { failMint = value; }
    function requestMetadataUpdate(uint256 id) external { emit MetadataUpdate(id); }
}

interface IVRFCallback { function rawFulfillRandomWords(uint256 id, uint256[] calldata words) external; }
contract MockNativeVRFWrapper is INativeVRFWrapper {
    uint256 public price = 0.01 ether;
    uint256 public nextId = 1;
    uint256 public received;
    bool public disabled;
    mapping(uint256 => address) public consumers;
    function setPrice(uint256 value) external { price = value; }
    function setDisabled(bool value) external { disabled = value; }
    function calculateRequestPriceNative(uint32, uint32) external view returns (uint256) { return price; }
    function estimateRequestPriceNative(uint32, uint32, uint256) external view returns (uint256) { return price; }
    function requestRandomWordsInNative(uint32 gasLimit, uint16 confirmations, uint32 words, bytes calldata args)
        external payable returns (uint256 id)
    {
        require(!disabled && msg.value == price && words == 1 && confirmations >= 3 && gasLimit == 100_000);
        require(keccak256(args) == keccak256(abi.encodeWithSelector(bytes4(keccak256("VRF ExtraArgsV1")), true)));
        id = nextId++;
        consumers[id] = msg.sender;
        received += msg.value;
    }
    function fulfill(uint256 id, uint256 word) external {
        uint256[] memory words = new uint256[](1);
        words[0] = word;
        IVRFCallback(consumers[id]).rawFulfillRandomWords(id, words);
    }
    function fulfillWithGas(uint256 id, uint256 word, uint256 gasLimit) external {
        uint256[] memory words = new uint256[](1);
        words[0] = word;
        IVRFCallback(consumers[id]).rawFulfillRandomWords{gas: gasLimit}(id, words);
    }
}

contract MockAuthority {
    function canCall(address, address, bytes4) external pure returns (bool immediate, uint32 delay) { return (true, 0); }
}

contract RejectingBreeder is IERC721Receiver {
    bool public reject = true;
    address public attackTarget;
    bytes public attackData;
    bool public attempted;
    bool public reentrySucceeded;
    function setAttack(address target, bytes calldata data) external { attackTarget=target; attackData=data; }
    function setReject(bool value) external { reject = value; }
    function execute(address target, bytes calldata data) external payable returns (bytes memory) {
        (bool ok, bytes memory result) = target.call{value: msg.value}(data);
        require(ok, "execution failed");
        return result;
    }
    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        if (attackTarget != address(0)) {
            attempted=true;
            (reentrySucceeded,) = attackTarget.call(attackData);
        }
        require(!reject, "reject mint");
        return IERC721Receiver.onERC721Received.selector;
    }
}

// Compile the real permission manager and proxy for integration/storage tests.
import {AccessManager} from "@openzeppelin/contracts/access/manager/AccessManager.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {EvoBreedingRules as Rules} from "../NPCs/Breeding/EvoBreedingRules.sol";
contract BreedingRulesHarness {
    function cost(Rules.Adult calldata a) external pure returns (uint256) { return Rules.cost(a); }
    function child(Rules.Adult calldata a, Rules.Adult calldata b, Rules.Species[] calldata p, uint256 word)
        external pure returns (uint256) { return Rules.childSpecies(a, b, p, word); }
    function hatch(Rules.Adult calldata a, Rules.Adult calldata b, Rules.Species calldata s, bool treated, uint256 word)
        external pure returns (Rules.Attributes memory, Rules.Stats memory) { return Rules.hatch(a,b,s,treated,word); }
}
