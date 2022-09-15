// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IcEVO is IERC20Upgradeable {

    struct Disbursement {
        uint256 startTime;
        uint256 duration;
        uint256 amount;
        uint256 balance;
    }

    event ClaimedDisbursement(address indexed from, uint256 amount);

    function DEFAULT_VESTING_PERIOD() external view returns(uint256);

    function disbursements(address) external view returns(Disbursement[] memory);
    function lockedOf(address) external view returns(uint256);
    function transferTime(address) external view returns(uint256);

    function mint(address _address, uint256 amount) external;
    function mintDisbursement(address to, uint256 startTime, uint256 duration, uint256 amount) external;
    function bridgeMintDisbursement(address to, uint256 startTime, uint256 duration, uint256 amount, uint256 balance) external;
    function batchMintDisbursement(address[] memory to, uint256[] memory amount, uint256 startTime, uint256 duration) external;

    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function useLocked(address account, uint256 amount) external;
    function burnLocked() external;

    function claimPending() external;
    function pendingOf(address _address) external view returns(uint256);

    function transferAllDisbursements(address to) external;

    function addGlobalWhitelist(address to) external;
    function addWhitelist(address from, address to) external;
    function resetTransferTimeOf(address _address) external;

    function disbursementsOf(address _address) external view returns(Disbursement[] memory);
}