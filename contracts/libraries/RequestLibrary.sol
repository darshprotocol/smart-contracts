// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./PoolLibrary.sol";

library RequestLibrary {
    enum Type {
        LENDING_REQUEST,
        BORROWING_REQUEST
    }

    struct Request {
        // shared
        uint160 requestId;
        uint16 percentage;
        uint16 daysToMaturity;
        uint160 expiresAt;
        uint256 interest;
        uint160 createdAt;
        address creator;
        uint160 offerId;
        // related to borrowing request only
        address collateralToken;
        uint256 collateralAmount;
        uint256 collateralPriceInUSD;
        uint160 ltvUsed;
        // type
        Type requestType;
    }
}
