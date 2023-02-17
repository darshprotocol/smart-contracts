// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/PoolLibrary.sol";
import "../libraries/OfferLibrary.sol";
import "../libraries/RequestLibrary.sol";

interface IOfferManager {

    function getOffer(uint256 offerId) external view returns(OfferLibrary.Offer memory);

    function getRequest(uint256 requestId) external view returns (RequestLibrary.Request memory);
   
}