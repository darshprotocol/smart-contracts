// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./interfaces/ITrustScore.sol";
import "./interfaces/ILoanToValueRatio.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract LoanToValueRatio is Ownable2Step, ILoanToValueRatio {
    ITrustScore private _trustScore;

    uint160 minLTV;
    uint160 maxLTV;

    uint8 public base = 10;
    uint256 public trustPrice0 = 1000 * 1e18;
    uint256 public trustPrice1 = 3000 * 1e18;

    constructor() Ownable2Step() {}

    function getBase() public view override returns (uint8) {
        return base;
    }

    function getRelativeLTV(address user, uint256 amount)
        public
        view
        override
        returns (uint160)
    {
        uint160 ltv = getLTV(user);
        
        if (amount > trustPrice1) return maxLTV;

        if (amount > trustPrice0) {
            uint160 average = ((maxLTV + minLTV) / 2);
            if (ltv <= average) return average;
        }

        return ltv;
    }

    function getLTV(address user) public view override returns (uint160) {
        // 0 ~ 100
        uint16 score = _trustScore.getScore(user);
        uint160 range = maxLTV - minLTV;
        uint160 scale = ((range * score) / 100);
        return minLTV + scale;
    }

    function setTrustScore(
        address trustScore_,
        uint160 minLTV_,
        uint160 maxLTV_
    ) public onlyOwner {
        require(minLTV_ < maxLTV_, "ERR_LTV");
        minLTV = minLTV_ * base;
        maxLTV = maxLTV_ * base;
        _trustScore = ITrustScore(trustScore_);
    }
}
