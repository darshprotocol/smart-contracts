// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract TrustScore is Ownable2Step {
    uint256 private POOR_PERCENTAGE;
    uint256 private GOOD_PERCENTAGE;
    uint256 private EXCELLENT_PERCENTAGE;

    enum Grade {
        POOR,
        GOOD,
        EXCELLENT
    }

    mapping(address => uint256) public percentages;

    constructor() Ownable2Step() {
        POOR_PERCENTAGE = 110;
        GOOD_PERCENTAGE = 90;
        EXCELLENT_PERCENTAGE = 80;
    }

    function updateScores(
        uint256 poorPercentage,
        uint256 goodPercentage,
        uint256 excellentPercentage
    ) public onlyOwner {
        require(poorPercentage > goodPercentage);
        require(goodPercentage > excellentPercentage);

        POOR_PERCENTAGE = poorPercentage;
        GOOD_PERCENTAGE = goodPercentage;
        EXCELLENT_PERCENTAGE = excellentPercentage;
    }

    function trustGrade(address user, uint256 pendingLoans)
        public
        view
        returns (Grade, uint256)
    {
        uint256 percentage = percentages[user];

        if (percentage == 0 || percentage >= POOR_PERCENTAGE) {
            return (Grade.POOR, POOR_PERCENTAGE);
        }
        if (percentage >= GOOD_PERCENTAGE) {
            if (pendingLoans > 0) {
                return (Grade.POOR, POOR_PERCENTAGE);
            }
            return (Grade.GOOD, GOOD_PERCENTAGE);
        }
        if (pendingLoans > 1) {
            return (Grade.POOR, POOR_PERCENTAGE);
        } else if (pendingLoans > 0) {
            return (Grade.GOOD, GOOD_PERCENTAGE);
        }
        return (Grade.EXCELLENT, EXCELLENT_PERCENTAGE);
    }

    function inverseTrustGrade(address user, uint256 pendingLoans)
        public
        view
        returns (Grade, uint256)
    {
        uint256 percentage = percentages[user];

        if (percentage == 0 || percentage >= POOR_PERCENTAGE) {
            return (Grade.EXCELLENT, EXCELLENT_PERCENTAGE);
        }
        if (percentage >= GOOD_PERCENTAGE) {
            if (pendingLoans > 0) {
                return (Grade.EXCELLENT, EXCELLENT_PERCENTAGE);
            }
            return (Grade.GOOD, GOOD_PERCENTAGE);
        }
        if (pendingLoans > 1) {
            return (Grade.EXCELLENT, EXCELLENT_PERCENTAGE);
        } else if (pendingLoans > 0) {
            return (Grade.GOOD, GOOD_PERCENTAGE);
        }
        return (Grade.POOR, POOR_PERCENTAGE);
    }
}
