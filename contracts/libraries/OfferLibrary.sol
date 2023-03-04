// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library OfferLibrary {
    enum Type {
        LENDING_OFFER,
        BORROWING_OFFER
    }

    enum State {
        DEFAULT,
        CANCELLED
    }

    event OfferCreated(
        uint256 offerId,
        State state,
        address principalToken,
        uint256 currentPrincipal,
        uint256 initialPrincipal,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint expiresAt,
        uint createdAt,
        address creator,
        address[] collateralTokens,
        address collateralToken,
        uint256 currentCollateral,
        uint256 initialCollateral,
        OfferLibrary.Type offerType
    );

    struct Offer {
        // shared attributes
        uint256 offerId;
        State state;
        address principalToken;
        uint256 currentPrincipal;
        uint256 initialPrincipal;
        uint256 interestRate;
        uint16 daysToMaturity;
        uint expiresAt;
        uint createdAt;
        address creator;
        // related to lending offers only
        address[] collateralTokens;
        // related to borrowing offers only
        address collateralToken;
        uint256 currentCollateral;
        uint256 initialCollateral;
        // type
        Type offerType;
    }
}
