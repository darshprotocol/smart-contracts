// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IVaultManager {
    function deposit(
        address to,
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

    function transfer(
        address from,
        address to,
        address token,
        uint256 amount,
        uint256 offerId
    ) external;

    function balanceOf(address provider, address token)
        external
        returns (uint256);
}
