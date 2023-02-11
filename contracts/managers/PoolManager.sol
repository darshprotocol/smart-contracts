// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/AssetLibrary.sol";

import "../interfaces/IPoolManager.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract PoolManager is IPoolManager, Ownable2Step {
    // user => pools
    mapping(address => AssetLibrary.Pool[]) public pools;

    address lendingPool;

    constructor() Ownable2Step() {}

    function getAddress() public view override returns (address payable) {
        return payable(address(this));
    }

    function deposit(
        address user,
        address token,
        uint256 amount
    ) public onlyLendingPool returns (bool) {
        // onlyOwner
        for (uint256 index = 0; index < pools[user].length; index++) {
            if (pools[user][index].token == token) {
                pools[user][index].amount += amount;
                return true;
            }
        }

        pools[user].push(AssetLibrary.Pool(token, amount));
        return true;
    }

    function withdraw(
        address user,
        address token,
        uint256 amount
    ) public onlyLendingPool returns (bool) {
        // onlyOwner
        for (uint256 index = 0; index < pools[user].length; index++) {
            if (pools[user][index].token == token) {
                // insuficient amount
                if (pools[user][index].amount < amount) return false;

                // withdrawn successful
                pools[user][index].amount -= amount;
                return true;
            }
        }

        return false;
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
