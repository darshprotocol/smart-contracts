const PoolManager = artifacts.require("PoolManager");
const OfferManager = artifacts.require("OfferManager");
const LoanManager = artifacts.require("LoanManager");

const LendingPool = artifacts.require("LendingPool");

const TokenFeed = artifacts.require("TokenFeed");
const PriceFeed = artifacts.require("PriceFeed");

const Activity = artifacts.require("Activity");
const TrustScore = artifacts.require("TrustScore");

const WBTC = artifacts.require("WBTC");
const WETH = artifacts.require("WETH");
const USDT = artifacts.require("USDT");
const USDC = artifacts.require("USDC");
const DAI = artifacts.require("DAI");

// const arr = [NATIVE, WBTC, WETH, USDT, USDC, DAI]

contract("CreateLendingOffer", async accounts => {
    it("setValues", async () => {
        //     const tokenFeed = await TokenFeed.deployed()
        //     await tokenFeed.setTokenAddress(0, "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE")
        //     await tokenFeed.setTokenAddress(1, WBTC.address)
        //     await tokenFeed.setTokenAddress(2, WETH.address)
        //     await tokenFeed.setTokenAddress(3, USDT.address)
        //     await tokenFeed.setTokenAddress(4, USDC.address)
        //     await tokenFeed.setTokenAddress(5, DAI.address)

        //     const priceFeed = await PriceFeed.deployed()
        //     await priceFeed.addPriceFeed("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", "0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D")
        //     await priceFeed.addPriceFeed(WBTC.address, "0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529")
        //     await priceFeed.addPriceFeed(WETH.address, "0xB8C458C957a6e6ca7Cc53eD95bEA548c52AFaA24")
        //     await priceFeed.addPriceFeed(USDT.address, "0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128")
        //     await priceFeed.addPriceFeed(USDC.address, "0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128")
        //     await priceFeed.addPriceFeed(DAI.address, "0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128")

        // const offerManager = await OfferManager.deployed()
        // await offerManager.setLendingPool(LendingPool.address)

        // const poolManager = await PoolManager.deployed()
        // await poolManager.setLendingPool(LendingPool.address)

        // const loanManager = await LoanManager.deployed()
        // await loanManager.setLendingPool(LendingPool.address)

        // const lendingPool = await LendingPool.deployed()
        // await lendingPool.setPriceFeed(PriceFeed.address);
        // await lendingPool.setTokenFeed(TokenFeed.address);
        // await lendingPool.setTrustScore(TrustScore.address);
        // await lendingPool.setActivity(Activity.address);
    })
    it("createOffer", async () => {
        const ftmAmount = "1000000000000000000" // 1 ftm
        const lending = await LendingPool.deployed()
        await lending.createLendingOffer(
            0,
            0, // amount
            "385802400000", // interest
            30, // days to maturity,
            7,
            {
                from: accounts[0],
                value: ftmAmount
            }
        )
    })
    it("borrowOffer", async () => {
        const usdt = await DAI.deployed()
        // await usdt.transfer(accounts[1], "100000000000000000000")
        // const balance1 = await usdt.balanceOf(accounts[1])
        // console.log("USDT Balance Before Loan", Number(balance1));
        await usdt.approve(LendingPool.address, "100000000000000000000", { from: accounts[1] })
        const borrowing = await LendingPool.deployed()
        const ftmAmount = "500000000000000000" // 0.5 ftm
        await borrowing.acceptLendingOffer(4, ftmAmount, 5, { from: accounts[1] })
        // const balance2 = await usdt.balanceOf(accounts[1])
        // console.log("USDT Balance After Loan", Number(balance2));
    })
    it("repayLoan", async () => {
        // const lendingPool = await LendingPool.deployed()
        // const createdAt = 1675515317
        // const now = Math.floor(Date.now() / 1000)
        // const ellapsed = (now + 10) - createdAt
        // const ftmAmount = "500000000000000000" // 0.5 ftm
        // const payback = await lendingPool.getFullInterestAmount(ftmAmount, ellapsed, "385802400000")
        // console.log(Number(payback));
        // await lendingPool.repayLoan(1, { value: payback, from: accounts[1] });
    })
})