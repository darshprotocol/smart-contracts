// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IFeeManager {
    function credit(address token, uint256 amount) external;

    function debit(address token, uint256 amount) external;

    function feePercentage() external returns (uint160);

    function balanceOf(address token) external returns (uint256);
}
