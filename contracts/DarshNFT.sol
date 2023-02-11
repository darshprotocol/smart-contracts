// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DarshNFT is Ownable2Step, ERC721 {
    address lendingPool;

    constructor() Ownable2Step() ERC721("DarshNFT", "DARSH") {}

    function mintFor(address user) public onlyLendingPool {}

    function setLendingPool(address address_) public onlyOwner {
        lendingPool = address_;
    }

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool);
        _;
    }
}
