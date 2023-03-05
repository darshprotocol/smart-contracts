const OfferManager = artifacts.require("OfferManager");
const LoanManager = artifacts.require("LoanManager");
const FeeManager = artifacts.require("FeeManager");

const LendingPool = artifacts.require("LendingPool");

const PriceFeed = artifacts.require("PriceFeed");

const Activity = artifacts.require("Activity");
const DarshScore = artifacts.require("DarshScore");
const LoanToValueRatio = artifacts.require("LoanToValueRatio");

const WBTC = "0x321162Cd933E2Be498Cd2267a90534A804051b11"
const WETH = "0x74b23882a30290451A17c44f4F05243b6b58C76d"
const USDT = "0x049d68029688eabf473097a2fc38ef61633a3c7a"
const USDC = "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75"
const DAI = "0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E"
const NATIVE = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"

contract("CreateLendingOffer", async accounts => {
    it("setValues", async () => {
        const priceFeed = await PriceFeed.deployed()
        await priceFeed.addPriceFeed(NATIVE, "0xf4766552D15AE4d256Ad41B6cf2933482B0680dc")
        await priceFeed.addPriceFeed(WBTC, "0x8e94C22142F4A64b99022ccDd994f4e9EC86E4B4")
        await priceFeed.addPriceFeed(WETH, "0x11DdD3d147E5b83D01cee7070027092397d63658")
        await priceFeed.addPriceFeed(USDT, "0xF64b636c5dFe1d3555A847341cDC449f612307d0")
        await priceFeed.addPriceFeed(USDC, "0x2553f4eeb82d5A26427b8d1106C51499CBa5D99c")
        await priceFeed.addPriceFeed(DAI, "0x91d5DEFAFfE2854C7D02F50c80FA1fdc8A721e52")
        await priceFeed.addUSDFeed("0xF64b636c5dFe1d3555A847341cDC449f612307d0")
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