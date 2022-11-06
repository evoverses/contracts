// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IL2BillingContract {
    /*************
     * Variables *
     *************/
    function feeWallet() external returns (address);
    function exitFee() external returns (uint256);

    /*************
     *   Events  *
     *************/

    event UpdateExitFee(uint256);
    event UpdateFeeWallet(address);
    event CollectFee(address, uint256);
    event Withdraw(address, uint256);

    /*************
     * Functions *
     *************/
    function collectFee() external payable;
    function withdraw() external;
    function updateExitFee(uint256 _exitFee) external;
    function updateFeeWallet(address _feeWallet) external;
}