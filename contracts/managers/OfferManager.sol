// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/PoolLibrary.sol";
import "../libraries/OfferLibrary.sol";
import "../libraries/RequestLibrary.sol";

import "../interfaces/IOfferManager.sol";

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract OfferManager is IOfferManager, Ownable2Step {
    using Counters for Counters.Counter;

    // offers
    Counters.Counter private offerIdTracker;
    mapping(uint256 => OfferLibrary.Offer) public offers;

    // request
    Counters.Counter private requestIdTracker;
    mapping(uint256 => RequestLibrary.Request) public requests;

    address lendingPool;

    constructor() Ownable2Step() {}

    // events for offers
    event OfferCreated(
        uint160 offerId,
        address principalToken,
        uint256 currentPrincipal,
        uint256 initialPrincipal,
        uint256 interest,
        uint16 daysToMaturity,
        uint160 expiresAt,
        uint160 createdAt,
        address creator,
        address[] collateralTokens,
        address collateralToken,
        uint256 currentCollateral,
        uint256 initialCollateral,
        OfferLibrary.Type offerType
    );

    // events for requests
    event RequestCreated(
        uint160 requestId,
        uint16 percentage,
        uint16 daysToMaturity,
        uint160 expiresAt,
        uint256 interest,
        uint160 createdAt,
        address creator,
        uint160 offerId,
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint160 ltvUsed,
        RequestLibrary.Type requestType
    );

    function createLendingOffer(
        address principalToken,
        uint256 principalAmount,
        uint256 interest,
        uint16 daysToMaturity,
        uint16 daysToExpire,
        address[] memory collateralTokens,
        address lender
    ) public onlyLendingPool returns (uint160) {
        offerIdTracker.increment();
        uint256 offerId = offerIdTracker.current();

        uint160 createdAt = uint160(block.timestamp);
        uint160 duration = uint160((daysToExpire * 1 days));
        uint160 expiresAt = createdAt + duration;

        offers[offerId] = OfferLibrary.Offer(
            // shared
            uint160(offerId),
            principalToken,
            principalAmount, // currentPrincipal
            principalAmount, // initialPrincipal
            interest,
            daysToMaturity,
            expiresAt,
            createdAt,
            lender,
            // related to lending offers only
            collateralTokens,
            // related to borrowing offers only
            address(0),
            0,
            0,
            // type
            OfferLibrary.Type.LENDING_OFFER
        );

        _emitOffer(uint160(offerId), offers[offerId]);
        return uint160(offerId);
    }

    function createLendingRequest(
        uint16 percentage,
        uint256 interest,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address lender,
        uint160 offerId
    ) public onlyLendingPool returns (uint160) {
        requestIdTracker.increment();
        uint256 requestId = requestIdTracker.current();

        uint160 createdAt = uint160(block.timestamp);
        uint160 duration = uint160((hoursToExpire * 1 hours));
        uint160 expiresAt = createdAt + duration;

        requests[requestId] = RequestLibrary.Request(
            // shared
            uint160(requestId),
            percentage,
            daysToMaturity,
            expiresAt,
            interest,
            createdAt,
            lender,
            offerId,
            // related to borrowing request only
            address(0),
            0,
            0,
            0,
            // type
            RequestLibrary.Type.LENDING_REQUEST
        );

        _emitRequest(uint160(requestId), requests[requestId]);
        return uint160(requestId);
    }

    function createBorrowingOffer(
        address principalToken,
        address collateralToken,
        uint256 collateralAmount,
        uint256 principalAmount,
        uint256 interest,
        uint16 daysToMaturity,
        uint16 daysToExpire,
        address borrower
    ) public onlyLendingPool returns (uint160) {
        offerIdTracker.increment();
        uint256 offerId = offerIdTracker.current();

        uint160 createdAt = uint160(block.timestamp);
        uint160 duration = uint160((daysToExpire * 1 days));
        uint160 expiresAt = createdAt + duration;

        offers[offerId] = OfferLibrary.Offer(
            uint160(offerId),
            principalToken,
            principalAmount, // currentPrincipal
            principalAmount, // initialPrincipal
            interest,
            daysToMaturity,
            expiresAt,
            createdAt,
            borrower,
            // related to lending offers only
            new address[](0),
            // related to borrowing offers only
            collateralToken,
            collateralAmount, // currentCollateral
            collateralAmount, //  initialCollateral
            // type
            OfferLibrary.Type.BORROWING_OFFER
        );

        _emitOffer(uint160(offerId), offers[offerId]);
        return uint160(offerId);
    }

    function createBorrowingRequest(
        uint16 percentage,
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint160 ltvUsed,
        uint256 interest,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address borrower,
        uint160 offerId
    ) public onlyLendingPool returns (uint160) {
        requestIdTracker.increment();
        uint256 requestId = requestIdTracker.current();

        uint160 createdAt = uint160(block.timestamp);
        uint160 duration = uint160((hoursToExpire * 1 hours));
        uint160 expiresAt = createdAt + duration;

        requests[requestId] = RequestLibrary.Request(
            // shared
            uint160(requestId),
            percentage,
            daysToMaturity,
            expiresAt,
            interest,
            createdAt,
            borrower,
            offerId,
            // related to borrowing request only
            collateralToken,
            collateralAmount,
            collateralPriceInUSD,
            ltvUsed,
            RequestLibrary.Type.BORROWING_REQUEST
        );

        _emitRequest(uint160(requestId), requests[requestId]);
        return uint160(requestId);
    }

    // events
    function _emitOffer(uint160 offerId, OfferLibrary.Offer memory offer)
        private
    {
        emit OfferCreated(
            offerId,
            offer.principalToken,
            offer.currentPrincipal,
            offer.initialPrincipal,
            offer.interest,
            offer.daysToMaturity,
            offer.expiresAt,
            offer.createdAt,
            offer.creator,
            offer.collateralTokens,
            offer.collateralToken,
            offer.currentCollateral,
            offer.initialCollateral,
            offer.offerType
        );
    }

    function _emitRequest(
        uint160 requestId,
        RequestLibrary.Request memory request
    ) private {
        emit RequestCreated(
            requestId,
            request.percentage,
            request.daysToMaturity,
            request.expiresAt,
            request.interest,
            request.createdAt,
            request.creator,
            request.offerId,
            request.collateralToken,
            request.collateralAmount,
            request.collateralPriceInUSD,
            request.ltvUsed,
            request.requestType
        );
    }

    // updaters
    function _afterOfferLendingLoan(uint160 offerId, uint256 principalAmount)
        public
        onlyLendingPool
    {
        OfferLibrary.Offer storage offer = offers[offerId];
        require(
            offer.offerType == OfferLibrary.Type.LENDING_OFFER,
            "ERR_OFFER_TYPE"
        );
        require(
            offer.currentPrincipal >= principalAmount,
            "ERR_INSUFFICIENT_PRINCIPAL"
        );
        require(offer.expiresAt > block.timestamp, "ERR_OFFER_EXPIRED");

        offers[offerId].currentPrincipal -= principalAmount;

        _emitOffer(offerId, offer);
    }

    function _afterOfferBorrowingLoan(
        uint160 offerId,
        uint256 principalAmount,
        uint256 collateralAmount
    ) public onlyLendingPool {
        OfferLibrary.Offer storage offer = offers[offerId];
        require(
            offer.offerType == OfferLibrary.Type.LENDING_OFFER,
            "ERR_OFFER_TYPE"
        );
        require(
            offer.currentPrincipal >= principalAmount,
            "ERR_INSUFFICIENT_PRINCIPAL"
        );
        require(
            offer.currentCollateral >= collateralAmount,
            "ERR_INSUFFICIENT_COLLATERAL"
        );
        require(offer.expiresAt > block.timestamp, "ERR_OFFER_EXPIRED");

        offer.currentPrincipal -= principalAmount;
        offer.currentCollateral -= collateralAmount;

        _emitOffer(offerId, offer);
    }

    function isCollateralSupported(uint160 offerId, address token)
        public
        view
        returns (bool)
    {
        OfferLibrary.Offer memory offer = offers[offerId];
        bool supported = false;
        for (
            uint256 index = 0;
            index < offer.collateralTokens.length;
            index++
        ) {
            if (offer.collateralTokens[index] == token) {
                supported = true;
                break;
            }
        }
        return supported;
    }

    // getters
    function getOffer(uint160 offerId)
        public
        view
        override
        returns (OfferLibrary.Offer memory)
    {
        return offers[offerId];
    }

    function getRequest(uint256 requestId)
        public
        view
        override
        returns (RequestLibrary.Request memory)
    {
        return requests[requestId];
    }

    function setLendingPool(address address_) public onlyOwner {
        lendingPool = address_;
    }

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool);
        _;
    }
}
