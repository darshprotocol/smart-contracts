const Activity = artifacts.require("Activity")
const PriceFeed = artifacts.require("PriceFeed")
const TrustScore = artifacts.require("TrustScore")
const LoanToValueRatio = artifacts.require("LoanToValueRatio")

module.exports = async function (deployer, network, accounts) {
    if (network == "test" || network == "test2") return;
    // return

    await deployer.deploy(PriceFeed)
    await deployer.deploy(Activity)
    await deployer.deploy(TrustScore)
    await deployer.deploy(LoanToValueRatio)
};