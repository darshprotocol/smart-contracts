// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Activity is Ownable2Step {
    address lendingPool;

    constructor() Ownable2Step() {}

    /*
        The activity contract keeps record of every
        users wallet address activity on the lending pool.

        These data and other externally sourced data are used to calculate
        the creditworthiness of a borrower's wallet address.
    */

    struct ActivityModel {
        // frequency
        uint16 repaymentTimes;
        uint16 borrowedTimes;
        // volume
        uint256 borrowedVolume;
        uint256 repaymentVolume;
        // active
        uint160 lastActive;
        // collateral
        uint256 collateralVolume;
        // interest
        uint256 interestPaidVolume;
        // defaulting
        uint16 defaultedTimes;
        uint256 defaultedVolume;
        // first borrow date
        uint160 firstBorrowAt;
        // hero stars collected
        uint16 stars;
    }

    mapping(address => ActivityModel) activities;

    function _borrowLoan(address user, uint256 amountBorrowedInUSD)
        external
        onlyLendingPool
    {
        ActivityModel storage activity = activities[user];
        activity.borrowedTimes += 1;
        activity.borrowedVolume += amountBorrowedInUSD;
        activity.lastActive = uint160(block.timestamp);
        if (activity.firstBorrowAt == 0) {
            activity.firstBorrowAt = uint160(block.timestamp);
        }
    }

    function _repayLoan(
        address user,
        uint256 amountPaidInUSD,
        uint256 interestPaidInUSD,
        bool completed
    ) external onlyLendingPool {
        ActivityModel storage activity = activities[user];
        activity.repaymentVolume += amountPaidInUSD;
        activity.interestPaidVolume += interestPaidInUSD;
        activity.lastActive = uint160(block.timestamp);
        
        if (completed) {
            activity.repaymentTimes += 1;
        }
    }

    function _dropCollateral(address user, uint256 amountInUSD)
        external
        onlyLendingPool
    {
        ActivityModel storage activity = activities[user];
        activity.collateralVolume += amountInUSD;
        activity.lastActive = uint160(block.timestamp);
    }

    function pendingLoansCount(address user) external view returns (uint16) {
        return activities[user].borrowedTimes - activities[user].repaymentTimes;
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
