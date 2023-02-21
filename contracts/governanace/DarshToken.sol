// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
    Darsh Token is essential for the darsh ecosystem.
    It is used for voting in the DARSH IMPROVEMENNT PROPOSALS,
    STAKING REWARDS and more use cases in the future.
*/

contract DarshToken is Ownable2Step, ERC20 {
    constructor() Ownable2Step() ERC20("Darsh Token", "DARSH") {
        _mint(msg.sender, 100000000 * 10**18);
    }
}
