const Activity = artifacts.require("Activity")
const PriceFeed = artifacts.require("PriceFeed")
const TokenFeed = artifacts.require("TokenFeed")
const StakingFeed = artifacts.require("StakingFeed")
const TrustScore = artifacts.require("TrustScore")

module.exports = async function (deployer, network, accounts) {
    if (network == "test" || network == "test2") return;
    return

    await deployer.deploy(PriceFeed)
    await deployer.deploy(TokenFeed)
    await deployer.deploy(Activity)
    await deployer.deploy(TrustScore)
    await deployer.deploy(StakingFeed)
};