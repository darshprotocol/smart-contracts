# Project detail
## Name
Darsh Protocol

## About
**Darsh's mission is to create a socialized way of lending and borrowing while maintaining DeFi's autonomy and permissionlessness by offering a decentralized peer to peer way for any individual to engage as a lender or borrower.**

**Our main goal is to provide an efficient and sustainable way for lenders to maximize their rewards on supplied asset by enabling them the ability to structure their loan terms while also removing the risk of an unexpected liquidation of a borrower's collateralized loan all being settled on-chain in a fully decentralized manner.**

## Links
[website](https://darshprotocol.netlify.app) | [documentation](https://darshprotocol.gitbook.io/product-docs) | [figma design](https://darshprotocol.gitbook.io/product-docs) | [devpost](https://devpost.com/software/darsh-protocol)

# Flow diagram
![Loan Diagram](https://user-images.githubusercontent.com/123966451/222807924-377c0485-182d-468a-a16c-978bd75d9317.png)

## LendingPool contract
The LendingPool contract is the main point of interaction with the DARSH protocol's market.

 > Users can:
 - Create Lending/Borrowing offers
 - Request for new terms on offers
 - Repay (Fully/Installment)
 - Claim principal and earnings
 - Claim back collateral
 - Cancel/Reject/Accept requests
 - and more.

 > Admin can:
 - Liquidate matured loans
 - Withdraw accrued fees
 - Change owner
 - Update configs
 
 [view contract on explorer](https://ftmscan.com)
 
## Supported tokens
![ftm](https://user-images.githubusercontent.com/123966451/222814337-c1378fdd-3dd5-4e57-9e1f-b8a9d830f91f.png)
![eth](https://user-images.githubusercontent.com/123966451/222814336-3cb5e554-a981-4ff8-86f6-ea7b4f6f1e2d.png)
![usdt](https://user-images.githubusercontent.com/123966451/222814331-f617e15b-8ae9-4c36-a6c9-7ad50c400348.png)
![btc](https://user-images.githubusercontent.com/123966451/222814332-2954a827-153d-492c-97c6-6a1a49715b8f.png)
![dai](https://user-images.githubusercontent.com/123966451/222814334-d291e5d5-0932-4ea4-85ae-e91323f2745c.png)
![usdc](https://user-images.githubusercontent.com/123966451/222814326-154b1313-b1bd-412c-92c6-3a451988293f.png)

## Governance [Coming soon]

![darsh](https://user-images.githubusercontent.com/123966451/222815877-9c242f12-2477-4396-88c5-709d848c4f3b.png)

| **Darsh Token** | **DARSH** |


## Sneak peaks

[view demo](https://darshprotocol.netlify.app)

## Development
Create a `.env` like the `.env-example` and update with valid keys and mnemonic/phrase or private key

 - Compile contracts

> truffle compile

- Migrate contracts

> truffle migrate --network=testnet|mainnet --compile-none

- Set configs

> truffle test --network=testnet|mainnet --compile-none -t1

- Run test

> truffle test --network=testnet|mainnet --compile-none -f2

- Verify

> truffle verify --network=testnet|mainnet <contracts> --license=MIT

## Tools
 | Smart contract | Frontend | Backend | Design | Cloud services |
 |--|--|--| -- |--|
 | Truffle and plugins | Vuejs | Expressjs | Figma | Netlify |
|Web3js|Web3js|Web3js||Render|
 ||Covalent API| Moralis Stream|||
 ||Jazzicon|Mongodb|||


## Languages
- Solidity
- Javascript
- HTML/CSS

## Dependencies
- Chainlink Price Feed
- Openzeppelin

## Team
**Arogundade Ibrahim**
 
**Role:** Developer
 
[contact me](https://linktr.ee/devarogundade)

 
 
**Awolola Idowu**
 
**Role:** UI/UX Designer & Web3 Expert
 
[contact me](https://pip.me/krypton)
