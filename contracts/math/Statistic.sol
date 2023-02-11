// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

library Statistic {
    function calculateMean(uint[] memory nums) internal pure returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < nums.length; i++) {
            sum += nums[i];
        }

        if (sum == 0) return 0;
        return sum / nums.length;
    }

    function calculateVariance(uint[] memory nums) internal pure returns (uint) {
        uint sum = 0;
        uint mean = calculateMean(nums);
        for (uint i = 0; i < nums.length; i++) {
            sum += (nums[i] - mean) ** 2;
        }

        if (sum == 0) return 0;
        return sum / nums.length;
    }

    function calculateStandardDeviation(uint[] memory nums) internal pure returns (uint) {
        uint variance = calculateMean(nums);

        if (variance == 0) return 0;
        return sqrt(variance);
    }

    function sqrt(uint x) internal pure returns (uint) {
        if (x == 0) return 0;
        uint n = (x + 1) / 2;
        uint n1 = (n + x / n) / 2;
        while (n1 < n) {
            n = n1;
            n1 = (n + x / n) / 2;
        }
        return n;
    }
}
