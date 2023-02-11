// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IPriceFeed {
    function getLatestPriceUSD(address) external returns (uint256, uint8);

    function exchangeRate(
        address base,
        address quote,
        uint256 amount
    ) external returns (uint256);
}
