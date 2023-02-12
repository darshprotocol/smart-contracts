// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./PoolLibrary.sol";

library RequestLibrary {

    enum Type { 
        LENDING_REQUEST,
        BORROWING_REQUEST
    }

    struct LendingRequest {
        uint160 requestId;
        uint16 percentage;
        uint16 daysToMaturity;
        uint160 expiresAt;
        uint256 interest;
        uint160 createdAt;
        address lender;
        uint160 offerId;
    }

    struct BorrowingRequest {
        uint160 requestId;
        uint16 percentage;
        address collateralToken;
        uint256 collateralAmount;
        uint256 collateralPriceInUSD;
        uint16 daysToMaturity;
        uint160 expiresAt;
        uint256 interest;
        uint160 createdAt;
        address borrower;
        uint160 offerId;
    }

}