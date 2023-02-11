// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../data/StakingFeed.sol";
import "../libraries/AssetLibrary.sol";
import "../interfaces/IStakingManager.sol";

contract StakingManager is IStakingManager {
    uint256 private _rewardFee;
    mapping(address => uint256) private _last24HAPY;

    // token address => reserve
    mapping(address => AssetLibrary.Reserve) private reserves;

    // user'swallet address => rewards
    mapping(address => AssetLibrary.StakingReward[]) public rewards;

    // provides data for staking manager
    // from example the current APY
    StakingFeed private _stakingFeed;

    event RewardClaimed(
        address user,
        address token,
        uint256 amount,
        uint256 date
    );

    constructor(address stakingFeed_) {
        _stakingFeed = StakingFeed(stakingFeed_);
    }

    // get balance of a reverse token by it's address
    function balance(address token) public view override returns (uint256) {
        return reserves[token].total;
    }

    // get user's balance
    function balanceOf(address user, address token)
        public
        view
        override
        returns (uint256)
    {
        for (uint256 index = 0; index < rewards[user].length; index++) {
            if (rewards[user][index].token == token) {
                return rewards[user][index].amount;
            }
        }

        return 0;
    }

    // transfer staking balance and consecutive rewards from
    // a user to another user
    // a use case is when a staked token is used as collateral
    // when executing a loan contract
    function transferLiquidityTo(
        address from,
        address to,
        address token,
        uint256 amount
    ) external returns (bool) {
        require(amount > 0);
        require(to != address(0));
        require(from != address(0));
        require(withdrawLiquidityFor(from, token, amount));
        require(provideLiquidityFor(to, token, amount));
        return true;
    }

    function provideLiquidityFor(
        address user,
        address token,
        uint256 amount
    ) public returns (bool) { // onlyOwner
        for (uint256 index = 0; index < rewards[user].length; index++) {
            if (rewards[user][index].token == token) {
                rewards[user][index].amount += amount;
                return true;
            }
        }

        reserves[token].providers.push(user);
        reserves[token].total += amount;
        rewards[user].push(
            AssetLibrary.StakingReward(token, amount, amount, 0)
        );
        return true;
    }

    function withdrawLiquidityFor(
        address user,
        address token,
        uint256 amount
    ) public returns (bool) { // onlyOwner
        for (uint256 index = 0; index < rewards[user].length; index++) {
            if (rewards[user][index].token == token) {
                // insuficient amount
                if (rewards[user][index].amount < amount) return false;

                // withdrawn successful
                rewards[user][index].amount -= amount;

                // balance amount and safe amount
                rewards[user][index].amount24 = rewards[user][index]
                    .amount;

                if (rewards[user][index].amount == 0) {
                    delete rewards[user][index];
                }

                reserves[token].total -= amount;
                return true;
            }
        }

        return false;
    }

    // function to claim staking reward
    function claimEarnings(address token, uint256 amount)
        public
        returns (bool)
    { // onlyOwner
        require(amount > 0);
        address user = msg.sender;

        for (uint256 index = 0; index < rewards[user].length; index++) {
            if (rewards[user][index].token == token) {
                // insuficient amount
                if (rewards[user][index].reward < amount) return false;

                // withdrawn successful
                rewards[user][index].reward -= amount;
                emit RewardClaimed(user, token, amount, block.timestamp);
                return true;
            }
        }

        return false;
    }

    // @params token -> token address
    // @returns APY for token
    function getAPY(address token) public view override returns (uint) {
        return _stakingFeed.getAPY(token);
    }

    function _getSafeAPY(address token) private view returns (uint256) {
        uint256 _apy = getAPY(token);
        if (_apy > _last24HAPY[token]) return _last24HAPY[token];
        return _apy;
    }

    function _increaseEarnings(
        address token,
        address user,
        uint256 amount
    ) private returns (bool) {
        for (uint256 index = 0; index < rewards[user].length; index++) {
            if (rewards[user][index].token == token) {
                rewards[user][index].reward += amount;
                return true;
            }
        }

        return false;
    }
}
