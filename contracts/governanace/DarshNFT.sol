// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DarshNFT is Ownable2Step, ERC721 {
    constructor() Ownable2Step() ERC721("DarshNFT", "xDSH") {}
}
