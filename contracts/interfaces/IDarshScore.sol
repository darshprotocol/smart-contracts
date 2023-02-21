// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IDarshScore {
    function getScore(address user) external view returns (uint16);
}
