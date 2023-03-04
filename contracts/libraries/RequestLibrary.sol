// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library RequestLibrary {
    enum Type {
        LENDING_REQUEST,
        BORROWING_REQUEST
    }

    enum State {
        PENDING,
        ACCEPTED,
        REJECTED,
        CANCELLED
    }

    event RequestCreated(
        uint256 requestId,
        State state,
        uint16 percentage,
        uint16 daysToMaturity,
        uint256 interestRate,
        uint expiresAt,
        uint createdAt,
        address creator,
        uint256 offerId,
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint160 ltvUsed,
        RequestLibrary.Type requestType
    );

    struct Request {
        // shared
        uint256 requestId;
        State state;
        uint16 percentage;
        uint16 daysToMaturity;
        uint256 interestRate;
        uint expiresAt;
        uint createdAt;
        address creator;
        uint256 offerId;
        // related to borrowing request only
        address collateralToken;
        uint256 collateralAmount;
        uint256 collateralPriceInUSD;
        uint160 ltvUsed;
        // type
        Type requestType;
    }
}
