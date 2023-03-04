// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDarshScore {
    function getScore(address user) external view returns (uint16);
}
