// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./Activity.sol";
import "./TrustScore.sol";

import "./data/TokenFeed.sol";

import "./libraries/Errors.sol";
import "./libraries/AssetLibrary.sol";

import "./math/SimpleInterest.sol";

import "./interfaces/IPriceFeed.sol";

import "./managers/LoanManager.sol";
import "./managers/OfferManager.sol";
import "./managers/PoolManager.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LendingPool is Context, ReentrancyGuard, SimpleInterest {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address deployer;

    Activity private _activity;
    TokenFeed private _tokenFeed;
    IPriceFeed private _priceFeed;
    TrustScore private _trustScore;

    // managers
    PoolManager private _poolManager;
    LoanManager private _loanManager;
    OfferManager private _offerManager;

    constructor(
        address poolManager_,
        address loanManager_,
        address offerManager_
    ) ReentrancyGuard() {
        deployer = _msgSender();

        _poolManager = PoolManager(poolManager_);
        _loanManager = LoanManager(loanManager_);
        _offerManager = OfferManager(offerManager_);
    }

    // @lenders
    function createLendingOffer(
        AssetLibrary.Type principalType,
        uint256 _principal, // only for ERC20 assets
        uint256 interest,
        uint256 daysToMaturity,
        uint256 daysToExpire,
        AssetLibrary.Type[] memory collateralTypes
    ) public payable {
        uint256 principal;

        /* checks if the lender is a defaulter */
        require(!_activity.isDefaulter(_msgSender()), "ERR_UNSAFE_LENDER");

        require(collateralTypes.length > 0, "ERR_NO_COLLATERAL_TYPES");

        /* derive the address of the principal from data repository */
        address principalToken = _tokenFeed.getTokenAddress(principalType);

        /* extract tokens from lender */
        if (principalToken == _tokenFeed.nativeAddress()) {
            principal = msg.value;
        } else {
            principal = _principal;
            ERC20(principalToken).transferFrom(
                _msgSender(),
                address(this),
                principal
            );
        }

        require(
            _poolManager.deposit(_msgSender(), principalToken, principal),
            "ERR_POOL_MANAGER_DEPOSIT"
        );

        /* create the offer */
        require(
            _offerManager.createLendingOffer(
                principalType,
                principal,
                interest,
                daysToMaturity,
                daysToExpire,
                collateralTypes,
                _msgSender()
            ) > 0,
            "ERR_OFFER_MANAGER_CREATE"
        );
    }

    // @lenders
    function acceptBorrowingOffer(uint256 offerId, uint256 desiredPercentage)
        public
        payable
    {
        OfferLibrary.BorrowingOffer memory offer = _offerManager
            .getBorrowingOffer(offerId);

        // platform safety
        require(offer.expiresAt > block.timestamp, "ERR_OFFER_EXPIRED");
        require(!_activity.isDefaulter(offer.borrower), "ERR_UNSAFE_BORROWER");
        require(_msgSender() != offer.borrower, "ERR_CANT_BORROW_OWN");

        // percentage must be 25, 50, 75 or 100
        require(desiredPercentage <= 100, "OVER_PERCENTAGE");
        require(desiredPercentage % 25 == 0, "ERR_PERCENTAGE");

        uint256 collateral = percentageOf(
            offer.initialCollateral,
            desiredPercentage
        );

        // verify if the remain offer is enough
        require(offer.currentCollateral >= collateral);

        /* derive the address of the asset types from data repository */
        address principalToken = _tokenFeed.getTokenAddress(
            offer.principalType
        );
        address collateralToken = _tokenFeed.getTokenAddress(
            offer.collateralType
        );

        /* get the trust factor of the borrower */
        uint256 pendingLoans = _activity.pendingLoans(offer.borrower);
        (, uint256 percentage) = _trustScore.inverseTrustGrade(
            offer.borrower,
            pendingLoans
        );

        /* calculate the collateral amount */
        uint256 priceInFullPrincipal = _priceFeed.exchangeRate(
            collateralToken,
            principalToken,
            collateral
        );

        uint256 principal = percentageOf(priceInFullPrincipal, percentage);

        /* extract principal from lender */
        /* transfer principal to borrower */
        if (principalToken == _tokenFeed.nativeAddress()) {
            // if principal is native coin
            require(msg.value >= principal);
            payable(offer.borrower).transfer(principal);
        } else {
            // if principal is ERC20
            ERC20(principalToken).transferFrom(
                _msgSender(),
                address(this),
                principal
            );
            ERC20(principalToken).transfer(offer.borrower, principal);
        }

        /* register the loan from the loan manager */
        require(
            _loanManager.createLoan(
                offer.offerId,
                OfferLibrary.Type.BORROWING_OFFER,
                offer.principalType,
                offer.collateralType,
                principal,
                collateral,
                offer.interest,
                offer.daysToMaturity,
                offer.borrower,
                _msgSender()
            ) > 0,
            "ERR_LOAN_MANAGER_CREATE"
        );

        _offerManager._afterOfferBorrowingLoan(offerId, collateral);
    }

    // @lenders
    function acceptBorrowingRequest(uint256 requestId) public payable {
        RequestLibrary.BorrowingRequest memory request = _offerManager
            .getBorrowingRequest(requestId);

        // platform safety
        require(
            !_activity.isDefaulter(request.borrower),
            "ERR_UNSAFE_BORROWER"
        );
        require(request.expiresAt > block.timestamp, "ERR_REQUEST_EXPIRED");
        require(
            _offerManager.belongsTo(
                request.offerId,
                _msgSender(),
                OfferLibrary.Type.LENDING_OFFER
            ),
            "ERR_ONLY_LENDER"
        );

        OfferLibrary.LendingOffer memory offer = _offerManager.getLendingOffer(
            request.offerId
        );

        /* derive the address of the asset types from data repository */
        address principalToken = _tokenFeed.getTokenAddress(
            offer.principalType
        );
        address collateralToken = _tokenFeed.getTokenAddress(
            request.collateralType
        );

        /* get the trust factor of the borrower */
        uint256 pendingLoans = _activity.pendingLoans(request.borrower);
        (, uint256 percentage) = _trustScore.inverseTrustGrade(
            request.borrower,
            pendingLoans
        );

        /* calculate the collateral amount */
        uint256 priceInFullPrincipal = _priceFeed.exchangeRate(
            collateralToken,
            principalToken,
            request.collateral
        );

        uint256 principal = percentageOf(priceInFullPrincipal, percentage);

        // verify if the remain offer is enough
        require(offer.currentPrincipal >= principal, "ERR_INSUFICIENT");

        /* extract principal from lender */
        /* transfer principal to borrower */
        if (principalToken == _tokenFeed.nativeAddress()) {
            // if principal is native coin
            require(msg.value >= principal);
            payable(request.borrower).transfer(principal);
        } else {
            // if principal is ERC20
            ERC20(principalToken).transferFrom(
                _msgSender(),
                address(this),
                principal
            );
            ERC20(principalToken).transfer(request.borrower, principal);
        }

        /* register the loan from the loan manager */
        require(
            _loanManager.createLoan(
                request.offerId,
                OfferLibrary.Type.LENDING_OFFER,
                offer.principalType,
                request.collateralType,
                principal,
                request.collateral,
                request.interest,
                request.daysToMaturity,
                request.borrower,
                _msgSender()
            ) > 0,
            "ERR_LOAN_MANAGER_CREATE"
        );

        _offerManager._afterOfferLendingLoan(offer.offerId, principal);
    }

    // @borrower
    function createBorrowingOffer(
        AssetLibrary.Type principalType,
        AssetLibrary.Type collateralType,
        uint256 _collateral, // for ERC20 assets
        uint256 interest,
        uint256 daysToMaturity,
        uint256 daysToExpire
    ) public payable {
        uint256 collateral;

        /* checks if the borrower is a defaulter */
        require(!_activity.isDefaulter(_msgSender()), "ERR_UNSAFE_BORROWER");

        /* derive the address of the collateral from data repository */
        address collateralToken = _tokenFeed.getTokenAddress(collateralType);

        /* extract collateral from borrower */
        if (collateralToken == _tokenFeed.nativeAddress()) {
            collateral = msg.value;
        } else {
            collateral = _collateral;
            ERC20(collateralToken).transferFrom(
                _msgSender(),
                address(this),
                collateral
            );
        }

        /* deposit tokens to vault */
        require(
            _poolManager.deposit(_msgSender(), collateralToken, collateral),
            "ERR_POOL_MANAGER_DEPOSIT"
        );

        /* create the offer */
        require(
            _offerManager.createBorrowingOffer(
                principalType,
                collateralType,
                collateral,
                interest,
                daysToMaturity,
                daysToExpire,
                _msgSender()
            ) > 0,
            "ERR_OFFER_MANAGER_CREATE"
        );
    }

    // @borrower
    function acceptLendingOffer(
        uint256 offerId,
        uint256 desiredPercentage,
        AssetLibrary.Type collateralType
    ) public payable {
        OfferLibrary.LendingOffer memory offer = _offerManager.getLendingOffer(
            offerId
        );

        // percentage must be 25, 50, 75 or 100
        require(desiredPercentage <= 100, "OVER_PERCENTAGE");
        require(desiredPercentage % 25 == 0, "ERR_PERCENTAGE");

        bool supported = false;
        for (uint256 index = 0; index < offer.collateralTypes.length; index++) {
            if (offer.collateralTypes[index] == collateralType) {
                supported = true;
                break;
            }
        }
        require(supported, "ERR_COLLATERAL_NOT_SUPPORTED");

        require(offer.expiresAt > block.timestamp, "ERR_OFFER_EXPIRED");

        uint256 desiredAmount = percentageOf(
            offer.initialPrincipal,
            desiredPercentage
        );

        require(
            desiredAmount <= offer.currentPrincipal,
            "ERR_INSUFFICIENT_AMOUNT"
        );

        /* checks if the lender is a defaulter */
        /* checks if the borrower is a defaulter */
        require(!_activity.isDefaulter(offer.lender), "ERR_UNSAFE_LENDER");
        require(!_activity.isDefaulter(_msgSender()), "ERR_UNSAFE_BORROWER");

        /* derive the address of the asset types from data repository */
        address principalToken = _tokenFeed.getTokenAddress(
            offer.principalType
        );
        address collateralToken = _tokenFeed.getTokenAddress(collateralType);

        /* get the trust factor of the borrower */
        uint256 pendingLoans = _activity.pendingLoans(_msgSender());
        (, uint256 percentage) = _trustScore.trustGrade(
            _msgSender(),
            pendingLoans
        );

        /* calculate the collateral amount */
        uint256 priceInFullCollateral = _priceFeed.exchangeRate(
            principalToken,
            collateralToken,
            desiredAmount
        );

        uint256 collateral = percentageOf(priceInFullCollateral, percentage);

        /* extract collateral tokens from borrower */
        if (collateralToken == _tokenFeed.nativeAddress()) {
            require(collateral >= msg.value, "ERR_COLLATERAL_AMOUNT");
        } else {
            ERC20(collateralToken).transferFrom(
                _msgSender(),
                address(this),
                collateral
            );
        }

        require(
            _poolManager.deposit(_msgSender(), collateralToken, collateral),
            "ERR_POOL_MANAGER_DEPOSIT"
        );

        /* transfer the asset to borrower */
        _poolManager.withdraw(_msgSender(), principalToken, desiredAmount);

        if (principalToken == _tokenFeed.nativeAddress()) {
            payable(_msgSender()).transfer(desiredAmount);
        } else {
            ERC20(principalToken).safeTransfer(_msgSender(), desiredAmount);
        }

        /* update offer balance */
        _offerManager._afterOfferLendingLoan(offerId, desiredAmount);

        /* register the loan */
        _loanManager.createLoan(
            offerId,
            OfferLibrary.Type.LENDING_OFFER,
            offer.principalType,
            collateralType,
            desiredAmount,
            collateral,
            offer.interest,
            offer.daysToMaturity,
            _msgSender(),
            offer.lender
        );

        /* update experience */
        // amount in USD
        _activity.incrementBorrowed(_msgSender(), 0);
    }

    // @borrower
    function acceptLendingRequest(uint256 requestId) public payable {
        RequestLibrary.LendingRequest memory request = _offerManager
            .getLendingRequest(requestId);

        // platform safety
        require(!_activity.isDefaulter(request.lender), "ERR_UNSAFE_LENDER");
        require(request.expiresAt > block.timestamp, "ERR_REQUEST_EXPIRED");
        require(
            _offerManager.belongsTo(
                request.offerId,
                _msgSender(),
                OfferLibrary.Type.BORROWING_OFFER
            ),
            "ERR_ONLY_BORROWER"
        );

        OfferLibrary.BorrowingOffer memory offer = _offerManager
            .getBorrowingOffer(request.offerId);

        /* derive the address of the asset types from data repository */
        address principalToken = _tokenFeed.getTokenAddress(
            offer.principalType
        );
        address collateralToken = _tokenFeed.getTokenAddress(
            offer.collateralType
        );

        uint256 collateral = percentageOf(
            offer.initialCollateral,
            request.desiredPercentage
        );

        uint256 principal = _priceFeed.exchangeRate(
            collateralToken,
            principalToken,
            offer.initialCollateral
        );

        // verify if the remain offer is enough
        require(offer.currentCollateral >= collateral, "ERR_INSUFICIENT");

        /* extract principal from lender */
        /* transfer principal to borrower */
        if (principalToken == _tokenFeed.nativeAddress()) {
            // if principal is native coin
            require(msg.value >= principal);
            payable(_msgSender()).transfer(principal);
        } else {
            // if principal is ERC20
            ERC20(principalToken).transferFrom(
                _msgSender(),
                address(this),
                principal
            );
            ERC20(principalToken).transfer(_msgSender(), principal);
        }

        /* register the loan from the loan manager */
        require(
            _loanManager.createLoan(
                request.offerId,
                OfferLibrary.Type.LENDING_OFFER,
                offer.principalType,
                offer.collateralType,
                principal,
                collateral,
                request.interest,
                request.daysToMaturity,
                _msgSender(),
                request.lender
            ) > 0,
            "ERR_LOAN_MANAGER_CREATE"
        );

        _offerManager._afterOfferLendingLoan(offer.offerId, principal);
    }

    function repayLoan(uint256 loanId) public payable {
        LoanLibrary.Loan memory loan = _loanManager.getLoan(loanId);

        // verify the borrower is the repayer
        require(loan.borrower == _msgSender(), "ERR_NOT_BORROWER");

        // ensure valid initial loan state when starting loan
        require(loan.state == LoanLibrary.State.ACTIVE, "ERR_LOAN_NOT_ACTIVE");

        // calculate the duration of the loan
        uint256 time = block.timestamp;
        uint256 ellapsedSecs = (time - loan.startDate);

        // calculate the pay back amount
        uint256 repayAmount = getFullInterestAmount(
            loan.currentPrincipal,
            ellapsedSecs,
            loan.interest
        );

        // update ledger book
        _loanManager.repayLoanAll(loanId);

        /* derive the address of the collateral from data repository */
        address principalToken = _tokenFeed.getTokenAddress(loan.principalType);
        address collateralToken = _tokenFeed.getTokenAddress(
            loan.collateralType
        );

        /* extract pay back amount */
        if (principalToken == _tokenFeed.nativeAddress()) {
            // if principal is native coin
            require(msg.value >= repayAmount);
        } else {
            // if principal is ERC20 token
            ERC20(principalToken).transferFrom(
                _msgSender(),
                address(this),
                repayAmount
            );
        }

        /* transfer collateral */
        if (collateralToken == _tokenFeed.nativeAddress()) {
            // if collateral is native coin
            payable(_msgSender()).transfer(loan.currentCollateral);
        } else {
            // if collateral is ERC20 token
            ERC20(collateralToken).transfer(
                _msgSender(),
                loan.currentCollateral
            );
        }
    }

    function repayLiquidatedLoan(uint256 loanId) public payable {
        LoanLibrary.Loan memory loan = _loanManager.getLoan(loanId);

        bool liquidated = loan.state == LoanLibrary.State.LIQUIDATED;
        require(liquidated);
    }

    function setPriceFeed(address priceFeed_) public onlyOwner {
        _priceFeed = IPriceFeed(priceFeed_);
    }

    function setTokenFeed(address tokenFeed_) public onlyOwner {
        _tokenFeed = TokenFeed(tokenFeed_);
    }

    function setTrustScore(address trustScore_) public onlyOwner {
        _trustScore = TrustScore(trustScore_);
    }

    function setActivity(address activity_) public onlyOwner {
        _activity = Activity(activity_);
    }

    function changeOwner(address newOwner) public onlyOwner {
        deployer = newOwner;
    }

    modifier onlyOwner() {
        require(_msgSender() == deployer, "ERR_ONLY_OWNER");
        _;
    }
}
