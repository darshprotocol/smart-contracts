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
    Counters.Counter private lendingOfferIdTracker;
    Counters.Counter private borrowingOfferIdTracker;

    mapping(uint256 => OfferLibrary.LendingOffer) public lendingOffers;
    mapping(uint256 => OfferLibrary.BorrowingOffer) public borrowingOffers;

    // request
    Counters.Counter private lendingRequestIdTracker;
    Counters.Counter private borrowingRequestIdTracker;

    mapping(uint256 => RequestLibrary.LendingRequest) public lendingRequests;
    mapping(uint256 => RequestLibrary.BorrowingRequest)
        public borrowingRequests;

    address lendingPool;

    constructor() Ownable2Step() {}

    // events for offers
    event LendingOfferCreated(
        uint160 offerId,
        address principalToken,
        uint256 currentPrincipal,
        uint256 initialPrincipal,
        uint256 interest,
        uint16 daysToMaturity,
        address[] collateralTokens,
        uint160 expiresAt,
        uint160 createdAt,
        address lender
    );

    event BorrowingOfferCreated(
        uint160 offerId,
        address principalToken,
        address collateralToken,
        uint256 initialCollateral,
        uint256 currentCollateral,
        uint256 interest,
        uint16 daysToMaturity,
        uint160 expiresAt,
        uint160 createdAt,
        address borrower
    );

    // events for requests
    event LendingRequestCreated(
        uint160 requestId,
        uint16 percentage,
        uint16 daysToMaturity,
        uint160 expiresAt,
        uint256 interest,
        uint160 createdAt,
        address lender,
        uint160 offerId
    );

    event BorrowingRequestCreated(
        uint160 requestId,
        uint16 percentage,
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint16 daysToMaturity,
        uint160 expiresAt,
        uint256 interest,
        uint160 createdAt,
        address borrower,
        uint160 offerId
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
        lendingOfferIdTracker.increment();
        uint256 offerId = lendingOfferIdTracker.current();

        uint160 createdAt = uint160(block.timestamp);
        uint160 duration = uint160((daysToExpire * 1 days));
        uint160 expiresAt = createdAt + duration;

        lendingOffers[offerId] = OfferLibrary.LendingOffer(
            uint160(offerId),
            principalToken,
            principalAmount, // currentPrincipal
            principalAmount, // initialPrincipal
            interest,
            daysToMaturity,
            collateralTokens,
            expiresAt,
            createdAt,
            lender
        );

        _emitLendingOffer(uint160(offerId), lendingOffers[offerId]);
        return uint160(offerId);
    }

    function createLendingRequest(
        uint16 percentage,
        uint256 interest,
        uint16 daysToMaturity,
        uint16 daysToExpire,
        address lender,
        uint160 offerId
    ) public onlyLendingPool returns (uint160) {
        lendingRequestIdTracker.increment();
        uint256 requestId = lendingRequestIdTracker.current();

        uint160 createdAt = uint160(block.timestamp);
        uint160 duration = uint160((daysToExpire * 1 days));
        uint160 expiresAt = createdAt + duration;

        lendingRequests[offerId] = RequestLibrary.LendingRequest(
            uint160(requestId),
            percentage,
            daysToMaturity,
            expiresAt,
            interest,
            createdAt,
            lender,
            offerId
        );

        _emitLendingRequest(uint160(requestId), lendingRequests[requestId]);
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
        borrowingOfferIdTracker.increment();
        uint256 offerId = borrowingOfferIdTracker.current();

        uint160 createdAt = uint160(block.timestamp);
        uint160 duration = uint160((daysToExpire * 1 days));
        uint160 expiresAt = createdAt + duration;

        borrowingOffers[offerId] = OfferLibrary.BorrowingOffer(
            uint160(offerId),
            principalToken,
            collateralToken,
            collateralAmount, // currentCollateral
            collateralAmount, // initialCollateral
            principalAmount, // currentPrincipal
            principalAmount, // initialPrincipal
            interest,
            daysToMaturity,
            expiresAt,
            createdAt,
            borrower
        );

        _emitBorrowingOffer(uint160(offerId), borrowingOffers[offerId]);
        return uint160(offerId);
    }

    function createBorrowingRequest(
        uint16 percentage,
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint256 interest,
        uint16 daysToMaturity,
        uint16 daysToExpire,
        address borrower,
        uint160 offerId
    ) public onlyLendingPool returns (uint160) {
        borrowingRequestIdTracker.increment();
        uint256 requestId = borrowingRequestIdTracker.current();

        uint160 createdAt = uint160(block.timestamp);
        uint160 duration = uint160((daysToExpire * 1 days));
        uint160 expiresAt = createdAt + duration;

        borrowingRequests[offerId] = RequestLibrary.BorrowingRequest(
            uint160(requestId),
            percentage,
            collateralToken,
            collateralAmount,
            collateralPriceInUSD,
            daysToMaturity,
            expiresAt,
            interest,
            createdAt,
            borrower,
            offerId
        );

        _emitBorrowingRequest(uint160(requestId), borrowingRequests[requestId]);
        return uint160(requestId);
    }

    // events
    function _emitLendingOffer(
        uint160 offerId,
        OfferLibrary.LendingOffer memory offer
    ) private {
        emit LendingOfferCreated(
            offerId,
            offer.principalToken,
            offer.currentPrincipal,
            offer.initialPrincipal,
            offer.interest,
            offer.daysToMaturity,
            offer.collateralTokens,
            offer.expiresAt,
            offer.createdAt,
            offer.lender
        );
    }

    function _emitBorrowingOffer(
        uint160 offerId,
        OfferLibrary.BorrowingOffer memory offer
    ) private {
        emit BorrowingOfferCreated(
            offerId,
            offer.principalToken,
            offer.collateralToken,
            offer.currentCollateral,
            offer.initialCollateral,
            offer.interest,
            offer.daysToMaturity,
            offer.expiresAt,
            offer.createdAt,
            offer.borrower
        );
    }

    function _emitLendingRequest(
        uint160 requestId,
        RequestLibrary.LendingRequest memory request
    ) private {
        emit LendingRequestCreated(
            requestId,
            request.percentage,
            request.daysToMaturity,
            request.expiresAt,
            request.interest,
            request.createdAt,
            request.lender,
            request.offerId
        );
    }

    function _emitBorrowingRequest(
        uint160 requestId,
        RequestLibrary.BorrowingRequest memory request
    ) private {
        emit BorrowingRequestCreated(
            requestId,
            request.percentage,
            request.collateralToken,
            request.collateralAmount,
            request.collateralPriceInUSD,
            request.daysToMaturity,
            request.expiresAt,
            request.interest,
            request.createdAt,
            request.borrower,
            request.offerId
        );
    }

    // updaters
    function _afterOfferLendingLoan(uint160 offerId, uint256 principalAmount)
        public
        onlyLendingPool
    {
        OfferLibrary.LendingOffer storage offer = lendingOffers[offerId];
        require(
            offer.currentPrincipal >= principalAmount,
            "ERR_INSUFFICIENT_PRINCIPAL"
        );
        require(offer.expiresAt > block.timestamp, "ERR_OFFER_EXPIRED");

        lendingOffers[offerId].currentPrincipal -= principalAmount;

        _emitLendingOffer(offerId, offer);
    }

    function _afterOfferBorrowingLoan(
        uint160 offerId,
        uint256 principalAmount,
        uint256 collateralAmount
    ) public onlyLendingPool {
        OfferLibrary.BorrowingOffer storage offer = borrowingOffers[offerId];
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

        _emitBorrowingOffer(offerId, offer);
    }
    
    function isCollateralSupported(uint160 offerId, address token)
        public
        view
        returns (bool)
    {
        OfferLibrary.LendingOffer memory offer = lendingOffers[offerId];
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
    function getLendingOffer(uint160 offerId)
        public
        view
        override
        returns (OfferLibrary.LendingOffer memory)
    {
        return lendingOffers[offerId];
    }

    function getBorrowingOffer(uint160 offerId)
        public
        view
        override
        returns (OfferLibrary.BorrowingOffer memory)
    {
        return borrowingOffers[offerId];
    }

    function getBorrowingRequest(uint256 requestId)
        public
        view
        override
        returns (RequestLibrary.BorrowingRequest memory)
    {
        return borrowingRequests[requestId];
    }

    function getLendingRequest(uint256 requestId)
        public
        view
        override
        returns (RequestLibrary.LendingRequest memory)
    {
        return lendingRequests[requestId];
    }

    function setLendingPool(address address_) public onlyOwner {
        lendingPool = address_;
    }

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool);
        _;
    }
}
