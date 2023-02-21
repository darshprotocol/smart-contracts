// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IVaultManager {
    function deposit(
        address from,
        address token,
        uint256 amount,
        uint256 offerId
    ) external;

    function withdraw(
        address from,
        address token,
        uint256 amount,
        uint256 offerId
    ) external;

    function balanceOf(uint256 offerId, address token)
        external
        returns (uint256);
}
