// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPriceFeed {
    function getLatestPriceUSD(address) external returns (uint256, uint8);

    function amountInUSD(address token, uint256 amount)
        external
        returns (uint256);

    function exchangeRate(
        address base,
        address quote,
        uint256 amount
    ) external returns (uint256);
}
