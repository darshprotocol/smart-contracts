// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/ActivityLibrary.sol";

interface IActivity {
    function borrowLoan(
        address lender,
        address borrower,
        uint256 amountBorrowedInUSD
    ) external;

    function repayLoan(
        address lender,
        address borrower,
        uint256 interestPaidInUSD,
        bool completed
    ) external;

    function activeLoansCount(address user) external view returns (uint16);

    function dropCollateral(address borrower, uint256 amountInUSD) external;

    function isDefaulter(address user) external returns (bool);

    function getActivity(address user)
        external view
        returns (ActivityLibrary.Model memory);
}
