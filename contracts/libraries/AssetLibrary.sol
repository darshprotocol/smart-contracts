// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

library AssetLibrary {
    struct Pool {
        address token;
        uint256 amount;
    }

    /* belongs to a wallet address or user */
    struct StakingReward {
        address token; // address of the associated stake e.g WETH
        uint256 amount; // current amount of stake
        uint256 amount24; // previous amount of stake since last distribution
        uint256 reward; // amount of unclaimed reward
    }

    struct Reserve {
        address[] providers;
        uint256 total;
    }
}
