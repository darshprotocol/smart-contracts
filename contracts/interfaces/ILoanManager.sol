// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/LoanLibrary.sol";
import "../libraries/OfferLibrary.sol";
import "../interfaces/ILoanManager.sol";

interface ILoanManager {
    function getLoan(uint160 loanId) external returns (LoanLibrary.Loan memory);

    function repayLoan(
        uint160 loanId,
        uint256 interestPaid,
        uint256 principalPaid,
        uint256 collateralRetrieved
    ) external returns (bool);

    // function liquidateLoan(uint160 loanId) external returns (bool);

    function claimPrincipal(uint160 loanId) external;

    function claimCollateral(uint160 loanId) external;
}
