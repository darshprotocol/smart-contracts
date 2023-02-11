// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./OfferLibrary.sol";
import "./AssetLibrary.sol";

library LoanLibrary {
    enum State {
        ACTIVE,
        PAID,
        LIQUIDATED
    }

    struct Loan {
        uint256 offerId;
        LoanLibrary.State state;
        OfferLibrary.Type offerType;
        address principalToken;
        address collateralToken;
        uint256 initialPrincipal;
        uint256 currentPrincipal;
        uint256 initialCollateral;
        uint256 currentCollateral;
        uint256 interest;
        uint160 startDate;
        uint160 maturityDate;
        uint numInstallmentsPaid;
        address borrower;
        address lender;
    }
}
