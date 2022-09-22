// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

abstract contract MarketplaceCounter {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _saleIdCounter; 

    function _getSaleId() internal returns (uint256) {
        uint256 saleId = _saleIdCounter.current();
        _saleIdCounter.increment();
        return saleId;
    }

    function currentSaleId() external view returns (uint256) {
        return _saleIdCounter.current();
    }

    uint256[49] private __gap;
}