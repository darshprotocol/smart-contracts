// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {

    constructor() ERC20("USDC", "USDC") {
        _mint(msg.sender, 100000000 * 10 ** 18);
    }

}