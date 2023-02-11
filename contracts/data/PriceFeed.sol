// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IPriceFeed.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../libraries/Errors.sol";

contract PriceFeed is Ownable2Step, IPriceFeed {
    mapping(address => address) feedAddresses;

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

    /**
     * Returns the latest price
     */
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
