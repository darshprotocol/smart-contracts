// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./AssetLibrary.sol";

library RequestLibrary {

    enum Type { 
        LENDING_REQUEST,
        BORROWING_REQUEST
    }

    struct LendingRequest {
        uint requestId;
        uint interest;
        uint desiredPercentage;
        uint daysToMaturity;
        uint expiresAt;
        uint createdAt;
        address lender;
        uint offerId;
    }

    struct BorrowingRequest {
        uint requestId;
        uint256 collateral;
        AssetLibrary.Type collateralType;
        uint interest;
        uint daysToMaturity;
        uint expiresAt;
        uint createdAt;
        address borrower;
        uint offerId;
    }

}