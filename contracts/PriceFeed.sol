// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./libraries/Errors.sol";
import "./interfaces/IPriceFeed.sol";

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// WBTC/USD -> 0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529
// WETH/USD -> 0xB8C458C957a6e6ca7Cc53eD95bEA548c52AFaA24
// FTM/USD -> 0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D

// USDT/USD -> 0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128
// USDC/USD -> 0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128
// DAI/USD -> 0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128

contract PriceFeed is Ownable2Step, IPriceFeed {
    mapping(address => address) feedAddresses;
    address USD = 0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128;

    event PriceFeedAdded(
        uint256 timestamp,
        address indexed token,
        address indexed priceFeed
    );

    constructor() Ownable2Step() {}

    /// @dev function for owner to add more price feeds
    function addPriceFeed(address token, address feed) external onlyOwner {
        feedAddresses[token] = feed;
        emit PriceFeedAdded(block.timestamp, token, feed);
    }

    /* Returns the latest price */
    function getLatestPriceUSD(address token)
        public
        view
        override
        returns (uint256, uint8)
    {
        require(feedAddresses[token] != address(0), "ERR_TOKEN_ADDRESS");

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            feedAddresses[token]
        );

        (, int256 answer, , , uint80 decimal) = priceFeed.latestRoundData();
        require(answer > 0, "ERR_ZERO_ANSWER");

        return (uint256(answer), uint8(decimal));
    }

    function amountInUSD(address token, uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        return exchangeRate(token, USD, amount);
    }

    function exchangeRate(
        address base,
        address quote,
        uint256 amount
    ) public view override returns (uint256) {
        (uint256 basePrice, ) = getLatestPriceUSD(base);
        (uint256 quotePrice, ) = getLatestPriceUSD(quote);

        return (basePrice * amount) / quotePrice;
    }
}
