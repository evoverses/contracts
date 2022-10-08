// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./IBobaTuringCredit.sol";
import "./ITuringHelper.sol";


abstract contract BobaL2TuringClient is Initializable {
    IBobaTuringCredit private TuringCredit;
    ITuringHelper internal TuringHelper;

    event TuringHelperSet(address indexed from, address _address);
    event TuringCreditSet(address indexed from, address _address);
    event TuringFeePaid(address indexed from, uint256 fee);

    function __BobaL2TuringClient_init(address turingCredit, address turingHelper) internal onlyInitializing {
        TuringCredit = IBobaTuringCredit(turingCredit);
        TuringHelper = ITuringHelper(turingHelper);
    }

    function _payTuringFee() internal virtual {
        uint256 fee = TuringCredit.turingPrice();
        require(msg.value == fee, "Insufficient Turing Fee");
        TuringCredit.addBalanceTo{value: fee}(fee, address(TuringHelper));
        emit TuringFeePaid(msg.sender, fee);
    }

    function _setTuringCredit(address turingCredit) internal {
        TuringCredit = IBobaTuringCredit(turingCredit);
        emit TuringCreditSet(msg.sender, turingCredit);
    }

    function _setTuringHelper(address turingHelper) internal {
        TuringHelper = ITuringHelper(turingHelper);
        emit TuringHelperSet(msg.sender, turingHelper);
    }

    uint256[48] private __gap;
}
