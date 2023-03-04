// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/LoanLibrary.sol";
import "../libraries/OfferLibrary.sol";
import "../interfaces/ILoanManager.sol";

interface ILoanManager {
    function createLoan(
        uint256 offerId,
        OfferLibrary.Type offerType,
        address principalToken,
        address collateralToken,
        uint256 principalAmount,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint256 unClaimedBorrowedPrincipal,
        address borrower,
        address lender
    ) external returns (uint256);

    function getLoan(uint256 loanId) external returns (LoanLibrary.Loan memory);

    function repayLoan(
        uint256 loanId,
        uint256 interestPaid,
        uint256 principalPaid,
        uint256 collateralRetrieved
    ) external returns (bool);

    function claimPrincipal(uint256 loanId, address user)
        external
        returns (uint256, uint256, address);

    function claimDefaultCollateral(uint256 loanId, address user)
        external
        returns (uint256, uint256, address);

    function claimCollateral(uint256 loanId, address user)
        external
        returns (uint256, uint256, address);

    function claimBorrowedPrincipal(uint256 loanId, address user)
        external
        returns (uint256, uint256, address);

    function liquidateLoan(
        uint256 loanId,
        uint256 principalPaid,
        uint256 collateralRetrieved,
        uint256 collateralPaid
    ) external;
}
