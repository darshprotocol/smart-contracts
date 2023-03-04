// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/OfferLibrary.sol";
import "../libraries/RequestLibrary.sol";

import "../interfaces/IOfferManager.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
    The OfferManager contract is responsible for bookeeping
    the offers and requests made.

    It can be only modified by the LendingPool contract,
    but can be read from external sources.

    Any OfferManager contract must inherite the IOfferManager interface.
*/

contract OfferManager is IOfferManager, Ownable2Step {
    uint256 public constant ONE_DAY = 60 * 60 * 24;
    uint256 public constant ONE_HOUR = 60 * 60;

    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // offers
    Counters.Counter private offerIdTracker;
    mapping(uint256 => OfferLibrary.Offer) public offers;

    // request
    Counters.Counter private requestIdTracker;
    mapping(uint256 => RequestLibrary.Request) public requests;

    address lendingPool;

    constructor() Ownable2Step() {}

    // creates a new lending offer
    function createLendingOffer(
        address principalToken,
        uint256 principalAmount,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 daysToExpire,
        address[] memory collateralTokens,
        address lender
    ) public override onlyLendingPool returns (uint256) {
        offerIdTracker.increment();
        uint256 offerId = offerIdTracker.current();

        uint256 createdAt = block.timestamp;
        uint256 duration = ONE_DAY.mul(daysToExpire);
        uint256 expiresAt = createdAt.add(duration);

        require(collateralTokens.length > 0, "ERR_NO_COLLATERAL_TYPES");

        offers[offerId] = OfferLibrary.Offer(
            // shared
            offerId,
            OfferLibrary.State.DEFAULT,
            principalToken,
            principalAmount, // currentPrincipal
            principalAmount, // initialPrincipal
            interestRate,
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

        _emitOffer(offerId, offers[offerId]);
        return offerId;
    }

    function reActivateOffer(
        uint256 offerId,
        uint16 toExpire,
        address user
    ) public override onlyLendingPool {
        OfferLibrary.Offer memory offer = offers[offerId];

        require(offer.creator == user, "ERR_ONLY_CREATOR");
        require(offer.initialCollateral == offer.currentCollateral);

        uint256 createdAt = block.timestamp;
        require(createdAt > offer.expiresAt, "ERR_NOT_EXPIRED");

        offerIdTracker.increment();

        uint256 duration;
        if (offer.offerType == OfferLibrary.Type.LENDING_OFFER) {
            duration = ONE_DAY.mul(toExpire);
        } else {
            duration = ONE_HOUR.mul(toExpire);
        }

        offer.expiresAt = createdAt + duration;
        offer.offerId = offerIdTracker.current();

        _emitOffer(offerId, offer);
    }

    // creates a new lending request
    function createLendingRequest(
        uint16 percentage,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address lender,
        uint256 offerId
    ) public override onlyLendingPool returns (uint256) {
        requestIdTracker.increment();
        uint256 requestId = requestIdTracker.current();

        uint256 createdAt = block.timestamp;
        uint256 duration = ONE_HOUR.mul(hoursToExpire);
        uint256 expiresAt = createdAt.add(duration);

        OfferLibrary.Offer memory offer = offers[offerId];

        require(
            offer.offerType == OfferLibrary.Type.BORROWING_OFFER,
            "ERR_OFFER_TYPE"
        );

        if (offer.initialCollateral == offer.currentCollateral) {
            require(createdAt < offers[offerId].expiresAt, "ERR_OFFER_EXPIRED");
        }

        requests[requestId] = RequestLibrary.Request(
            // shared
            requestId,
            RequestLibrary.State.PENDING,
            percentage,
            daysToMaturity,
            interestRate,
            expiresAt,
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

        _emitRequest(requestId, requests[requestId]);
        return requestId;
    }

    // creates a new borrowing offer
    function createBorrowingOffer(
        address principalToken,
        address collateralToken,
        uint256 collateralAmount,
        uint256 principalAmount,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address borrower
    ) public override onlyLendingPool returns (uint256) {
        offerIdTracker.increment();
        uint256 offerId = offerIdTracker.current();

        uint256 createdAt = block.timestamp;
        uint256 duration = ONE_HOUR.mul(hoursToExpire);
        uint256 expiresAt = createdAt.add(duration);

        offers[offerId] = OfferLibrary.Offer(
            offerId,
            OfferLibrary.State.DEFAULT,
            principalToken,
            principalAmount, // currentPrincipal
            principalAmount, // initialPrincipal
            interestRate,
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

        _emitOffer(offerId, offers[offerId]);
        return offerId;
    }

    // creates a new borrowing request
    function createBorrowingRequest(
        uint16 percentage,
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint160 ltvUsed,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address borrower,
        uint256 offerId
    ) public override onlyLendingPool returns (uint256) {
        requestIdTracker.increment();
        uint256 requestId = requestIdTracker.current();

        uint256 createdAt = block.timestamp;
        uint256 duration = ONE_HOUR.mul(hoursToExpire);
        uint256 expiresAt = createdAt.add(duration);

        OfferLibrary.Offer memory offer = offers[offerId];

        require(
            offer.offerType == OfferLibrary.Type.LENDING_OFFER,
            "ERR_OFFER_TYPE"
        );

        if (offer.initialCollateral == offer.currentCollateral) {
            require(createdAt < offers[offerId].expiresAt, "ERR_OFFER_EXPIRED");
        }

        requests[requestId] = RequestLibrary.Request(
            // shared
            requestId,
            RequestLibrary.State.PENDING,
            percentage,
            daysToMaturity,
            interestRate,
            expiresAt,
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

        _emitRequest(requestId, requests[requestId]);
        return requestId;
    }

    function rejectRequest(uint256 requestId, address user)
        public
        override
        onlyLendingPool
    {
        RequestLibrary.Request storage request = requests[requestId];
        OfferLibrary.Offer memory offer = offers[request.offerId];
        require(offer.creator == user, "ERR_ONLY_CREATOR");
        require(
            request.state == RequestLibrary.State.PENDING,
            "ERR_OFFER_STATE"
        );
        request.state = RequestLibrary.State.REJECTED;
        _emitRequest(requestId, request);
    }

    function acceptRequest(uint256 requestId, address user)
        public
        override
        onlyLendingPool
    {
        RequestLibrary.Request storage request = requests[requestId];
        OfferLibrary.Offer memory offer = offers[request.offerId];
        require(offer.creator == user, "ERR_ONLY_CREATOR");
        request.state = RequestLibrary.State.ACCEPTED;
        _emitRequest(requestId, request);
    }

    function cancelRequest(uint256 requestId, address user)
        public
        override
        onlyLendingPool
    {
        RequestLibrary.Request storage request = requests[requestId];
        require(request.creator == user, "ERR_ONLY_CREATOR");
        require(
            request.state != RequestLibrary.State.ACCEPTED,
            "ERR_ALREADY_USED"
        );
        require(
            request.state != RequestLibrary.State.CANCELLED,
            "ERR_ALREADY_CANCELLED"
        );
        request.state = RequestLibrary.State.CANCELLED;
        _emitRequest(requestId, request);
    }

    function removePrincipal(
        uint256 offerId,
        address user,
        uint256 amount
    ) public override onlyLendingPool {
        OfferLibrary.Offer storage offer = offers[offerId];
        require(
            offer.offerType == OfferLibrary.Type.LENDING_OFFER,
            "ERR_OFFER_TYPE"
        );
        require(offer.currentPrincipal >= amount, "INSUFICIENT_AMOUNT");
        require(offer.creator == user, "ERR_ONLY_LENDER");

        offer.currentPrincipal -= amount;

        if (amount == offer.initialPrincipal) {
            offer.state = OfferLibrary.State.CANCELLED;
        }

        _emitOffer(offerId, offer);
    }

    function removeCollateral(
        uint256 offerId,
        address user,
        uint256 amount
    ) public override onlyLendingPool {
        OfferLibrary.Offer storage offer = offers[offerId];
        require(
            offer.offerType == OfferLibrary.Type.BORROWING_OFFER,
            "ERR_OFFER_TYPE"
        );
        require(offer.currentCollateral >= amount, "INSUFICIENT_AMOUNT");
        require(offer.creator == user, "ERR_ONLY_LENDER");

        offer.currentCollateral -= amount;

        if (amount == offer.initialCollateral) {
            offer.state = OfferLibrary.State.CANCELLED;
        }

        _emitOffer(offerId, offer);
    }

    // events
    function _emitOffer(uint256 offerId, OfferLibrary.Offer memory offer)
        private
    {
        emit OfferLibrary.OfferCreated(
            offerId,
            offer.state,
            offer.principalToken,
            offer.currentPrincipal,
            offer.initialPrincipal,
            offer.interestRate,
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
        uint256 requestId,
        RequestLibrary.Request memory request
    ) private {
        emit RequestLibrary.RequestCreated(
            requestId,
            request.state,
            request.percentage,
            request.daysToMaturity,
            request.interestRate,
            request.expiresAt,
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

    // called after a lending offer loan is executed
    function afterLendingLoan(uint256 offerId, uint256 principalAmount)
        public
        override
        onlyLendingPool
    {
        OfferLibrary.Offer storage offer = offers[offerId];
        require(
            offer.currentPrincipal >= principalAmount,
            "ERR_INSUFFICIENT_PRINCIPAL"
        );

        if (offer.initialCollateral == offer.currentCollateral) {
            require(offer.expiresAt > block.timestamp, "ERR_OFFER_EXPIRED");
        }

        offers[offerId].currentPrincipal -= principalAmount;

        _emitOffer(offerId, offer);
    }

    // called after a borrowing offer loan is executed
    function afterBorrowingLoan(
        uint256 offerId,
        uint256 principalAmount,
        uint256 collateralAmount
    ) public override onlyLendingPool {
        OfferLibrary.Offer storage offer = offers[offerId];
        require(
            offer.currentPrincipal >= principalAmount,
            "ERR_INSUFFICIENT_PRINCIPAL"
        );
        require(
            offer.currentCollateral >= collateralAmount,
            "ERR_INSUFFICIENT_COLLATERAL"
        );

        if (offer.initialCollateral == offer.currentCollateral) {
            require(offer.expiresAt > block.timestamp, "ERR_OFFER_EXPIRED");
        }

        offer.currentPrincipal -= principalAmount;
        offer.currentCollateral -= collateralAmount;

        _emitOffer(offerId, offer);
    }

    // checks if a offer support collateral token
    function isCollateralSupported(uint256 offerId, address token)
        public
        view
        override
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
    function getOffer(uint256 offerId)
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
