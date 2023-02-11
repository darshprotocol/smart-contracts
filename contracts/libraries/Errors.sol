// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

library Errors {
    string public constant PRICE_FEED_TOKEN_NOT_SUPPORTED = "100"; // Token is not supported
    string public constant PRICE_FEED_TOKEN_BELOW_ZERO = "101"; // Token below zero price
}