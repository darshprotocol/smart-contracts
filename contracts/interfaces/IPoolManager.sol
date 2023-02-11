// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IPoolManager {

    function getAddress() external returns(address payable);
    
    function balanceOf(address provider, address token) external returns(uint256);

}