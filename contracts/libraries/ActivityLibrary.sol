// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library ActivityLibrary {
    event ActivityChanged(
        address user,
        uint16 borrowedTimes,
        uint16 lentTimes,
        uint256 borrowedVolume,
        uint256 lentVolume,
        uint256 lastActive,
        uint256 collateralVolume,
        uint256 interestPaidVolume,
        uint16 defaultedTimes,
        uint256 defaultedVolume,
        uint256 firstBorrowAt,
        uint16 activeLoans
    );

    struct Model {
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
}
