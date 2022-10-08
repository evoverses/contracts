// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../utils/constants/ConstantsBase.sol";
import "../../ERC20/interfaces/IEVO.sol";

abstract contract BBFeeDistributor is Initializable, AccessControlEnumerableUpgradeable, BaseConstants {
    using SafeERC20Upgradeable for IEVO;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    EnumerableMapUpgradeable.AddressToUintMap private _shareDistribution;

    uint256 private _totalShares;

    IEVO private _EVO;

    function __BBFeeDistributor_init(address feeToken) internal onlyInitializing {
        __AccessControlEnumerable_init();
        _EVO = IEVO(feeToken);
    }

    function _distributeFee(uint256 fee) internal {
        uint256 count = _shareDistribution.length();
        for (uint256 i = 0; i < count; i++) {
            address destination;
            uint256 share;
            (destination, share) = _shareDistribution.at(i);
            uint256 amount = fee * share / _totalShares;
            if (destination == address(0)) {
                _EVO.burnFrom(_msgSender(), amount);
            } else {
                _EVO.transferFrom(_msgSender(), destination, amount);
            }
        }
    }

    function setFeeShare(address destination, uint256 share) public onlyRole(ADMIN_ROLE) {
        bool exists;
        uint256 _share;
        (exists, _share) = _shareDistribution.tryGet(destination);
        if (exists) {
            if (share >= _share) {
                _totalShares += share - _share;
            } else {
                _totalShares -= _share - share;
            }
        } else {
            _totalShares += share;
        }
        _shareDistribution.set(destination, share);
    }

    function removeFeeShare(address destination) public onlyRole(ADMIN_ROLE) {
        bool exists;
        uint256 share;
        (exists, share) = _shareDistribution.tryGet(destination);
        if (exists) {
            _totalShares -= share;
            _shareDistribution.remove(destination);
        }
    }

    function getFeeShares() public view returns (address[] memory destinations, uint256[] memory shares, uint256 total) {
        total = _totalShares;
        uint256 count = _shareDistribution.length();
        destinations = new address[](count);
        shares = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            (destinations[i], shares[i]) = _shareDistribution.at(i);
        }
    }

    uint256[47] private __gap;
}
