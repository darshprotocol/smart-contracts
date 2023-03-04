// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract SimpleInterest {
    /// @dev The units of precision equal to the minimum interestRate.
    uint256 public constant INTEREST_RATE_DENOMINATOR = 1e18;
    uint16 public constant PERCENT = 100;

    function getFullInterestAmount(
        uint256 principal,
        uint256 durationSecs,
        uint256 interestRate
    ) public pure virtual returns (uint256) {
        uint256 accrued = (principal * interestRate * durationSecs) /
            INTEREST_RATE_DENOMINATOR /
            PERCENT;

        return principal + accrued;
    }

    function percentageOf(uint256 total, uint160 percent)
        public
        pure
        virtual
        returns (uint256)
    {
        if (percent == 0) return total;
        return (total * percent) / PERCENT;
    }

    function checkPercentage(uint16 percentage) public pure virtual {
        // percentage must be 25, 50, 75 or 100
        require(percentage <= 100, "OVER_PERCENTAGE");
        require(percentage % 25 == 0, "ERR_PERCENTAGE");
    }
}
