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

        // repaymentTimes - 15 marks
        if (_activity.pendingLoansCount(user) > 2) {
            result += 15;
        } else if (_activity.pendingLoansCount(user) == 2) {
            result += 10;
        } else if (_activity.pendingLoansCount(user) == 1) {
            result += 5;
        } else if (activity.repaymentTimes > 30) {
            result += 0;
        } else if (activity.repaymentTimes > 21) {
            result += 2;
        } else if (activity.repaymentTimes > 13) {
            result += 4;
        } else if (activity.repaymentTimes > 7) {
            result += 6;
        } else if (activity.repaymentTimes > 3) {
            result += 8;
        } else {
            result += 10;
        }

        // repaymentVolume - 20 marks
        if (_activity.pendingLoansCount(user) > 2) {
            result += 20;
        } else if (_activity.pendingLoansCount(user) == 2) {
            result += 15;
        } else if (_activity.pendingLoansCount(user) == 1) {
            result += 10;
        } else if (activity.repaymentVolume > 35000 * 1e18) {
            result += 0;
        } else if (activity.repaymentVolume > 25000 * 1e18) {
            result += 3;
        } else if (activity.repaymentVolume > 16000 * 1e18) {
            result += 6;
        } else if (activity.repaymentVolume > 12000 * 1e18) {
            result += 8;
        } else if (activity.repaymentVolume > 9000 * 1e18) {
            result += 10;
        } else if (activity.repaymentVolume > 6000 * 1e18) {
            result += 12;
        } else if (activity.repaymentVolume > 3500 * 1e18) {
            result += 14;
        } else if (activity.repaymentVolume > 2000 * 1e18) {
            result += 16;
        } else if (activity.repaymentVolume > 500 * 1e18) {
            result += 18;
        } else {
            result += 20;
        }

        // borrowedTimes - 10 marks
        if (_activity.pendingLoansCount(user) > 2) {
            result += 10;
        } else if (_activity.pendingLoansCount(user) == 2) {
            result += 6;
        } else if (_activity.pendingLoansCount(user) == 1) {
            result += 3;
        } else if (activity.borrowedTimes > 26) {
            result += 0;
        } else if (activity.borrowedTimes > 18) {
            result += 2;
        } else if (activity.borrowedTimes > 10) {
            result += 4;
        } else if (activity.borrowedTimes > 5) {
            result += 6;
        } else if (activity.borrowedTimes > 2) {
            result += 8;
        } else {
            result += 10;
        }

        // borrowedVolume - 10 marks
        if (_activity.pendingLoansCount(user) > 2) {
            result += 10;
        } else if (_activity.pendingLoansCount(user) == 2) {
            result += 8;
        } else if (_activity.pendingLoansCount(user) == 1) {
            result += 6;
        } else if (activity.borrowedVolume > 35000 * 1e18) {
            result += 0;
        } else if (activity.borrowedVolume > 25000 * 1e18) {
            result += 1;
        } else if (activity.borrowedVolume > 16000 * 1e18) {
            result += 2;
        } else if (activity.borrowedVolume > 12000 * 1e18) {
            result += 3;
        } else if (activity.borrowedVolume > 9000 * 1e18) {
            result += 4;
        } else if (activity.borrowedVolume > 6000 * 1e18) {
            result += 6;
        } else if (activity.borrowedVolume > 3500 * 1e18) {
            result += 7;
        } else if (activity.borrowedVolume > 2000 * 1e18) {
            result += 8;
        } else if (activity.borrowedVolume > 500 * 1e18) {
            result += 9;
        } else {
            result += 10;
        }

        // collateralVolume - 15 marks
        if (_activity.pendingLoansCount(user) > 2) {
            result += 15;
        } else if (_activity.pendingLoansCount(user) == 2) {
            result += 10;
        } else if (_activity.pendingLoansCount(user) == 1) {
            result += 5;
        } else if (activity.collateralVolume > 35000 * 1e18) {
            result += 0;
        } else if (activity.collateralVolume > 25000 * 1e18) {
            result += 1;
        } else if (activity.collateralVolume > 16000 * 1e18) {
            result += 2;
        } else if (activity.collateralVolume > 12000 * 1e18) {
            result += 3;
        } else if (activity.collateralVolume > 9000 * 1e18) {
            result += 5;
        } else if (activity.collateralVolume > 6000 * 1e18) {
            result += 7;
        } else if (activity.collateralVolume > 3500 * 1e18) {
            result += 9;
        } else if (activity.collateralVolume > 2000 * 1e18) {
            result += 11;
        } else if (activity.collateralVolume > 500 * 1e18) {
            result += 13;
        } else {
            result += 15;
        }

        // interestPaidVolume - 20 marks
        if (_activity.pendingLoansCount(user) > 2) {
            result += 20;
        } else if (_activity.pendingLoansCount(user) == 2) {
            result += 15;
        } else if (_activity.pendingLoansCount(user) == 1) {
            result += 10;
        } else if (activity.interestPaidVolume > 150 * 1e18) {
            result += 0;
        } else if (activity.interestPaidVolume > 120 * 1e18) {
            result += 2;
        } else if (activity.interestPaidVolume > 100 * 1e18) {
            result += 4;
        } else if (activity.interestPaidVolume > 80 * 1e18) {
            result += 6;
        } else if (activity.interestPaidVolume > 60 * 1e18) {
            result += 8;
        } else if (activity.interestPaidVolume > 45 * 1e18) {
            result += 10;
        } else if (activity.interestPaidVolume > 25 * 1e18) {
            result += 12;
        } else if (activity.interestPaidVolume > 15 * 1e18) {
            result += 14;
        } else if (activity.interestPaidVolume > 10 * 1e18) {
            result += 16;
        } else if (activity.interestPaidVolume > 5 * 1e18) {
            result += 18;
        } else {
            result += 20;
        }

        // stars - 10 marks
        if (activity.stars > 5) {
            result += 0;
        } else if (activity.stars > 3) {
            result += 2;
        } else if (activity.stars > 2) {
            result += 4;
        } else if (activity.stars > 1) {
            result += 6;
        } else if (activity.stars > 0) {
            result += 8;
        } else {
            result += 10;
        }

        // EXTRA -- MARKS

        // defaultedTimes - 50 marks
        if (activity.defaultedTimes == 0) {
            result += 0;
        } else if (activity.defaultedTimes == 1) {
            result += 15;
        } else if (activity.defaultedTimes == 2) {
            result += 25;
        } else {
            result += 50;
        }

        // defaultedVolume - 50 marks
        if (activity.defaultedVolume == 0) {
            result += 0;
        } else if (activity.defaultedVolume <= 20 * 1e18) {
            result += 15;
        } else if (activity.defaultedVolume <= 50 * 1e18) {
            result += 25;
        } else {
            result += 50;
        }

        // lastActive - 5 ~ 10 marks
        uint160 currentTime = uint160(block.timestamp);

        if (activity.lastActive == 0) {
            result += 5;
        } else if ((activity.lastActive + 15 days) < currentTime) {
            result += 0;
        } else if ((activity.lastActive + 25 days) < currentTime) {
            result += 4;
        } else if ((activity.lastActive + 45 days) < currentTime) {
            result += 7;
        } else {
            result += 10;
        }

        return result;
    }

    function setActivity(address activity_) public onlyOwner {
        _activity = Activity(activity_);
    }
}
