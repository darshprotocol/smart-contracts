const Activity = artifacts.require("Activity")
const PriceFeed = artifacts.require("PriceFeed")
const DarshScore = artifacts.require("DarshScore")
const LoanToValueRatio = artifacts.require("LoanToValueRatio")

module.exports = async function (deployer, network, accounts) {
    if (network == "testnet_test" || network == "mainnet_test") return;
    
    await deployer.deploy(PriceFeed)
    await deployer.deploy(Activity)
    await deployer.deploy(DarshScore)
    await deployer.deploy(LoanToValueRatio)
};