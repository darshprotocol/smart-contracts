// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./Activity.sol";
import "./interfaces/ITrustScore.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract TrustScore is Ownable2Step, ITrustScore {
    Activity private _activity;

    constructor() Ownable2Step() {}

    function getScore(address user) public view override returns (uint16) {
        Activity.ActivityModel memory activity = _activity.getActivity(user);
        uint16 result;

        // repaymentTimes
        if (activity.repaymentTimes > 30) {
            result += 0;
        } else if (activity.repaymentTimes > 21) {
            result += 1;
        } else if (activity.repaymentTimes > 13) {
            result += 3;
        } else if (activity.repaymentTimes > 7) {
            result += 5;
        } else if (activity.repaymentTimes > 3) {
            result += 7;
        } else {
            result += 8;
        }

        // repaymentVolume
        if (activity.repaymentVolume > 2000 * 1e18) {
            result += 0;
        } else if (activity.repaymentVolume > 1600 * 1e18) {
            result += 3;
        } else if (activity.repaymentVolume > 1300 * 1e18) {
            result += 5;
        } else if (activity.repaymentVolume > 1100 * 1e18) {
            result += 8;
        } else if (activity.repaymentVolume > 900 * 1e18) {
            result += 9;
        } else if (activity.repaymentVolume > 600 * 1e18) {
            result += 11;
        } else if (activity.repaymentVolume > 400 * 1e18) {
            result += 12;
        } else if (activity.repaymentVolume > 250 * 1e18) {
            result += 13;
        } else if (activity.repaymentVolume > 100 * 1e18) {
            result += 14;
        } else {
            result += 15;
        }

        // borrowedTimes
        if (activity.borrowedTimes > 26) {
            result += 0;
        } else if (activity.borrowedTimes > 18) {
            result += 1;
        } else if (activity.borrowedTimes > 10) {
            result += 3;
        } else if (activity.borrowedTimes > 5) {
            result += 5;
        } else if (activity.borrowedTimes > 2) {
            result += 6;
        } else {
            result += 7;
        }

        // borrowedVolume
        if (activity.borrowedVolume > 2000 * 1e18) {
            result += 0;
        } else if (activity.borrowedVolume > 1600 * 1e18) {
            result += 1;
        } else if (activity.borrowedVolume > 1300 * 1e18) {
            result += 2;
        } else if (activity.borrowedVolume > 1100 * 1e18) {
            result += 3;
        } else if (activity.borrowedVolume > 900 * 1e18) {
            result += 4;
        } else if (activity.borrowedVolume > 600 * 1e18) {
            result += 6;
        } else if (activity.borrowedVolume > 400 * 1e18) {
            result += 7;
        } else if (activity.borrowedVolume > 250 * 1e18) {
            result += 8;
        } else if (activity.borrowedVolume > 100 * 1e18) {
            result += 9;
        } else {
            result += 10;
        }

        // lastActive
        uint160 currentTime = uint160(block.timestamp);

        if (activity.lastActive == 0) {
            result += 10;
        } else if ((activity.lastActive + 20 days) < currentTime) {
            result += 0;
        } else if ((activity.lastActive + 35 days) < currentTime) {
            result += 4;
        } else if ((activity.lastActive + 50 days) < currentTime) {
            result += 7;
        } else {
            result += 10;
        }

        // collateralVolume
        if (activity.collateralVolume > 2000 * 1e18) {
            result += 0;
        } else if (activity.collateralVolume > 1600 * 1e18) {
            result += 1;
        } else if (activity.collateralVolume > 1300 * 1e18) {
            result += 2;
        } else if (activity.collateralVolume > 1100 * 1e18) {
            result += 3;
        } else if (activity.collateralVolume > 900 * 1e18) {
            result += 4;
        } else if (activity.collateralVolume > 600 * 1e18) {
            result += 6;
        } else if (activity.collateralVolume > 400 * 1e18) {
            result += 7;
        } else if (activity.collateralVolume > 250 * 1e18) {
            result += 8;
        } else if (activity.collateralVolume > 100 * 1e18) {
            result += 9;
        } else {
            result += 10;
        }

        // interestPaidVolume
        if (activity.interestPaidVolume > 150 * 1e18) {
            result += 0;
        } else if (activity.interestPaidVolume > 100 * 1e18) {
            result += 3;
        } else if (activity.interestPaidVolume > 80 * 1e18) {
            result += 5;
        } else if (activity.interestPaidVolume > 60 * 1e18) {
            result += 8;
        } else if (activity.interestPaidVolume > 45 * 1e18) {
            result += 9;
        } else if (activity.interestPaidVolume > 25 * 1e18) {
            result += 11;
        } else if (activity.interestPaidVolume > 15 * 1e18) {
            result += 12;
        } else if (activity.interestPaidVolume > 10 * 1e18) {
            result += 13;
        } else if (activity.interestPaidVolume > 5 * 1e18) {
            result += 14;
        } else {
            result += 15;
        }

        // defaultedTimes
        if (activity.defaultedTimes == 0) {
            result += 0;
        } else if (activity.defaultedTimes == 1) {
            result += 5;
        } else {
            result += 10;
        }

        // defaultedVolume
        if (activity.defaultedVolume == 0) {
            result += 0;
        } else if (activity.defaultedVolume <= 20 * 1e18) {
            result += 10;
        } else {
            result += 15;
        }

        return result;
    }

    function setActivity(address activity_) public onlyOwner {
        _activity = Activity(activity_);
    }
}
