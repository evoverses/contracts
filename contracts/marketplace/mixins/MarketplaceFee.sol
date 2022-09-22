// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./MarketplaceConstants.sol";

abstract contract MarketplaceFee is
Initializable, AccessControlEnumerableUpgradeable, MarketplaceConstants {
    uint256 private _fee;

    mapping(FeeType => uint256) private _feeWeights;

    event MarketplaceFeeUpdated(uint256 indexed fee);
    event MarketplaceFeeWeightUpdated(uint256 indexed feeWeight, FeeType feeType);

    function __MarketplaceFee_init() internal onlyInitializing {
        __AccessControlEnumerable_init();
        _fee = 100;
        _feeWeights[FeeType.Burned] = 2500;
        _feeWeights[FeeType.Shared] = 2500;
        _feeWeights[FeeType.Founders] = 1000;
        _feeWeights[FeeType.Marketing] = 1000;
        _feeWeights[FeeType.Dev] = 500;
    }

    function getMarketplaceFee() external view returns (uint256) {
        return _fee;
    }

    function getMarketplaceFeeWeights() external view returns ( uint256, uint256, uint256, uint256, uint256) {
        return (
            _feeWeights[FeeType.Burned],
            _feeWeights[FeeType.Shared],
            _feeWeights[FeeType.Founders],
            _feeWeights[FeeType.Marketing],
            _feeWeights[FeeType.Dev]
        );
    }

    function setMarketplaceFee(uint256 fee) external onlyRole(UPDATER_ROLE) {
        require(fee <= MAX_FEE, "MarketplaceFeeUpgradeable: Fees > 10%");
        _fee = fee;
        emit MarketplaceFeeUpdated(fee);
    }

    function setMarketplaceFeeWeight(uint256 feeWeight, FeeType feeType) external onlyRole(UPDATER_ROLE) {
        _feeWeights[feeType] = feeWeight;

        uint256 total =
            _feeWeights[FeeType.Burned]
            + _feeWeights[FeeType.Shared]
            + _feeWeights[FeeType.Founders]
            + _feeWeights[FeeType.Marketing]
            + _feeWeights[FeeType.Dev];
        require(total <= 100, "Total Fees exceed 100%");

        emit MarketplaceFeeWeightUpdated(feeWeight, feeType);
    }

    function _getFee(uint256 price) internal view returns (uint256) {
        return price * _fee / FEE_BASIS_POINTS;
    }
    function _getFeeWeight(uint256 amount, FeeType feeType) internal view returns (uint256) {
        return amount * _feeWeights[feeType] / FEE_BASIS_POINTS;
    }

    function _getSendFeeWeights(uint256 amount) internal view returns(uint256[4] memory) {
        uint256[4] memory percents = [
            _getFeeWeight(amount, FeeType.Shared),
            _getFeeWeight(amount, FeeType.Founders),
            _getFeeWeight(amount, FeeType.Marketing),
            _getFeeWeight(amount, FeeType.Dev)
        ];
        return percents;
    }

    function _getSendFeeTypes() internal pure returns(FeeType[4] memory) {
        FeeType[4] memory feeTypes = [FeeType.Shared, FeeType.Founders, FeeType.Marketing, FeeType.Dev];
        return feeTypes;
    }

    uint256[48] private __gap;
}
