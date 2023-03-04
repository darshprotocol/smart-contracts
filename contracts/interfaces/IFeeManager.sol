// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFeeManager {
    function credit(address token, uint256 amount) external;

    function debit(address token, uint256 amount) external;

    function feePercentage() external returns (uint160);

    function balanceOf(address token) external returns (uint256);
}
