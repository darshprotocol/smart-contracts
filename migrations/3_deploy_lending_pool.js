const LendingPool = artifacts.require("LendingPool")

module.exports = async function (deployer, network, accounts) {
    if (network == "testnet_test" || network == "mainnet_test") return;
    
    await deployer.deploy(LendingPool)
}