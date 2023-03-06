// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
    Darsh Token is essential for the darsh ecosystem.
    It is used for voting in the DARSH IMPROVEMENNT PROPOSALS,
    STAKING REWARDS and more use cases in the future.
*/

contract DarshToken is Ownable2Step, ERC20 {
    constructor() Ownable2Step() ERC20("Darsh Token", "DSH") {
        _mint(msg.sender, 100000000 * 10**18);
    }
}
