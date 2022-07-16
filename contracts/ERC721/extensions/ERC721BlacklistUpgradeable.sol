// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../deprecated/OldTokenConstants.sol";

/**
* @title ERC721 Blacklist v1.0.0
* @author @DirtyCajunRice
*/
abstract contract ERC721BlacklistUpgradeable is Initializable, ERC721Upgradeable,
AccessControlEnumerableUpgradeable, OldTokenConstants {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private blacklist;

    modifier notBlacklisted(address _address) {
        require(!blacklist.contains(_address), "Blacklisted address");
        _;
    }

    function __ERC721Blacklist_init() internal onlyInitializing {
        __AccessControlEnumerable_init();
        __ERC721Blacklist_init_unchained();
    }

    function __ERC721Blacklist_init_unchained() internal onlyInitializing {

    }

    function addBlacklist(address _address) public onlyRole(ADMIN_ROLE) {
        blacklist.add(_address);
    }

    function removeBlacklist(address _address) public onlyRole(ADMIN_ROLE) {
        blacklist.remove(_address);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    virtual
    notBlacklisted(from)
    notBlacklisted(to)
    override(ERC721Upgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(
        ERC721Upgradeable,
        AccessControlEnumerableUpgradeable
    )
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256[49] private __gap;
}