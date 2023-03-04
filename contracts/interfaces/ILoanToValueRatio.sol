// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILoanToValueRatio {
    function getBase() external view returns (uint8);

    function getLTV(address user) external view returns (uint160);

    function getRelativeLTV(address user, uint256 amount)
        external
        view
        returns (uint160);
}
