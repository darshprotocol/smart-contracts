// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LoanLibrary {
    enum State {
        ACTIVE,
        REPAID,
        ACTIVE_DEFAULTED,
        REPAID_DEFAULTED
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
        uint256 interestRate,
        uint256 startDate,
        uint256 maturityDate,
        uint16 graceDays,
        address borrower,
        address lender
    );

    event LoanCreatedProperty(
        uint256 loanId,
        uint256 collateralPriceInUSD,
        uint8 numInstallmentsPaid,
        uint256 unClaimedPrincipal,
        uint256 unClaimedCollateral,
        uint256 unClaimedDefaultCollateral,
        uint256 unClaimedBorrowedPrincipal,
        uint256 totalInterestPaid,
        uint256 repaidOn
    );

    struct Loan {
        uint256 offerId;
        /// @dev enum loan state
        State state;
        /// @dev tokens address
        address principalToken;
        address collateralToken;
        /// @dev initial principal that was borrowed
        uint256 initialPrincipal;
        /// @dev current principal that is being borrowed
        uint256 currentPrincipal;
        /// @dev initial collateral that was dropped
        uint256 initialCollateral;
        /// @dev current collateral that is being dropped
        uint256 currentCollateral;
        /// @dev worth of collateral in USD at the time of loan
        uint256 collateralPriceInUSD;
        /// @dev loan interestRate rate per seconds
        uint256 interestRate;
        /// @dev loan start in seconds
        uint256 startDate;
        /// @dev loan maturity in seconds
        uint256 maturityDate;
        /// @dev loan grace days in days
        uint16 graceDays;
        /// @dev number of times that a borrower
        /// split to payback a loan
        uint8 numInstallmentsPaid;
        /// @dev this represents principal + interestRate
        /// that was paid payback by the borrower that
        /// the lender as not claimed
        uint256 unClaimedPrincipal;
        /// @dev this represents collateral amount
        /// that was unlock that the borrower has not
        /// claimed
        uint256 unClaimedCollateral;
        /// @dev this represents collateral amount
        /// retrieve from a borrower when default
        /// that the lender has not claimed
        uint256 unClaimedDefaultCollateral;
        /// @dev this represents principal amount
        /// that the borrower has not claimed
        uint256 unClaimedBorrowedPrincipal;
        /// @dev this represents total interestRate paid by
        /// the borrower
        uint256 totalInterestPaid;
        /// @dev seconds of full/installment repaid loan
        uint256 repaidOn;
        /// @dev actors address
        address borrower;
        address lender;
    }
}
