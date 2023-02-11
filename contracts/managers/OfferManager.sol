// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/AssetLibrary.sol";
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

    event LendingOfferCreated(
        uint256 offerId,
        address principalToken,
        uint256 currentPrincipal,
        uint256 initialPrincipal,
        uint256 interest,
        uint256 daysToMaturity,
        address[] collateralTypes,
        uint160 expiresAt,
        uint160 createdAt,
        address lender
    );

    event BorrowingOfferCreated(
        uint256 offerId,
        address principalToken,
        address collateralToken,
        uint256 initialCollateral,
        uint256 currentCollateral,
        uint256 interest,
        uint256 daysToMaturity,
        uint160 expiresAt,
        uint160 createdAt,
        address borrower
    );

    event OfferClosed(uint256 offerId, OfferLibrary.Type offerType);

    event RequestClosed(uint256 requestId, RequestLibrary.Type requestType);

    function createLendingOffer(
        address principalToken,
        uint256 principal,
        uint256 interest,
        uint256 daysToMaturity,
        uint256 daysToExpire,
        address[] memory collateralTypes,
        address lender
    ) public onlyLendingPool returns (uint256) {
        // onlyOwner
        lendingOfferIdTracker.increment();
        uint256 offerId = lendingOfferIdTracker.current();

        uint160 createdAt = uint160(block.timestamp);
        uint160 duration = uint160((daysToExpire * 1 days));
        uint160 expiresAt = createdAt + duration;

        lendingOffers[offerId] = OfferLibrary.LendingOffer(
            offerId,
            principalToken,
            principal, // currentPrincipal
            principal, // initialPrincipal
            interest,
            daysToMaturity,
            collateralTypes,
            expiresAt,
            createdAt,
            lender
        );

        emit LendingOfferCreated(
            offerId,
            principalToken,
            principal, // currentPrincipal
            principal, // initialPrincipal
            interest,
            daysToMaturity,
            collateralTypes,
            expiresAt,
            createdAt,
            lender
        );

        return offerId;
    }

    function _afterOfferLendingLoan(uint256 offerId, uint256 principal)
        public
        onlyLendingPool
    {
        require(
            lendingOffers[offerId].currentPrincipal >= principal,
            "ERR_INSUFFICIENT_AMOUNT"
        );
        lendingOffers[offerId].currentPrincipal -= principal;
    }

    function _afterOfferBorrowingLoan(
        uint256 offerId,
        uint256 principal,
        uint256 collateral
    ) public onlyLendingPool {
        borrowingOffers[offerId].currentPrincipal -= principal;
        borrowingOffers[offerId].currentCollateral -= collateral;
    }

    function createBorrowingOffer(
        address principalToken,
        address collateralToken,
        uint256 collateral,
        uint256 principalNeeded,
        uint256 interest,
        uint256 daysToMaturity,
        uint256 daysToExpire,
        address borrower
    ) public onlyLendingPool returns (uint256) {
        borrowingOfferIdTracker.increment();
        uint256 offerId = borrowingOfferIdTracker.current();

        uint160 createdAt = uint160(block.timestamp);
        uint160 duration = uint160((daysToExpire * 1 days));
        uint160 expiresAt = createdAt + duration;

        borrowingOffers[offerId] = OfferLibrary.BorrowingOffer(
            offerId,
            principalToken,
            collateralToken,
            collateral, // currentCollateral
            collateral, // initialCollateral
            principalNeeded, // currentPrincipal
            principalNeeded, // initialPrincipal
            interest,
            daysToMaturity,
            expiresAt,
            createdAt,
            borrower
        );

        emit BorrowingOfferCreated(
            offerId,
            principalToken,
            collateralToken,
            collateral, // currentCollateral
            collateral, // initialCollateral
            interest,
            daysToMaturity,
            expiresAt,
            createdAt,
            borrower
        );

        return offerId;
    }

    function withdrawLendingOffer(
        uint256 offerId,
        address lender,
        uint256 amount
    ) public onlyLendingPool returns (bool) {
        require(lender == lendingOffers[offerId].lender);
        require(lendingOffers[offerId].currentPrincipal <= amount);
        lendingOffers[offerId].currentPrincipal -= amount;

        if (lendingOffers[offerId].currentPrincipal == 0) {
            delete lendingOffers[offerId];
            emit OfferClosed(offerId, OfferLibrary.Type.LENDING_OFFER);
        }

        return true;
    }

    function closeLendingRequest(uint256 requestId) public {}

    function getLendingOffer(uint256 offerId)
        public
        view
        override
        returns (OfferLibrary.LendingOffer memory)
    {
        return lendingOffers[offerId];
    }

    function getBorrowingOffer(uint256 offerId)
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
