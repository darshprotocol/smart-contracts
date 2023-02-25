// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title Activity contract
/// @author Arogundade Ibrahim
/// @notice Keeps record of every user's activity on the LendingPool contract
/// @dev These records are use to calculate user's darsh score
contract Activity is Ownable2Step {
    address lendingPool;

    constructor() Ownable2Step() {}

    struct ActivityModel {
        // frequency
        uint16 borrowedTimes;
        uint16 lentTimes;
        // volume
        uint256 borrowedVolume;
        uint256 lentVolume;
        // last active
        uint256 lastActive;
        // collateral volume
        uint256 collateralVolume;
        // interestRate
        uint256 interestPaidVolume;
        // defaulting
        uint16 defaultedTimes;
        uint256 defaultedVolume;
        // first borrow date
        uint256 firstBorrowAt;
        // active loans
        uint16 activeLoans;
    }

    mapping(address => ActivityModel) activities;

    function borrowLoan(
        address lender,
        address borrower,
        uint256 amountBorrowedInUSD
    ) external onlyLendingPool {
        ActivityModel storage lenderActivity = activities[lender];
        ActivityModel storage borrowerActivity = activities[borrower];

        lenderActivity.lentTimes += 1;
        lenderActivity.lentVolume += amountBorrowedInUSD;
        lenderActivity.activeLoans += 1;

        lenderActivity.lastActive = block.timestamp;

        borrowerActivity.borrowedTimes += 1;
        borrowerActivity.borrowedVolume += amountBorrowedInUSD;
        borrowerActivity.activeLoans += 1;

        if (borrowerActivity.firstBorrowAt == 0) {
            borrowerActivity.firstBorrowAt = block.timestamp;
        }
    }

    function repayLoan(
        address lender,
        address borrower,
        uint256 interestPaidInUSD,
        bool completed
    ) external onlyLendingPool {
        ActivityModel storage lenderActivity = activities[lender];
        ActivityModel storage borrowerActivity = activities[borrower];

        borrowerActivity.interestPaidVolume += interestPaidInUSD;
        borrowerActivity.lastActive = block.timestamp;

        if (completed) {
            lenderActivity.activeLoans -= 1;
            borrowerActivity.activeLoans -= 1;
        }
    }

    function activeLoansCount(address user) external view returns(uint16) {
        return activities[user].activeLoans;
    }

    function dropCollateral(address borrower, uint256 amountInUSD)
        external
        onlyLendingPool
    {
        ActivityModel storage activity = activities[borrower];
        activity.collateralVolume += amountInUSD;
    }

    function isDefaulter(address user) external view returns (bool) {
        return activities[user].defaultedTimes > 0;
    }

    function getActivity(address user)
        external
        view
        returns (ActivityModel memory)
    {
        return activities[user];
    }

    function setLendingPool(address address_) public onlyOwner {
        lendingPool = address_;
    }

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool);
        _;
    }
}
