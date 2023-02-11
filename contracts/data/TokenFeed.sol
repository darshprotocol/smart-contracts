// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/AssetLibrary.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/*
    ChainLink Fantom Testnet Price Feed Addresses.
    For developent purpose.

    WBTC/USD -> 0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529
    WETH/USD -> 0xB8C458C957a6e6ca7Cc53eD95bEA548c52AFaA24
    FTM/USD -> 0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D

    USDT/USD -> 0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128
    USDC/USD -> 0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128
    DAI/USD -> 0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128
*/

contract TokenFeed is Ownable2Step {
    mapping(AssetLibrary.Type => address) public tokenAddresses;

    address public constant nativeAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function getTokenAddress(AssetLibrary.Type assetType)
        public
        view
        returns (address)
    {
        return tokenAddresses[assetType];
    }

    function setTokenAddress(AssetLibrary.Type assetType, address tokenAddress)
        external
        onlyOwner
    {
        tokenAddresses[assetType] = tokenAddress;
    }
}
