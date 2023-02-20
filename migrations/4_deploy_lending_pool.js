const LendingPool = artifacts.require("LendingPool")

module.exports = async function (deployer, network, accounts) {
    if (network == "test" || network == "test2") return;
    // return

    await deployer.deploy(LendingPool)
}