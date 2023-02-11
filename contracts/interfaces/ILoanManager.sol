// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/LoanLibrary.sol";
import "../libraries/OfferLibrary.sol";
import "../interfaces/ILoanManager.sol";

interface ILoanManager {
    function getLoan(uint256 loanId) external returns (LoanLibrary.Loan memory);

    function repayLoanAll(uint256 loanId) external returns (bool);

    function repayLoanInstallment(
        uint256 loanId,
        uint256 principalPaid,
        uint256 collateralRetrieved
    ) external returns (bool);

    function liquidateLoan(uint256 loanId) external returns (bool);
}
