// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./../interfaces/ISimpleInterest.sol";

abstract contract SimpleInterest is ISimpleInterest {
    /// @dev The units of precision equal to the minimum interest.
    uint256 public constant INTEREST_RATE_DENOMINATOR = 1e18;

    function getFullInterestAmount(
        uint256 principal,
        uint256 durationSecs,
        uint256 interest
    ) public pure virtual returns (uint256) {
        uint256 accrued = (principal * interest * durationSecs) /
            INTEREST_RATE_DENOMINATOR;

        return principal + accrued;
    }

    function percentageOf(uint256 total, uint160 percent)
        public
        pure
        virtual
        returns (uint256)
    {
        if (percent == 0) return total;
        return (total * percent) / 100;
    }

    function percentageInverseOf(uint256 total, uint160 percent)
        public
        pure
        virtual
        returns (uint256)
    {
        require(percent >= 100);
        uint160 diff = percent - 100;
        uint160 percentage = 100 - diff;
        return percentageOf(total, percentage);
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
