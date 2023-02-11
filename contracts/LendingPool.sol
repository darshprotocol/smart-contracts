// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./libraries/Errors.sol";
import "./libraries/AssetLibrary.sol";

import "./math/SimpleInterest.sol";

import "./interfaces/IPriceFeed.sol";
import "./interfaces/ILoanToValueRatio.sol";

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

    IPriceFeed private _priceFeed;
    ILoanToValueRatio private _ltv;

    // managers
    PoolManager private _poolManager;
    LoanManager private _loanManager;
    OfferManager private _offerManager;

    address public constant nativeAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

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
        address principalType,
        uint256 _principal, // only for ERC20 assets
        uint256 interest,
        uint256 daysToMaturity,
        uint256 daysToExpire,
        address[] memory collateralTypes
    ) public payable {
        uint256 principalAmount;

        require(collateralTypes.length > 0, "ERR_NO_COLLATERAL_TYPES");

        /* extract tokens from lender */
        if (principalType == nativeAddress) {
            principalAmount = msg.value;
        } else {
            principalAmount = _principal;
            ERC20(principalType).transferFrom(
                _msgSender(),
                address(this),
                principalAmount
            );
        }

        require(
            _poolManager.deposit(_msgSender(), principalType, principalAmount),
            "ERR_POOL_MANAGER_DEPOSIT"
        );

        /* create the offer */
        require(
            _offerManager.createLendingOffer(
                principalType,
                principalAmount,
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
    function acceptBorrowingOffer(uint256 offerId, uint16 desiredPercentage)
        public
        payable
    {
        OfferLibrary.BorrowingOffer memory offer = _offerManager
            .getBorrowingOffer(offerId);

        // platform safety
        require(offer.expiresAt > block.timestamp, "ERR_OFFER_EXPIRED");
        require(_msgSender() != offer.borrower, "ERR_CANT_BORROW_OWN");

        // percentage must be 25, 50, 75 or 100
        require(desiredPercentage <= 100, "OVER_PERCENTAGE");
        require(desiredPercentage % 25 == 0, "ERR_PERCENTAGE");

        uint256 collateralAmount = percentageOf(
            offer.initialCollateral,
            desiredPercentage
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            desiredPercentage
        );

        // verify if the remain offer is enough
        require(
            offer.currentCollateral >= collateralAmount &&
                offer.currentPrincipal >= principalAmount,
            "ERR_COLLATERAL_BALANCE"
        );

        /* extract principal from lender */
        /* transfer principal to borrower */
        if (offer.principalType == nativeAddress) {
            // if principal is native coin
            require(msg.value >= principalAmount);
            payable(offer.borrower).transfer(principalAmount);
        } else {
            // if principal is ERC20
            ERC20(offer.principalType).transferFrom(
                _msgSender(),
                address(this),
                principalAmount
            );
            ERC20(offer.principalType).transfer(
                offer.borrower,
                principalAmount
            );
        }

        /* register the loan from the loan manager */
        require(
            _loanManager.createLoan(
                offer.offerId,
                OfferLibrary.Type.BORROWING_OFFER,
                offer.principalType,
                offer.collateralType,
                principalAmount,
                collateralAmount,
                offer.interest,
                offer.daysToMaturity,
                offer.borrower,
                _msgSender()
            ) > 0,
            "ERR_LOAN_MANAGER_CREATE"
        );

        _offerManager._afterOfferBorrowingLoan(offerId, collateralAmount);
    }

    // @lenders
    function acceptBorrowingRequest(uint256 requestId) public payable {
        RequestLibrary.BorrowingRequest memory request = _offerManager
            .getBorrowingRequest(requestId);

        require(request.expiresAt > block.timestamp, "ERR_REQUEST_EXPIRED");

        OfferLibrary.LendingOffer memory offer = _offerManager.getLendingOffer(
            request.offerId
        );
        require(offer.lender == _msgSender(), "ERR_ONLY_LENDER");

        // verify if the remain offer is enough
        require(
            offer.currentPrincipal >= request.principalAmount,
            "ERR_INSUFICIENT"
        );

        /* extract principal from lender */
        /* transfer principal to borrower */
        if (offer.principalType == nativeAddress) {
            // if principal is native coin
            require(msg.value >= request.principalAmount);
            payable(request.borrower).transfer(request.principalAmount);
        } else {
            // if principal is ERC20
            ERC20(offer.principalType).transferFrom(
                _msgSender(),
                address(this),
                request.principalAmount
            );
            ERC20(offer.principalType).transfer(
                request.borrower,
                request.principalAmount
            );
        }

        /* register the loan from the loan manager */
        require(
            _loanManager.createLoan(
                request.offerId,
                OfferLibrary.Type.LENDING_OFFER,
                offer.principalType,
                request.collateralType,
                request.principalAmount,
                request.collateralAmount,
                request.interest,
                request.daysToMaturity,
                request.borrower,
                _msgSender()
            ) > 0,
            "ERR_LOAN_MANAGER_CREATE"
        );

        _offerManager._afterOfferLendingLoan(
            offer.offerId,
            request.principalAmount
        );
    }

    // @borrower
    function createBorrowingOffer(
        address principalType,
        address collateralType,
        uint256 _collateral, // for ERC20 assets
        uint256 interest,
        uint256 daysToMaturity,
        uint256 daysToExpire
    ) public payable {
        uint256 collateralAmount;

        /* extract collateral from borrower */
        if (collateralType == nativeAddress) {
            collateralAmount = msg.value;
        } else {
            collateralAmount = _collateral;
            ERC20(collateralType).transferFrom(
                _msgSender(),
                address(this),
                collateralAmount
            );
        }

        uint16 ltv = _ltv.getLTV(_msgSender());

        uint256 principalPrice = _priceFeed.exchangeRate(
            collateralType,
            principalType,
            collateralAmount
        );

        uint256 principalAmount = percentageInverseOf(principalPrice, ltv) /
            _ltv.getBase();

        /* deposit tokens to vault */
        require(
            _poolManager.deposit(
                _msgSender(),
                collateralType,
                collateralAmount
            ),
            "ERR_POOL_MANAGER_DEPOSIT"
        );

        /* create the offer */
        require(
            _offerManager.createBorrowingOffer(
                principalType,
                collateralType,
                collateralAmount,
                principalAmount,
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
        uint16 desiredPercentage,
        address collateralType
    ) public payable {
        OfferLibrary.LendingOffer memory offer = _offerManager.getLendingOffer(
            offerId
        );

        require(offer.expiresAt > block.timestamp, "ERR_OFFER_EXPIRED");
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

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            desiredPercentage
        );

        require(
            principalAmount <= offer.currentPrincipal,
            "ERR_INSUFFICIENT_AMOUNT"
        );

        /* get the trust factor of the borrower */
        uint16 ltv = _ltv.getLTV(_msgSender());

        /* calculate the collateral amount */
        uint256 priceInFullCollateral = _priceFeed.exchangeRate(
            offer.principalType,
            collateralType,
            principalAmount
        );

        uint256 collateralAmount = percentageOf(priceInFullCollateral, ltv) /
            _ltv.getBase();

        /* extract collateral tokens from borrower */
        if (collateralType == nativeAddress) {
            require(collateralAmount >= msg.value, "ERR_COLLATERAL_AMOUNT");
        } else {
            ERC20(collateralType).transferFrom(
                _msgSender(),
                address(this),
                collateralAmount
            );
        }

        require(
            _poolManager.deposit(
                _msgSender(),
                collateralType,
                collateralAmount
            ),
            "ERR_POOL_MANAGER_DEPOSIT"
        );

        /* transfer the asset to borrower */
        _poolManager.withdraw(
            _msgSender(),
            offer.principalType,
            principalAmount
        );

        if (offer.principalType == nativeAddress) {
            payable(_msgSender()).transfer(principalAmount);
        } else {
            ERC20(offer.principalType).safeTransfer(
                _msgSender(),
                principalAmount
            );
        }

        /* update offer balance */
        _offerManager._afterOfferLendingLoan(offerId, principalAmount);

        /* register the loan */
        _loanManager.createLoan(
            offerId,
            OfferLibrary.Type.LENDING_OFFER,
            offer.principalType,
            collateralType,
            principalAmount,
            collateralAmount,
            offer.interest,
            offer.daysToMaturity,
            _msgSender(),
            offer.lender
        );

        // amount in USD
        // _activity.borrowLoan(_msgSender(), 0);
    }

    // @borrower
    function acceptLendingRequest(uint256 requestId) public payable {
        RequestLibrary.LendingRequest memory request = _offerManager
            .getLendingRequest(requestId);

        require(request.expiresAt > block.timestamp, "ERR_REQUEST_EXPIRED");
        // require(request.borrower == _msgSender(), "ERR_ONLY_BORROWER");

        OfferLibrary.BorrowingOffer memory offer = _offerManager
            .getBorrowingOffer(request.offerId);

        uint256 collateralAmount = percentageOf(
            offer.initialCollateral,
            request.desiredPercentage
        );

        uint256 principalNormalAmount = _priceFeed.exchangeRate(
            offer.collateralType,
            offer.principalType,
            offer.initialCollateral
        );

        uint16 ltv = _ltv.getLTV(_msgSender());

        uint256 principalAmount = percentageInverseOf(
            principalNormalAmount,
            ltv
        ) / _ltv.getBase();

        // verify if the remain offer is enough
        require(offer.currentCollateral >= collateralAmount, "ERR_INSUFICIENT");

        /* extract principal from lender */
        /* transfer principal to borrower */
        if (offer.principalType == nativeAddress) {
            // if principal is native coin
            require(msg.value >= principalAmount);
            payable(_msgSender()).transfer(principalAmount);
        } else {
            // if principal is ERC20
            ERC20(offer.principalType).transferFrom(
                _msgSender(),
                address(this),
                principalAmount
            );
            ERC20(offer.principalType).transfer(_msgSender(), principalAmount);
        }

        /* register the loan from the loan manager */
        require(
            _loanManager.createLoan(
                request.offerId,
                OfferLibrary.Type.LENDING_OFFER,
                offer.principalType,
                offer.collateralType,
                principalAmount,
                collateralAmount,
                request.interest,
                request.daysToMaturity,
                _msgSender(),
                request.lender
            ) > 0,
            "ERR_LOAN_MANAGER_CREATE"
        );

        _offerManager._afterOfferLendingLoan(offer.offerId, principalAmount);
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

        /* extract pay back amount */
        if (loan.principalType == nativeAddress) {
            // if principal is native coin
            require(msg.value >= repayAmount);
        } else {
            // if principal is ERC20 token
            ERC20(loan.principalType).transferFrom(
                _msgSender(),
                address(this),
                repayAmount
            );
        }

        /* transfer collateral */
        if (loan.collateralType == nativeAddress) {
            // if collateral is native coin
            payable(_msgSender()).transfer(loan.currentCollateral);
        } else {
            // if collateral is ERC20 token
            ERC20(loan.collateralType).transfer(
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

    function changeOwner(address newOwner) public onlyOwner {
        deployer = newOwner;
    }

    modifier onlyOwner() {
        require(_msgSender() == deployer, "ERR_ONLY_OWNER");
        _;
    }
}
