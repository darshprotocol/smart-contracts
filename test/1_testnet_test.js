const OfferManager = artifacts.require("OfferManager");
const LoanManager = artifacts.require("LoanManager");
const FeeManager = artifacts.require("FeeManager");

const LendingPool = artifacts.require("LendingPool");

const PriceFeed = artifacts.require("PriceFeed");

const Activity = artifacts.require("Activity");
const DarshScore = artifacts.require("DarshScore");
const LoanToValueRatio = artifacts.require("LoanToValueRatio");

const WBTC = "0xBcEdBF29D6dff33fCf5CA6c1816CcA886fd6F5C4"
const WETH = "0x2b42D1149f3427044acd6B310F6721c5d87c652e"
const USDT = "0x114Eb0218066A32d072bDe9F1C396D0F0C5F5180"
const USDC = "0x81733e12b6C9c5F4Dd6459F3766dFDB2DC1f89f8"
const DAI = "0xBE6FdBafBD486733601cA35300Cc1dbb763d6edB"
const NATIVE = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"

contract("CreateLendingOffer", async accounts => {
    it("setValues", async () => {
        const priceFeed = await PriceFeed.deployed()
        await priceFeed.addPriceFeed(NATIVE, "0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D")
        await priceFeed.addPriceFeed(WBTC, "0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529")
        await priceFeed.addPriceFeed(WETH, "0xB8C458C957a6e6ca7Cc53eD95bEA548c52AFaA24")
        await priceFeed.addPriceFeed(USDT, "0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128")
        await priceFeed.addPriceFeed(USDC, "0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128")
        await priceFeed.addPriceFeed(DAI, "0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128")
        await priceFeed.addUSDFeed("0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128")
    })
    it("setValues 2", async () => {
        const ltv = await LoanToValueRatio.deployed()
        await ltv.setDarshScore(DarshScore.address, 100, 120)

        const darshScore = await DarshScore.deployed()
        await darshScore.setActivity(Activity.address)

        const offerManager = await OfferManager.deployed()
        await offerManager.setLendingPool(LendingPool.address)

        const loanManager = await LoanManager.deployed()
        await loanManager.setLendingPool(LendingPool.address)

        const feeManager = await FeeManager.deployed()
        await feeManager.setLendingPool(LendingPool.address)

        const activity = await Activity.deployed()
        await activity.setLendingPool(LendingPool.address)
    })
    it("setValues 3", async function () {
        const lendingPool = await LendingPool.deployed()
        await lendingPool.setFeeds(
            LoanToValueRatio.address,
            Activity.address,
            PriceFeed.address
        )
        await lendingPool.setManagers(
            LoanManager.address,
            OfferManager.address,
            FeeManager.address
        )
    })
})