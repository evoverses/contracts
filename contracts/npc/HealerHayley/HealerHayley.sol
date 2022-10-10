// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../ERC721/interfaces/EvoStructs.sol";
import "../../utils/constants/NpcConstants.sol";
import "../../utils/boba/IBobaTuringCredit.sol";
import "../../utils/boba/ITuringHelper.sol";
import "../../ERC721/interfaces/IEvo.sol";
import "../../libraries/Numbers.sol";

/**
* @title Healer Hayley v1.0.0
* @author @DirtyCajunRice
*/
contract HealerHayley is Initializable, EvoStructs, PausableUpgradeable, AccessControlEnumerableUpgradeable, NpcConstants {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Numbers for uint256;

    enum Reason {
        Size
    }

    IBobaTuringCredit private _turingCredit;
    ITuringHelper private _turing;
    IEvo private _Evo;

    address private _unused;

    mapping (Reason => EnumerableSetUpgradeable.UintSet) private _affected;
    mapping (Reason => EnumerableSetUpgradeable.UintSet) private _healed;

    event Healed(address indexed from, uint256 tokenId, Reason reason, uint256 value);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Pausable_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(CONTRACT_ROLE, _msgSender());

        _turingCredit = IBobaTuringCredit(0x4200000000000000000000000000000000000020);
        _turing = ITuringHelper(0x680e176b2bbdB2336063d0C82961BDB7a52CF13c);
        _Evo = IEvo(0x3e9694a37846C864C67253af6F5d1F534ff3BF46);
    }

    function healSize(uint256[] memory tokenIds) external payable {
        require(tokenIds.length <= 15, "HealerHayley::Maximum 15 Evos per size heal");
        _payTuringFee();

        uint256 random = _turing.Random();
        uint256[] memory chunks = random.chunkUintX(10_000, 15);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_affected[Reason.Size].contains(tokenIds[i]), "Evo already healed");
            uint256 size = chunks[i] % 21;
            _Evo.setAttribute(tokenIds[i], 14, size);
            _affected[Reason.Size].remove(tokenIds[i]);
            _healed[Reason.Size].add(tokenIds[i]);
            emit Healed(msg.sender, tokenIds[i], Reason.Size, size);
        }
    }


    function setAffected(Reason reason, uint256[] memory affected) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < affected.length; i++) {
            _affected[reason].add(affected[i]);
        }
    }

    function remainingAffected(Reason reason) public view returns (uint256[] memory, uint256[] memory) {
        return (_affected[reason].values(), _healed[reason].values());
    }


    function _payTuringFee() internal {
        uint256 price = _turingCredit.turingPrice();
        require(msg.value == price, "Insufficient Turing Fee");
        _turingCredit.addBalanceTo{value: msg.value}(msg.value, address(_turing));
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

}