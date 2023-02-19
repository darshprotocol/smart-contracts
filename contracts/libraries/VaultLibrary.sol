// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

library VaultLibrary {
    event Transfer(
        uint256 offerId,
        address from,
        address to,
        uint256 amount,
        address token,
        uint256 timestamp
    );

    struct Vault {
        address token;
        uint256 amount;
    }
}
