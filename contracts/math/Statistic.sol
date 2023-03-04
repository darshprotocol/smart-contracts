// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Statistic {
    function calculateMean(uint256[] memory nums)
        public
        pure
        returns (uint256)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < nums.length; i++) {
            sum += nums[i];
        }

        if (sum == 0) return 0;
        return sum / nums.length;
    }

    function calculateVariance(uint256[] memory nums)
        public
        pure
        returns (uint256)
    {
        uint256 sum = 0;
        uint256 mean = calculateMean(nums);
        for (uint256 i = 0; i < nums.length; i++) {
            sum += (nums[i] - mean)**2;
        }

        if (sum == 0) return 0;
        return sum / nums.length;
    }

    function calculateStandardDeviation(uint256[] memory nums)
        public
        pure
        returns (uint256)
    {
        uint256 variance = calculateMean(nums);

        if (variance == 0) return 0;
        return sqrt(variance);
    }

    function sqrt(uint256 x) public pure returns (uint256) {
        if (x == 0) return 0;
        uint256 n = (x + 1) / 2;
        uint256 n1 = (n + x / n) / 2;
        while (n1 < n) {
            n = n1;
            n1 = (n + x / n) / 2;
        }
        return n;
    }
}
