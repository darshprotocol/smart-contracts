// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./OfferLibrary.sol";
import "./PoolLibrary.sol";

library LoanLibrary {
    enum State {
        ACTIVE,
        PAID,
        LIQUIDATED
    }

    struct Loan {
        uint160 offerId;
        LoanLibrary.State state;
        address principalToken;
        address collateralToken;
        uint256 initialPrincipal;
        uint256 currentPrincipal;
        uint256 initialCollateral;
        uint256 currentCollateral;
        uint256 collateralPriceInUSD;
        uint256 interest;
        uint160 startDate;
        uint160 maturityDate;
        uint16 graceDays;
        uint8 numInstallmentsPaid;
        uint256 unClaimedPrincipal;
        uint256 unClaimedCollateral;
        address borrower;
        address lender;
    }
}
