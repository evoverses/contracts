// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "../interfaces/IERC20L2.sol";

/**
 * @title ERC20 L2 Token
 * @dev ERC20 Token that can be burned (destroyed).
 */
abstract contract ERC20L2 is Initializable, IERC20L2, ERC20Upgradeable, ERC165Upgradeable, AccessControlUpgradeable {
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    address public l1Token;

    function __ERC20L2_init(address _l1Token) internal onlyInitializing {
        __ERC165_init();

        __AccessControl_init();
        _grantRole(BRIDGE_ROLE, _msgSender());
        l1Token = _l1Token;
    }

    function mint(address to, uint256 amount) public onlyRole(BRIDGE_ROLE) {
        _mint(to, amount);
    }

    function burn(address _from, uint256 _amount) public virtual onlyRole(BRIDGE_ROLE) {
        _burn(_from, _amount);
    }

    function _setL1Token(address _l1Token) internal virtual {
        l1Token = _l1Token;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165Upgradeable, AccessControlUpgradeable) returns (bool) {
        bytes4 bridge = IERC20L2.l1Token.selector ^ IERC20L2.mint.selector ^ IERC20L2.burn.selector;
        return interfaceId == bridge || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}