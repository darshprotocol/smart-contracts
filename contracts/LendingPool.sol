// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./Activity.sol";

import "./libraries/Errors.sol";
import "./libraries/PoolLibrary.sol";

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

    Activity private _activity;
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
        _poolManager = PoolManager(poolManager_);
        _loanManager = LoanManager(loanManager_);
        _offerManager = OfferManager(offerManager_);

        deployer = _msgSender();
    }

    // @lenders
    function createLendingOffer(
        uint256 principalAmount_, // only for ERC20 assets
        address principalToken,
        address[] memory collateralTokens,
        uint16 daysToMaturity,
        uint256 interest,
        uint16 daysToExpire
    ) public payable {
        uint256 principalAmount;

        require(collateralTokens.length > 0, "ERR_NO_COLLATERAL_TYPES");

        /* extract tokens from lender */
        if (principalToken == nativeAddress) {
            principalAmount = msg.value;
        } else {
            principalAmount = principalAmount_;
            ERC20(principalToken).transferFrom(
                _msgSender(),
                address(this),
                principalAmount
            );
        }

        /* delegate principal to lender */
        _poolManager.deposit(_msgSender(), principalToken, principalAmount);

        /* create the lending offer */
        _offerManager.createLendingOffer(
            principalToken,
            principalAmount,
            interest,
            daysToMaturity,
            daysToExpire,
            collateralTokens,
            _msgSender()
        );
    }

    // @lenders
    function createLendingRequest(
        uint160 offerId,
        uint16 percentage,
        uint16 daysToMaturity,
        uint256 interest,
        uint16 daysToExpire
    ) public payable {
        _checkPercentage(percentage);

        OfferLibrary.LendingOffer memory offer = _offerManager.getLendingOffer(
            offerId
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            percentage
        );

        /* extract tokens from lender */
        if (offer.principalToken == nativeAddress) {
            require(msg.value >= principalAmount);
        } else {
            ERC20(offer.principalToken).transferFrom(
                _msgSender(),
                address(this),
                principalAmount
            );
        }

        /* delegate principal to lender */
        _poolManager.deposit(
            _msgSender(),
            offer.principalToken,
            principalAmount
        );

        /* create the lending request */
        _offerManager.createLendingRequest(
            percentage,
            interest,
            daysToMaturity,
            daysToExpire,
            _msgSender(),
            offerId
        );
    }

    // @lenders
    function acceptBorrowingOffer(uint160 offerId, uint16 percentage)
        public
        payable
    {
        _checkPercentage(percentage);

        OfferLibrary.BorrowingOffer memory offer = _offerManager
            .getBorrowingOffer(offerId);

        require(_msgSender() != offer.borrower, "ERR_CANT_BORROW_OWN");

        uint256 collateralAmount = percentageOf(
            offer.initialCollateral,
            percentage
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            percentage
        );

        /* extract principal from lender/caller and transfer to borrower */
        if (offer.principalToken == nativeAddress) {
            require(msg.value >= principalAmount);
            payable(offer.borrower).transfer(principalAmount);
        } else {
            ERC20(offer.principalToken).transferFrom(
                _msgSender(),
                address(this),
                principalAmount
            );
            ERC20(offer.principalToken).transfer(
                offer.borrower,
                principalAmount
            );
        }

        /* delegate the loan collateral to lender */
        _poolManager.transfer(
            offer.borrower,
            _msgSender(),
            offer.collateralToken,
            collateralAmount
        );
        /* undelegate the principal from lender */
        _poolManager.burn(_msgSender(), offer.principalToken, principalAmount);

        uint256 collateralPriceInUSD = _priceFeed.amountInUSD(
            offer.collateralToken,
            collateralAmount
        );

        /* register the loan from the loan manager */
        _loanManager.createLoan(
            offer.offerId,
            OfferLibrary.Type.BORROWING_OFFER,
            offer.principalToken,
            offer.collateralToken,
            principalAmount,
            collateralAmount,
            collateralPriceInUSD,
            offer.interest,
            offer.daysToMaturity,
            offer.borrower,
            _msgSender()
        );

        // will revert the transaction if fail
        _offerManager._afterOfferBorrowingLoan(
            offerId,
            principalAmount,
            collateralAmount
        );

        // update activity
        uint256 borrowedAmountInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );
        _activity._borrowLoan(offer.borrower, borrowedAmountInUSD);
    }

    // @lenders
    function acceptBorrowingRequest(uint256 requestId) public {
        RequestLibrary.BorrowingRequest memory request = _offerManager
            .getBorrowingRequest(requestId);

        OfferLibrary.LendingOffer memory offer = _offerManager.getLendingOffer(
            request.offerId
        );

        require(offer.lender == _msgSender(), "ERR_ONLY_LENDER");

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            request.percentage
        );

        /* transfer principal to borrower */
        if (offer.principalToken == nativeAddress) {
            payable(request.borrower).transfer(principalAmount);
        } else {
            ERC20(offer.principalToken).transfer(
                request.borrower,
                principalAmount
            );
        }

        /* delegate the loan collateral to lender */
        _poolManager.transfer(
            request.borrower,
            _msgSender(),
            request.collateralToken,
            request.collateralAmount
        );
        /* undelegate the principal from lender */
        _poolManager.burn(_msgSender(), offer.principalToken, principalAmount);

        /* register the loan from the loan manager */
        _loanManager.createLoan(
            request.offerId,
            OfferLibrary.Type.LENDING_OFFER,
            offer.principalToken,
            request.collateralToken,
            principalAmount,
            request.collateralAmount,
            request.collateralPriceInUSD,
            request.interest,
            request.daysToMaturity,
            request.borrower,
            _msgSender()
        );

        // will revert the transaction if fail
        _offerManager._afterOfferBorrowingLoan(
            request.offerId,
            principalAmount,
            request.collateralAmount
        );

        // update activity
        uint256 amountBorrowedInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );
        _activity._borrowLoan(request.borrower, amountBorrowedInUSD);
    }

    // @borrower
    function createBorrowingOffer(
        address principalToken,
        address collateralToken,
        uint256 collateralAmount_, // for ERC20 assets
        uint256 interest,
        uint16 daysToMaturity,
        uint16 daysToExpire
    ) public payable {
        uint256 collateralAmount;

        /* extract collateral from borrower */
        if (collateralToken == nativeAddress) {
            collateralAmount = msg.value;
        } else {
            collateralAmount = collateralAmount_;
            ERC20(collateralToken).transferFrom(
                _msgSender(),
                address(this),
                collateralAmount
            );
        }

        uint256 principalNormalAmount = _priceFeed.exchangeRate(
            collateralToken,
            principalToken,
            collateralAmount
        );

        uint256 principalAmountInUSD = _priceFeed.amountInUSD(
            principalToken,
            principalNormalAmount
        );

        uint160 ltv = _ltv.getRelativeLTV(_msgSender(), principalAmountInUSD);

        uint256 principalAmount = percentageInverseOf(
            principalNormalAmount,
            ltv
        ) / _ltv.getBase();

        /* delegate the collateral to borrower */
        _poolManager.deposit(_msgSender(), collateralToken, collateralAmount);

        /* create the offer */
        _offerManager.createBorrowingOffer(
            principalToken,
            collateralToken,
            collateralAmount,
            principalAmount,
            interest,
            daysToMaturity,
            daysToExpire,
            _msgSender()
        );

        // update activity
        uint256 amountInUSD = _priceFeed.amountInUSD(
            collateralToken,
            collateralAmount
        );
        _activity._dropCollateral(_msgSender(), amountInUSD);
    }

    // @borrower
    function createBorrowingRequest(
        uint160 offerId,
        uint16 percentage,
        address collateralToken,
        uint256 interest,
        uint16 daysToMaturity,
        uint16 daysToExpire
    ) public payable {
        _checkPercentage(percentage);

        OfferLibrary.LendingOffer memory offer = _offerManager.getLendingOffer(
            offerId
        );

        require(
            _offerManager.isCollateralSupported(offerId, collateralToken),
            "ERR_COLLATERAL_NOT_SUPPORTED"
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            percentage
        );

        uint256 principalPriceInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );

        uint160 ltv = _ltv.getRelativeLTV(_msgSender(), principalPriceInUSD);

        uint256 collateralNormalAmount = _priceFeed.exchangeRate(
            offer.principalToken,
            collateralToken,
            principalAmount
        );

        uint256 collateralAmount = percentageOf(collateralNormalAmount, ltv) /
            _ltv.getBase();

        /* extract collateral from borrower */
        if (collateralToken == nativeAddress) {
            require(collateralAmount >= msg.value);
        } else {
            ERC20(collateralToken).transferFrom(
                _msgSender(),
                address(this),
                collateralAmount
            );
        }

        /* delegate the collateral to borrower */
        _poolManager.deposit(_msgSender(), collateralToken, collateralAmount);

        uint256 collateralPriceInUSD = _priceFeed.amountInUSD(
            collateralToken,
            collateralAmount
        );

        /* create the request */
        _offerManager.createBorrowingRequest(
            percentage,
            collateralToken,
            collateralAmount,
            collateralPriceInUSD,
            interest,
            daysToMaturity,
            daysToExpire,
            _msgSender(),
            offerId
        );

        // update activity
        _activity._dropCollateral(_msgSender(), collateralPriceInUSD);
    }

    // @borrower
    function acceptLendingOffer(
        uint160 offerId,
        uint16 percentage,
        address collateralToken
    ) public payable {
        _checkPercentage(percentage);

        OfferLibrary.LendingOffer memory offer = _offerManager.getLendingOffer(
            offerId
        );

        require(
            _offerManager.isCollateralSupported(offerId, collateralToken),
            "ERR_COLLATERAL_NOT_SUPPORTED"
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            percentage
        );

        uint256 principalPriceInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );

        uint160 ltv = _ltv.getRelativeLTV(_msgSender(), principalPriceInUSD);

        /* calculate the collateral amount */
        uint256 collateralNormalAmount = _priceFeed.exchangeRate(
            offer.principalToken,
            collateralToken,
            principalAmount
        );

        uint256 collateralAmount = percentageOf(collateralNormalAmount, ltv) /
            _ltv.getBase();

        /* extract collateral tokens from borrower */
        if (collateralToken == nativeAddress) {
            require(collateralAmount >= msg.value, "ERR_COLLATERAL_AMOUNT");
        } else {
            ERC20(collateralToken).transferFrom(
                _msgSender(),
                address(this),
                collateralAmount
            );
        }

        /* transfer the principal to borrower */
        if (offer.principalToken == nativeAddress) {
            payable(_msgSender()).transfer(principalAmount);
        } else {
            ERC20(offer.principalToken).safeTransfer(
                _msgSender(),
                principalAmount
            );
        }

        /* delegate the loan collateral to lender */
        _poolManager.transfer(
            _msgSender(),
            offer.lender,
            collateralToken,
            collateralAmount
        );
        /* undelegate the loan principal from lender */
        _poolManager.burn(offer.lender, offer.principalToken, principalAmount);

        uint256 collateralPriceInUSD = _priceFeed.amountInUSD(
            collateralToken,
            collateralAmount
        );

        /* register the loan */
        _loanManager.createLoan(
            offerId,
            OfferLibrary.Type.LENDING_OFFER,
            offer.principalToken,
            collateralToken,
            principalAmount,
            collateralAmount,
            collateralPriceInUSD,
            offer.interest,
            offer.daysToMaturity,
            _msgSender(),
            offer.lender
        );

        // will revert if transaction fail
        _offerManager._afterOfferLendingLoan(offerId, principalAmount);

        // update activity
        uint256 amountBorrowedInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );
        _activity._borrowLoan(_msgSender(), amountBorrowedInUSD);
    }

    // @borrower
    function acceptLendingRequest(uint256 requestId) public payable {
        RequestLibrary.LendingRequest memory request = _offerManager
            .getLendingRequest(requestId);

        OfferLibrary.BorrowingOffer memory offer = _offerManager
            .getBorrowingOffer(request.offerId);

        require(offer.borrower == _msgSender(), "ERR_ONLY_BORROWER");

        uint256 collateralAmount = percentageOf(
            offer.initialCollateral,
            request.percentage
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            request.percentage
        );

        /* transfer principal to borrower */
        if (offer.principalToken == nativeAddress) {
            payable(_msgSender()).transfer(principalAmount);
        } else {
            ERC20(offer.principalToken).transfer(_msgSender(), principalAmount);
        }

        /* delegate the loan collateral to lender */
        _poolManager.transfer(
            _msgSender(),
            request.lender,
            offer.collateralToken,
            collateralAmount
        );
        /* undelegate the loan principal from lender */
        _poolManager.burn(
            request.lender,
            offer.principalToken,
            principalAmount
        );

        uint256 collateralPriceInUSD = _priceFeed.amountInUSD(
            offer.collateralToken,
            collateralAmount
        );

        /* register the loan from the loan manager */
        _loanManager.createLoan(
            request.offerId,
            OfferLibrary.Type.LENDING_OFFER,
            offer.principalToken,
            offer.collateralToken,
            principalAmount,
            collateralAmount,
            collateralPriceInUSD,
            request.interest,
            request.daysToMaturity,
            _msgSender(),
            request.lender
        );

        // will revert the transaction if fail
        _offerManager._afterOfferLendingLoan(offer.offerId, principalAmount);

        // update activity
        uint256 amountBorrowedInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );
        _activity._borrowLoan(_msgSender(), amountBorrowedInUSD);
    }

    // @borrower
    function reActivateOffer() public payable {}

    // @borrower
    function reActivateRequest() public payable {}

    // @borrower
    function repayLoan(uint256 loanId, uint16 percentage) public payable {
        LoanLibrary.Loan memory loan = _loanManager.getLoan(loanId);

        // percentage must be 25, 50, 75 or 100
        require(percentage <= 100, "OVER_PERCENTAGE");
        require(percentage % 25 == 0, "ERR_PERCENTAGE");

        // verify the borrower is the repayer
        require(loan.borrower == _msgSender(), "ERR_NOT_BORROWER");

        // calculate the duration of the loan
        uint160 time = uint160(block.timestamp);
        uint160 ellapsedSecs = (time - loan.startDate);

        uint256 principalAmount = percentageOf(
            loan.initialPrincipal,
            percentage
        );

        uint256 collateralAmount = percentageOf(
            loan.initialCollateral,
            percentage
        );

        // calculate the pay back amount
        uint256 repaymentPrincipalAmount = getFullInterestAmount(
            principalAmount,
            ellapsedSecs,
            loan.interest
        );

        // will revert the transaction if fail
        _loanManager.repayLoan(loanId, principalAmount, collateralAmount);

        /* extract pay back amount */
        if (loan.principalToken == nativeAddress) {
            require(msg.value >= repaymentPrincipalAmount);
        } else {
            ERC20(loan.principalToken).transferFrom(
                _msgSender(),
                address(this),
                repaymentPrincipalAmount
            );
        }

        /* transfer collateral */
        if (loan.collateralToken == nativeAddress) {
            payable(_msgSender()).transfer(collateralAmount);
        } else {
            ERC20(loan.collateralToken).transfer(
                _msgSender(),
                collateralAmount
            );
        }

        // update activity
        uint256 interestPaidInUSD = _priceFeed.amountInUSD(
            loan.principalToken,
            (repaymentPrincipalAmount - principalAmount)
        );

        uint256 amountPaidInUSD = _priceFeed.amountInUSD(
            loan.principalToken,
            principalAmount
        );

        _activity._repayLoan(_msgSender(), amountPaidInUSD, interestPaidInUSD);
    }

    function repayLiquidatedLoan(uint256 loanId) public payable {}

    function setLTV(address ltv_) public onlyOwner {
        _ltv = ILoanToValueRatio(ltv_);
    }

    function setActivity(address activity_) public onlyOwner {
        _activity = Activity(activity_);
    }

    function setPriceFeed(address priceFeed_) public onlyOwner {
        _priceFeed = IPriceFeed(priceFeed_);
    }

    function changeOwner(address newOwner) public onlyOwner {
        deployer = newOwner;
    }

    function _checkPercentage(uint16 percentage) private pure {
        // percentage must be 25, 50, 75 or 100
        require(percentage <= 100, "OVER_PERCENTAGE");
        require(percentage % 25 == 0, "ERR_PERCENTAGE");
    }

    modifier onlyOwner() {
        require(_msgSender() == deployer, "ERR_ONLY_OWNER");
        _;
    }
}
