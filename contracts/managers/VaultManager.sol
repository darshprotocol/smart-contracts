// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/VaultLibrary.sol";

import "../interfaces/IVaultManager.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract VaultManager is IVaultManager, Ownable2Step {
    address lendingPool;

    mapping(uint256 => VaultLibrary.Vault[]) public vaults;

    constructor() Ownable2Step() {}

    function deposit(
        address to,
        address token,
        uint256 amount,
        uint256 offerId
    ) public override onlyLendingPool {
        for (uint256 index = 0; index < vaults[offerId].length; index++) {
            if (vaults[offerId][index].token == token) {
                vaults[offerId][index].amount += amount;
            }
        }

        vaults[offerId].push(VaultLibrary.Vault(token, amount));

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
        for (uint256 index = 0; index < vaults[offerId].length; index++) {
            if (vaults[offerId][index].token == token) {
                // insuficient amount
                if (vaults[offerId][index].amount < amount) revert("ERR_WITHDRAW");

                // burn successful
                vaults[offerId][index].amount -= amount;

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

    function balanceOf(uint256 offerId, address token)
        public
        view
        override
        returns (uint256)
    {
        for (uint256 index = 0; index < vaults[offerId].length; index++) {
            if (vaults[offerId][index].token == token) {
                return vaults[offerId][index].amount;
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
