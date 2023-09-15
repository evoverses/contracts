// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../../../utils/constants/ConstantsBase.sol";
import "../../../../utils/access/StandardAccessControl.sol";
import "./IL2BillingContract.sol";

contract L2BillingContract is Initializable, IL2BillingContract, StandardAccessControl {
    /*************
     * Variables *
     *************/

    address public feeWallet;
    uint256 public exitFee;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*************
     * Callback *
     *************/

    receive() external payable {}

    /*************
     * Functions *
     *************/

    function initialize() initializer public {
        __StandardAccessControl_init();
        feeWallet = address(0);
        exitFee = 0;
    }

    function collectFee() external payable {
        require(exitFee == msg.value, "exit fee does not match");
        emit CollectFee(msg.sender, exitFee);
    }

    function withdraw() external {
        require(feeWallet != address(0), "BillingContract::Fee wallet not set");
        uint256 balance = address(this).balance;
        require(balance >= 15e18, "BillingContract::Balance is too low");
        (bool sent,) = feeWallet.call{value: balance}("");
        require(sent, "BillingContract::Failed to withdraw BOBA");
        emit Withdraw(feeWallet, balance);
    }

    function updateExitFee(uint256 _exitFee) external onlyAdmin {
        exitFee = _exitFee;
        emit UpdateExitFee(_exitFee);
    }

    function updateFeeWallet(address _feeWallet) external onlyAdmin {
        require(_feeWallet != address(0), "BillingContract::Cannot set to zero address");
        require(_feeWallet != feeWallet, "BillingContract::Fee wallet unchanged");
        feeWallet = _feeWallet;
        emit UpdateFeeWallet(feeWallet);
    }
}
