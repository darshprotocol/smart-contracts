// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/OfferLibrary.sol";
import "../libraries/RequestLibrary.sol";

interface IOfferManager {
    function createLendingOffer(
        address principalToken,
        uint256 principalAmount,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 daysToExpire,
        address[] memory collateralTokens,
        address lender
    ) external returns (uint256);

    function createLendingRequest(
        uint16 percentage,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address lender,
        uint256 offerId
    ) external returns (uint256);

    function createBorrowingOffer(
        address principalToken,
        address collateralToken,
        uint256 collateralAmount,
        uint256 principalAmount,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address borrower
    ) external returns (uint256);

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
    ) external returns (uint256);

    function reActivateOffer(
        uint256 offerId,
        uint16 toExpire,
        address user
    ) external;

    function rejectRequest(uint256 requestId, address user) external;

    function acceptRequest(uint256 requestId, address user) external;

    function cancelRequest(uint256 requestId, address user) external;

    function removePrincipal(
        uint256 offerId,
        address user,
        uint256 amount
    ) external;

    function removeCollateral(
        uint256 offerId,
        address user,
        uint256 amount
    ) external;

    function isCollateralSupported(uint256 offerId, address token)
        external
        returns (bool);

    function afterBorrowingLoan(
        uint256 offerId,
        uint256 principalAmount,
        uint256 collateralAmount
    ) external;

    function afterLendingLoan(uint256 offerId, uint256 principalAmount)
        external;

    function getOffer(uint256 offerId)
        external
        view
        returns (OfferLibrary.Offer memory);

    function getRequest(uint256 requestId)
        external
        view
        returns (RequestLibrary.Request memory);
}
