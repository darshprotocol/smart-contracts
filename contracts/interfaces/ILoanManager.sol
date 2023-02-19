// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

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
        uint256 interest,
        uint16 daysToMaturity,
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

    function claimPrincipal(uint256 loanId, address user) external;

    function claimDefaultCollateral(uint256 loanId, address user) external;

    function claimCollateral(uint256 loanId, address user) external;

    function liquidateLoan(
        uint256 loanId,
        uint256 principalPaid,
        uint256 collateralRetrieved,
        uint256 collateralPaid
    ) external;
}
