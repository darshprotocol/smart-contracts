const LoanManager = artifacts.require("LoanManager")
const OfferManager = artifacts.require("OfferManager")
const FeeManager = artifacts.require("FeeManager")

module.exports = async function(deployer, network, accounts) {
    if (network == "testnet_test" || network == "mainnet_test") return;
    
    await deployer.deploy(LoanManager)
    await deployer.deploy(OfferManager)
    await deployer.deploy(FeeManager)
};