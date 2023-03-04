// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./libraries/ActivityLibrary.sol";

import "./interfaces/IActivity.sol";

import "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title Activity contract
/// @author Arogundade Ibrahim
/// @notice Keeps record of every user's activity on the LendingPool contract
/// @dev These records are use to calculate user's darsh score
contract Activity is Ownable2Step, IActivity {
    address lendingPool;

    constructor() Ownable2Step() {}

    mapping(address => ActivityLibrary.Model) activities;

    function borrowLoan(
        address lender,
        address borrower,
        uint256 amountBorrowedInUSD
    ) public override onlyLendingPool {
        ActivityLibrary.Model storage lenderActivity = activities[lender];
        ActivityLibrary.Model storage borrowerActivity = activities[borrower];

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

        _emitActivity(lenderActivity, lender);
        _emitActivity(borrowerActivity, borrower);
    }

    function repayLoan(
        address lender,
        address borrower,
        uint256 interestPaidInUSD,
        bool completed
    ) external onlyLendingPool {
        ActivityLibrary.Model storage lenderActivity = activities[lender];
        ActivityLibrary.Model storage borrowerActivity = activities[borrower];

        borrowerActivity.interestPaidVolume += interestPaidInUSD;
        borrowerActivity.lastActive = block.timestamp;

        if (completed) {
            lenderActivity.activeLoans -= 1;
            borrowerActivity.activeLoans -= 1;
        }

        _emitActivity(lenderActivity, lender);
        _emitActivity(borrowerActivity, borrower);
    }

    function activeLoansCount(address user)
        public
        view
        override
        returns (uint16)
    {
        return activities[user].activeLoans;
    }

    function dropCollateral(address borrower, uint256 amountInUSD)
        public
        override
        onlyLendingPool
    {
        ActivityLibrary.Model storage activity = activities[borrower];
        activity.collateralVolume += amountInUSD;

        _emitActivity(activity, borrower);
    }

    function isDefaulter(address user) public view override returns (bool) {
        return activities[user].defaultedTimes > 0;
    }

    function getActivity(address user)
        public
        view
        override
        returns (ActivityLibrary.Model memory)
    {
        return activities[user];
    }

    function _emitActivity(ActivityLibrary.Model memory activity, address user)
        private
    {
        emit ActivityLibrary.ActivityChanged(
            user,
            activity.borrowedTimes,
            activity.lentTimes,
            activity.borrowedVolume,
            activity.lentVolume,
            activity.lastActive,
            activity.collateralVolume,
            activity.interestPaidVolume,
            activity.defaultedTimes,
            activity.defaultedVolume,
            activity.firstBorrowAt,
            activity.activeLoans
        );
    }

    function setLendingPool(address address_) public onlyOwner {
        lendingPool = address_;
    }

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool);
        _;
    }
}
