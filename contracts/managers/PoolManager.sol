// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/PoolLibrary.sol";

import "../interfaces/IPoolManager.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract PoolManager is IPoolManager, Ownable2Step {
    address lendingPool;

    mapping(address => PoolLibrary.Pool[]) pools;

    constructor() Ownable2Step() {}

    function deposit(
        address user,
        address token,
        uint256 amount
    ) public onlyLendingPool {
        for (uint256 index = 0; index < pools[user].length; index++) {
            if (pools[user][index].token == token) {
                pools[user][index].amount += amount;
            }
        }

        pools[user].push(PoolLibrary.Pool(token, amount));
    }

    function burn(
        address user,
        address token,
        uint256 amount
    ) public onlyLendingPool {
        for (uint256 index = 0; index < pools[user].length; index++) {
            if (pools[user][index].token == token) {
                // insuficient amount
                if (pools[user][index].amount < amount) revert("ERR_WITHDRAW");

                // burn successful
                pools[user][index].amount -= amount;
                return;
            }
        }

        revert("ERR_WITHDRAW");
    }

    function transfer(
        address from,
        address to,
        address token,
        uint256 amount
    ) public onlyLendingPool {
        burn(from, token, amount);
        deposit(to, token, amount);
    }

    function balanceOf(address user, address token)
        public
        view
        override
        returns (uint256)
    {
        for (uint256 index = 0; index < pools[user].length; index++) {
            if (pools[user][index].token == token) {
                return pools[user][index].amount;
            }
        }

        return 0;
    }

    function setLendingPool(address address_) public onlyOwner {
        lendingPool = address_;
    }

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool);
        _;
    }
}
