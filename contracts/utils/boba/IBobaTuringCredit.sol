// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title IBobaTuringCredit
 * @dev The credit system for Boba Turing
 */
interface IBobaTuringCredit {
    function prepaidBalance(address) external view returns(uint256);

    function turingToken() external view returns(address);
    function turingPrice() external view returns(uint256);
    function ownerRevenue() external view returns(uint256);

    event TransferOwnership(address oldOwner, address newOwner);
    event AddBalanceTo(address sender, uint256 balanceAmount, address helperContractAddress);
    event WithdrawRevenue(address sender, uint256 withdrawAmount);

    /**
     * @dev Add credit for a Turing helper contract
     *
     * @param _addBalanceAmount the prepaid amount that the user want to add
     * @param _helperContractAddress the address of the turing helper contract
     */
    function addBalanceTo(uint256 _addBalanceAmount, address _helperContractAddress) external;

    /**
     * @dev Return the credit of a specific helper contract
     */
    function getCreditAmount(address _helperContractAddress) external view returns(uint256);
}