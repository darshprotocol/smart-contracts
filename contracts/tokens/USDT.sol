// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {

    constructor() ERC20("USDT", "USDT") {
        _mint(msg.sender, 100000000 * 10 ** 18);
    }

}