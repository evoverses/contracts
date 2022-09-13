// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "../interfaces/IERC721L2.sol";

/**
 * @title ERC721 L2 Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721L2 is Initializable, ContextUpgradeable, ERC721Upgradeable, IERC721L2,
AccessControlEnumerableUpgradeable {
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    address public l1Contract;

    function __ERC721L2_init(address _l1Contract) internal onlyInitializing {
        __ERC721L2_init_unchained(_l1Contract);

        __AccessControlEnumerable_init();

        _grantRole(BRIDGE_ROLE, _msgSender());
    }

    function __ERC721L2_init_unchained(address _l1Contract) internal onlyInitializing {
        l1Contract = _l1Contract;
    }

    function mint(address _to, uint256 _tokenId, bytes memory _data) public virtual;

    function burn(uint256 _tokenId) public virtual;

    function bridgeExtraData(uint256 tokenId) public view virtual returns(bytes memory);

    function _setL1Contract(address _l1Contract) internal virtual {
        l1Contract = _l1Contract;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual
    override(ERC721Upgradeable, IERC165Upgradeable, AccessControlEnumerableUpgradeable) returns (bool) {
        bytes4 bridgingSupportedInterface = IERC721L2.l1Contract.selector
            ^ IERC721L2.mint.selector
            ^ IERC721L2.burn.selector;

        return interfaceId == IERC721L2.bridgeExtraData.selector
            || interfaceId == bridgingSupportedInterface
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}