// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

abstract contract SimpleInterest  {
    /// @dev The units of precision equal to the minimum interest.
    uint256 public constant INTEREST_RATE_DENOMINATOR = 1e18;
    uint16 public constant PERCENT = 100;

    function getFullInterestAmount(
        uint256 principal,
        uint256 durationSecs,
        uint256 interest
    ) public pure virtual returns (uint256) {
        uint256 accrued = (principal * interest * durationSecs) /
            INTEREST_RATE_DENOMINATOR / PERCENT;

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

    function minimumBetween(uint256 a, uint256 b)
        private
        pure
        returns (uint256)
    {
        if (b > a) return a;
        return b;
    }
}
