// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./AssetLibrary.sol";

library OfferLibrary {
    enum Type {
        LENDING_OFFER,
        BORROWING_OFFER
    }

    struct LendingOffer {
        uint256 offerId;
        AssetLibrary.Type principalType;
        uint256 currentPrincipal;
        uint256 initialPrincipal;
        uint256 interest;
        uint daysToMaturity;
        AssetLibrary.Type[] collateralTypes;
        uint160 expiresAt;
        uint160 createdAt;
        address lender;
    }

    struct BorrowingOffer {
        uint256 offerId;
        AssetLibrary.Type principalType;
        AssetLibrary.Type collateralType;
        uint256 currentCollateral;
        uint256 initialCollateral;
        uint256 interest;
        uint daysToMaturity;
        uint160 expiresAt;
        uint160 createdAt;
        address borrower;
    }
}
