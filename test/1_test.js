const PoolManager = artifacts.require("PoolManager");
const OfferManager = artifacts.require("OfferManager");
const LoanManager = artifacts.require("LoanManager");
const FeeManager = artifacts.require("FeeManager");

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
        const priceFeed = await PriceFeed.deployed()
        await priceFeed.addPriceFeed(NATIVE.address, "0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D")
        await priceFeed.addPriceFeed(WBTC.address, "0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529")
        await priceFeed.addPriceFeed(WETH.address, "0xB8C458C957a6e6ca7Cc53eD95bEA548c52AFaA24")
        await priceFeed.addPriceFeed(USDT.address, "0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128")
        await priceFeed.addPriceFeed(USDC.address, "0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128")
        await priceFeed.addPriceFeed(DAI.address, "0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128")
    })
    it("setValues 2", async () => {
        const ltv = await LoanToValueRatio.deployed()
        await ltv.setTrustScore(TrustScore.address, 100, 120)

        const trustScore = await TrustScore.deployed()
        await trustScore.setActivity(Activity.address)

        const offerManager = await OfferManager.deployed()
        await offerManager.setLendingPool(LendingPool.address)

        const poolManager = await PoolManager.deployed()
        await poolManager.setLendingPool(LendingPool.address)

        const loanManager = await LoanManager.deployed()
        await loanManager.setLendingPool(LendingPool.address)

        const feeManager = await FeeManager.deployed()
        await feeManager.setLendingPool(LendingPool.address)

        const activity = await Activity.deployed()
        await activity.setLendingPool(LendingPool.address)

        const lendingPool = await LendingPool.deployed()
        await lendingPool.setLTV(LoanToValueRatio.address);
        await lendingPool.setActivity(Activity.address);
        await lendingPool.setPriceFeed(PriceFeed.address);
    })
    it("createOffer", async () => {
        // const ftmAmount = "2000000000000000000" // 2 ftm
        // const lending = await LendingPool.deployed()
        // await lending.createLendingOffer(
        //     0, // amount
        //     NATIVE.address,
        //     [USDC.address, USDT.address, DAI.address],
        //     30, // days to maturity,
        //     "50000000000000", // interest
        //     7,
        //     {
        //         from: accounts[0],
        //         value: ftmAmount
        //     }
        // )
    })
    it("ltv", async () => {
        // const ltv = await LoanToValueRatio.deployed()
        // let x = await ltv.getLTV(accounts[1]);
        // console.log(x.toNumber());

        const trt = await TrustScore.deployed()
        let z = await trt.getScore(accounts[1])
        console.log(z.toNumber())

        const act = await Activity.deployed()
        let y = await act.getActivity(accounts[1])
        console.log(y)
    })
    it("borrowOffer", async () => {
        // const dai = await DAI.deployed()
        // let b = await dai.balanceOf("0x579959633488750B0C6603bEC0f8FDd24aD57fcA")
        // console.log(b.toNumber());
        // // await dai.transfer(accounts[1], "10000000000000000000")
        // await dai.approve(LendingPool.address, "10000000000000000000", { from: accounts[1] })
        // const borrowing = await LendingPool.deployed()
        // await borrowing.acceptLendingOffer(2, 50, DAI.address, { from: accounts[1] })
    })
    it("repayLoan", async () => {
        // const lendingPool = await LendingPool.deployed()
        // const createdAt = 1676286833
        // const now = Math.floor(Date.now() / 1000)
        // const ellapsed = (now + 20) - createdAt
        // const ftmAmount = "250000000000000000"
        // const payback = await lendingPool.getFullInterestAmount(ftmAmount, ellapsed, "50000000000000")
        // console.log(Number(payback));
        // await lendingPool.repayLoan(2, 25, { value: payback, from: accounts[1] });
    })
})