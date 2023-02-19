// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/VaultLibrary.sol";

import "../interfaces/IVaultManager.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract VaultManager is IVaultManager, Ownable2Step {
    address lendingPool;

    mapping(address => VaultLibrary.Vault[]) public vaults;

    constructor() Ownable2Step() {}

    function deposit(
        address to,
        address token,
        uint256 amount,
        uint256 offerId
    ) public override onlyLendingPool {
        for (uint256 index = 0; index < vaults[to].length; index++) {
            if (vaults[to][index].token == token) {
                vaults[to][index].amount += amount;
            }
        }

        vaults[to].push(VaultLibrary.Vault(token, amount));

        emit VaultLibrary.Transfer(
            offerId,
            to,
            address(0),
            amount,
            token,
            block.timestamp
        );
    }

    function withdraw(
        address from,
        address token,
        uint256 amount,
        uint256 offerId
    ) public override onlyLendingPool {
        for (uint256 index = 0; index < vaults[from].length; index++) {
            if (vaults[from][index].token == token) {
                // insuficient amount
                if (vaults[from][index].amount < amount) revert("ERR_WITHDRAW");

                // burn successful
                vaults[from][index].amount -= amount;

                emit VaultLibrary.Transfer(
                    offerId,
                    address(0),
                    from,
                    amount,
                    token,
                    block.timestamp
                );
                return;
            }
        }

        revert("ERR_WITHDRAW_END");
    }

    function transfer(
        address from,
        address to,
        address token,
        uint256 amount,
        uint256 offerId
    ) public override onlyLendingPool {
        withdraw(from, token, amount, offerId);
        deposit(to, token, amount, offerId);
    }

    function balanceOf(address user, address token)
        public
        view
        override
        returns (uint256)
    {
        for (uint256 index = 0; index < vaults[user].length; index++) {
            if (vaults[user][index].token == token) {
                return vaults[user][index].amount;
            }
        }

        return 0;
    }

    function setLendingPool(address address_) public onlyOwner {
        lendingPool = address_;
    }

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool);
        _;
    }
}
