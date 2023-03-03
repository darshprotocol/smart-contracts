# Project detail
## Name
Darsh Protocol
![darsh](https://user-images.githubusercontent.com/123966451/222813942-11c8f479-8471-47e3-b119-851bd41202f2.png)

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
> Smart contract
- Truffle and plugins
- Web3js

> Frontend
- Vuejs
- Web3js
- Covalent API
- Jazzicon

> Backend
- Expressjs
- Moralis Stream
- Web3js
- Mongodb

## Languages
- Solidity
- Javascript
- HTML/CSS

## Dependencies
- Chainlink Price Feed
- Openzeppelin

## Sneak peaks

## Team
**Arogundade Ibrahim**
 
**Role:** Developer
 
[contact me](https://linktr.ee/devarogundade)

 
 
**Awolola Idowu**
 
**Role:** UI/UX Designer & Web3 Expert
 
[contact me](https://pip.me/krypton)
