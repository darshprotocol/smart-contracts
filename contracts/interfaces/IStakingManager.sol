// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IStakingManager {

    function balance(address token) external returns(uint256);

    function balanceOf(address provider, address token) external returns(uint256);

    function getAPY(address token) external returns(uint);

}