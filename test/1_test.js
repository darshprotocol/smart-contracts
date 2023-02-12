const PoolManager = artifacts.require("PoolManager");
const OfferManager = artifacts.require("OfferManager");
const LoanManager = artifacts.require("LoanManager");

const LendingPool = artifacts.require("LendingPool");

const PriceFeed = artifacts.require("PriceFeed");

const Activity = artifacts.require("Activity");
const TrustScore = artifacts.require("TrustScore");
const LoanToValueRatio = artifacts.require("LoanToValueRatio");

const WBTC = artifacts.require("WBTC");
const WETH = artifacts.require("WETH");
const USDT = artifacts.require("USDT");
const USDC = artifacts.require("USDC");
const DAI = artifacts.require("DAI");
const NATIVE = {
    address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
}

// const arr = [NATIVE, WBTC, WETH, USDT, USDC, DAI]

contract("CreateLendingOffer", async accounts => {
    it("setValues", async () => {
        // const priceFeed = await PriceFeed.deployed()
        // await priceFeed.addPriceFeed(NATIVE.address, "0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D")
        // await priceFeed.addPriceFeed(WBTC.address, "0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529")
        // await priceFeed.addPriceFeed(WETH.address, "0xB8C458C957a6e6ca7Cc53eD95bEA548c52AFaA24")
        // await priceFeed.addPriceFeed(USDT.address, "0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128")
        // await priceFeed.addPriceFeed(USDC.address, "0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128")
        // await priceFeed.addPriceFeed(DAI.address, "0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128")
    })
    it("setValues 2", async () => {
        // const ltv = await LoanToValueRatio.deployed()
        // await ltv.setTrustScore(TrustScore.address, 100, 120)

        // const trustScore = await TrustScore.deployed()
        // await trustScore.setActivity(Activity.address)

        // const offerManager = await OfferManager.deployed()
        // await offerManager.setLendingPool(LendingPool.address)

        // const poolManager = await PoolManager.deployed()
        // await poolManager.setLendingPool(LendingPool.address)

        // const loanManager = await LoanManager.deployed()
        // await loanManager.setLendingPool(LendingPool.address)

        // const activity = await Activity.deployed()
        // await activity.setLendingPool(LendingPool.address)

        // const lendingPool = await LendingPool.deployed()
        // await lendingPool.setLTV(LoanToValueRatio.address);
        // await lendingPool.setActivity(Activity.address);
        // await lendingPool.setPriceFeed(PriceFeed.address);
    })
    it("createOffer", async () => {
        // const ftmAmount = "1000000000000000000" // 1 ftm
        // const lending = await LendingPool.deployed()
        // await lending.createLendingOffer(
        //     0, // amount
        //     NATIVE.address,
        //     [USDC.address, USDT.address, DAI.address],
        //     30, // days to maturity,
        //     "385802400000000", // interest
        //     7,
        //     {
        //         from: accounts[0],
        //         value: ftmAmount
        //     }
        // )
    })
    it("ltv", async () => {
        const ltv = await LoanToValueRatio.deployed()
        let x = await ltv.getLTV(accounts[1]);
        console.log(x.toNumber());
    })
    it("borrowOffer", async () => {
        // const dai = await DAI.deployed()
        // await dai.transfer(accounts[1], "10000000000000000000")
        // await dai.approve(LendingPool.address, "10000000000000000000", { from: accounts[1] })
        // const borrowing = await LendingPool.deployed()
        // await borrowing.acceptLendingOffer(1, 75, DAI.address, { from: accounts[1] })
    })
    it("repayLoan", async () => {
        const lendingPool = await LendingPool.deployed()
        const createdAt = 1676239028
        const now = Math.floor(Date.now() / 1000)
        const ellapsed = (now + 10) - createdAt
        const ftmAmount = "7500000000000000000" // 0.75 ftm
        const payback = await lendingPool.getFullInterestAmount(ftmAmount, ellapsed, "385802400000")
        console.log(Number(payback));
        await lendingPool.repayLoan(1, 50, { value: payback, from: accounts[1] });
    })
})