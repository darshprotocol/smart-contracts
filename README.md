# Project detail
## Name
Darsh Protocol

## About
Darsh's mission is to create a socialized way of lending and borrowing while maintaining DeFi's autonomy and permissionlessness by offering a decentralized peer to peer way for any individual to engage as a lender or borrower.

Our main goal is to provide an efficient and sustainable way for lenders to maximize their rewards on supplied asset by enabling them the ability to structure their loan terms while also removing the risk of an unexpected liquidation of a borrower's collateralized loan all being settled on-chain in a fully decentralized manner.

## Links
[website](https://darshprotocol.netlify.app) | [documentation](https://darshprotocol.gitbook.io/product-docs) | [figma design](https://www.figma.com/file/Sxzt8ogh9kVzs3jDVEYeIk/Darsh-Project?node-id=1371-56011&t=3Q91CFDVrVhd6pB5-0) | [devpost](https://devpost.com/software/darsh-protocol)

# Flow diagram
![Loan Diagram](https://user-images.githubusercontent.com/123966451/222807924-377c0485-182d-468a-a16c-978bd75d9317.png)
[view full flow diagram](https://www.figma.com/file/iqIY47PfSbBb0W6fQH835c/Darsh-Flow-Charts?node-id=0%3A1&t=C66NhTmJgB4HB12L-0)

## Features

**Terms Structuring:** Lenders are enabled to create offers with sets of predetermined loan terms, specifying the principal amount and asset type (ERC20), Collateral types, Loan duration, interest rate demanded to be met by a potential borrower.

**Asset Vaulting:** the principal supplied by a Lender is locked into a principal vault accessible to the lender anytime. The vault serves as a decentralized escrow between a lender and borrowers.

**On-Chain matching:** loan offers funded by lenders are matched and settled with a borrower once countersigned, all happening seamlessly with all transactions recorded and fully verifiable on-chain.

**Loan Managing:** on approving and creating a loan offer, lenders are assigned the full authority to a created loan offer of actions like settling borrow requests, repayments claiming, asset vault management all achievable on-chain.

**Offer Bidding:** on a lend loan offer, borrowers are allowed to directly request for a borrow loan offer with loan terms relative to the lend loan initially offered by a lender.

**Permissionless Borrowing:** principals can be borrowed by borrowers permissionlessly from a lend loan offer created by a lender, once the loan terms demanded are met.

**Customed Repayment:** loan repayments are ease for borrowers to reassess their collateralized asset anytime once repaid. Repayments can be paid in proportions or once within the loan duration specified.

[learn more](https://darshprotocol.gitbook.io/product-docs)

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
 
 [view contract on explorer](https://ftmscan.com/address/0xb9669c5d15cbFB85A7E26DA7cEffAEa91f942E7e#code)
 
## Supported tokens
![ftm](https://user-images.githubusercontent.com/123966451/222814337-c1378fdd-3dd5-4e57-9e1f-b8a9d830f91f.png)
![eth](https://user-images.githubusercontent.com/123966451/222814336-3cb5e554-a981-4ff8-86f6-ea7b4f6f1e2d.png)
![usdt](https://user-images.githubusercontent.com/123966451/222814331-f617e15b-8ae9-4c36-a6c9-7ad50c400348.png)
![btc](https://user-images.githubusercontent.com/123966451/222814332-2954a827-153d-492c-97c6-6a1a49715b8f.png)
![dai](https://user-images.githubusercontent.com/123966451/222814334-d291e5d5-0932-4ea4-85ae-e91323f2745c.png)
![usdc](https://user-images.githubusercontent.com/123966451/222814326-154b1313-b1bd-412c-92c6-3a451988293f.png)

## Governance [Coming soon]

![darsh](https://user-images.githubusercontent.com/123966451/222815877-9c242f12-2477-4396-88c5-709d848c4f3b.png)

| **Darsh Token** | **DSH** |

This ensures the protocol can rapidly adjust to changing market conditions, as well as update core parts of the protocol as time goes on.

DARSH token holders will receive governance powers proportionally to their balance.

The governance power which is used to vote for or against existing proposals, and gives access to creating and sustaining a proposal.

## Revenue model
A platform fee of 5% will be deducted from interests paid by borrowers.
> More revenue models will be introduced as we grow and unlock more use cases to our users.

## Sneak peaks
![Desktop - 100 (1)](https://user-images.githubusercontent.com/123966451/222903210-45840f83-0d05-440b-a555-925f38325b50.png)
![Desktop - 102](https://user-images.githubusercontent.com/123966451/222903213-1e17b8cc-4cf8-49e4-b87d-dec96e7050ef.png)
![Desktop - 83](https://user-images.githubusercontent.com/123966451/222903216-c726512a-c815-4fa8-b533-0fe76bca9f13.png)

[checkout full demo here](https://darshprotocol.netlify.app)

## Development
Create a `.env` like the `.env-example` and update with valid keys and mnemonic/phrase or private key

 - Compile contracts

> truffle compile

- Migrate contracts

> truffle migrate --network=testnet|mainnet --compile-none

- Set configs

> truffle test --network=testnet|mainnet --compile-none --t1

- Run test

> truffle test --network=testnet|mainnet --compile-none --f2

- Verify contracts

> truffle verify --network=testnet|mainnet <contracts> --license=MIT

- Run frontend
> npm run dev
 
- Start node backend
> npm run start

## Stacks
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
 
**Position:** Web3 Fullstack Developer
 
[contact me](https://linktr.ee/devarogundade)

 
 
**Awolola Idowu**
 
**Position:** UI/UX Designer
 
[contact me](https://www.pip.me/Kryptograph)
