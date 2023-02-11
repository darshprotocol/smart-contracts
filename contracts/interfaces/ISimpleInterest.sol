// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface ISimpleInterest {
    function getFullInterestAmount(
        uint256 principal,
        uint256 durationSecs,
        uint256 interest
    ) external returns (uint256);

    function percentageOf(uint256 total, uint256 percent)
        external
        returns (uint256);
}
