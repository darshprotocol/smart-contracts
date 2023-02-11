// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./interfaces/ILiqudation.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Liquidator is ILiqudation, Ownable2Step {

    uint private _gracePeriod;

    constructor() {
        _gracePeriod = 5 days;
    }

    function updateGracePeriod(uint millis) public onlyOwner {
        _gracePeriod = millis;
    }

    function gracePeriod() public view override returns(uint) {
        return _gracePeriod;
    }
    
    function liquidate(uint256 loanId, address caller) public returns(bool) {
        // check if caller can liquidate loan
    }

}