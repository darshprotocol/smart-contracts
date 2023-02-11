// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./interfaces/ITrustScore.sol";
import "./interfaces/ILoanToValueRatio.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract LoanToValueRatio is Ownable2Step, ILoanToValueRatio {
    ITrustScore private _trustScore;

    uint16 minLTV;
    uint16 maxLTV;

    uint8 public base = 10;

    constructor() Ownable2Step() {}

    function getBase() public view override returns (uint8) {
        return base;
    }

    function getLTV(address user) public view override returns (uint16) {
        // 0 ~ 100
        uint16 score = _trustScore.getScore(user);
        uint16 range = maxLTV - minLTV;
        uint16 scale = ((range * score) / 100);
        return minLTV + scale;
    }

    function setTrustScore(
        address trustScore_,
        uint16 minLTV_,
        uint16 maxLTV_
    ) public onlyOwner {
        require(minLTV_ < maxLTV_, "ERR_LTV");
        minLTV = minLTV_ * base;
        maxLTV = maxLTV_ * base;
        _trustScore = ITrustScore(trustScore_);
    }
}
