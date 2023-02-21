// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DarshNFT is Ownable2Step, ERC721 {
    constructor() Ownable2Step() ERC721("DarshNFT", "DARSH") {}
}
