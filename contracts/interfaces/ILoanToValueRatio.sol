// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface ILoanToValueRatio {
    function getBase() external view returns (uint8);
    function getLTV(address user) external view returns (uint160);
}
