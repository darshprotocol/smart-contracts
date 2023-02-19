const LendingPool = artifacts.require("LendingPool")
const VaultManager = artifacts.require("VaultManager")
const LoanManager = artifacts.require("LoanManager")
const OfferManager = artifacts.require("OfferManager")
const FeeManager = artifacts.require("FeeManager")

module.exports = async function(deployer, network, accounts) {
    if (network == "test" || network == "test2") return;
    // return
    
    await deployer.deploy(
        LendingPool,
        VaultManager.address,
        LoanManager.address,
        OfferManager.address,
        FeeManager.address
    )
}