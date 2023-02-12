// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/PoolLibrary.sol";
import "../libraries/OfferLibrary.sol";
import "../libraries/RequestLibrary.sol";

interface IOfferManager {

    function getLendingOffer(uint160 offerId) external view returns(OfferLibrary.LendingOffer memory);

    function getBorrowingOffer(uint160 offerId) external view returns(OfferLibrary.BorrowingOffer memory);

    function getBorrowingRequest(uint256 requestId) external view returns (RequestLibrary.BorrowingRequest memory);
   
    function getLendingRequest(uint256 requestId) external view returns (RequestLibrary.LendingRequest memory);

}