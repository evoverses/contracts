// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../ERC721/EvoEgg/IEvoEgg.sol";
import "../../ERC721/interfaces/IEvo.sol";
import "../constants/NpcConstants.sol";
/**
* @title Unreal Engine Query Helper v1.0.0
* @author @DirtyCajunRice
*/
contract UnrealEngineQueryHelper is Initializable, AccessControlEnumerableUpgradeable {
    IERC20Upgradeable private EVO;
    IERC20Upgradeable private cEVO;
    IEvo private Evo;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        Evo = IEvo(0x454a0E479ac78e508a95880216C06F50bf3C321C);
        EVO = IERC20Upgradeable(0x42006Ab57701251B580bDFc24778C43c9ff589A1);
        cEVO = IERC20Upgradeable(0x7B5501109c2605834F7A4153A75850DB7521c37E);
    }

    function allTokenUriOf(address owner) public view returns(string[] memory) {
        return Evo.batchTokenUriJson(Evo.tokensOfOwner(owner));
    }

    function balancesOf(address owner) public view returns(uint256, uint256) {
        return (EVO.balanceOf(owner), cEVO.balanceOf(owner));
    }

    function dataOf(address owner) public view returns(uint256, uint256, string[] memory) {
        uint256 evo;
        uint256 cEvo;
        (evo, cEvo) = balancesOf(owner);
        return (evo, cEvo, allTokenUriOf(owner));
    }

    function dataOf2(address owner, string memory uid) public view returns(string memory, uint256, uint256, string[] memory) {
        uint256 evo;
        uint256 cEvo;
        (evo, cEvo) = balancesOf(owner);
        return (uid, evo, cEvo, allTokenUriOf(owner));
    }
}