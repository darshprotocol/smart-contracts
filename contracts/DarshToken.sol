// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DarshToken is Ownable2Step, ERC20 {
    constructor() Ownable2Step() ERC20("Darsh Token", "DARSH") {}
}
