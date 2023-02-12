const LendingPool = artifacts.require("LendingPool")
const Activity = artifacts.require("Activity")
const LoanToValueRatio = artifacts.require("LoanToValueRatio")
const PoolManager = artifacts.require("PoolManager")
const LoanManager = artifacts.require("LoanManager")
const OfferManager = artifacts.require("OfferManager")

module.exports = async function(deployer, network, accounts) {
    if (network == "test" || network == "test2") return;
    // return
    
    await deployer.deploy(
        LendingPool,
        LoanToValueRatio.address,
        Activity.address,
        PoolManager.address,
        LoanManager.address,
        OfferManager.address
    )
}