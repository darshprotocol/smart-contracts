// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IFeeManager.sol";

import "@openzeppelin/contracts/access/Ownable2Step.sol";

/*
    The FeeManager contract is solely created to bookkeep
    @dev revenue from the LendingPool contract.
   This contract can only be modified by the LendingPool 
    contract.
*/
 

contract FeeManager is IFeeManager, Ownable2Step {
    address deployer;

    uint160 private _percentage = 5; // 2%
    mapping(address => uint256) private _balances;

    constructor() Ownable2Step() {}

    function credit(address token, uint256 amount)
        public
        override
        onlyLendingPool
    {
        _balances[token] += amount;
    }

    function debit(address token, uint256 amount)
        public
        override
        onlyLendingPool
    {
        uint256 balance = _balances[token];
        require(balance >= amount, "ERR_INSUFFICIENT");
        _balances[token] -= amount;
    }

    function balanceOf(address token) public view override returns (uint256) {
        return _balances[token];
    }

    function feePercentage() public view override returns (uint160) {
        return _percentage;
    }

    function changePercentage(uint160 percentage_) public onlyOwner {
        _percentage = percentage_;
    }

    function setLendingPool(address lendingPool_) public onlyOwner {
        deployer = lendingPool_;
    }

    modifier onlyLendingPool() {
        require(deployer == msg.sender, "ERR_ONLY_LENDING_POOL");
        _;
    }
}
