// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IcEVOUpgradeable {
    struct Disbursement {
        uint256 startTime;
        uint256 duration;
        uint256 amount;
        uint256 balance;
    }
    function mint(address _address, uint256 amount) external;
    function mintDisbursement(address to, uint256 startTime, uint256 duration, uint256 amount) external;
    function bridgeMintDisbursement(
        address to,
        uint256 startTime,
        uint256 duration,
        uint256 amount,
        uint256 balance
    ) external;
    function batchMintDisbursement(
        address[] memory to,
        uint256[] memory amount,
        uint256 startTime,
        uint256 duration
    ) external;
    function burn(uint256 amount) external;
    function claimPending() external;
    function pendingOf(address _address) external view returns(uint256);
    function disbursementsOf(address _address) external view returns(Disbursement[] memory);
    function disbursementOf(address _address) external view returns(uint256, uint256, uint256, uint256);
    function removeDisbursement(address _address, uint256 index) external;
}