
const WBTC = artifacts.require("WBTC")
const WETH = artifacts.require("WETH")
const USDT = artifacts.require("USDT")
const USDC = artifacts.require("USDC")
const DAI = artifacts.require("DAI")

module.exports = async function (deployer, network, accounts) {
    if (network == "test" || network == "test2") return;
    // return

    await deployer.deploy(WBTC)
    await deployer.deploy(WETH)
    await deployer.deploy(USDT)
    await deployer.deploy(USDC)
    await deployer.deploy(DAI)
};