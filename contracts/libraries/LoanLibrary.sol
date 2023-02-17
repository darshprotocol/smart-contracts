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

    event LoanCreated(
        uint256 loanId,
        uint256 offerId,
        LoanLibrary.State state,
        address principalToken,
        address collateralToken,
        uint256 initialPrincipal,
        uint256 currentPrincipal,
        uint256 initialCollateral,
        uint256 currentCollateral,
        uint256 interest,
        uint256 startDate,
        uint256 maturityDate,
        uint16 graceDays,
        address borrower,
        address lender
    );

    struct Loan {
        uint256 offerId;
        LoanLibrary.State state;
        address principalToken;
        address collateralToken;
        uint256 initialPrincipal;
        uint256 currentPrincipal;
        uint256 initialCollateral;
        uint256 currentCollateral;
        uint256 collateralPriceInUSD;
        uint256 interest;
        uint startDate;
        uint maturityDate;
        uint16 graceDays;
        uint8 numInstallmentsPaid;
        uint256 unClaimedPrincipal;
        uint256 unClaimedCollateral;
        uint repaidOn;
        address borrower;
        address lender;
    }
}
