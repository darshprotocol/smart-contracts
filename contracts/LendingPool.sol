// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LendingPoolProvider.sol";

import "./libraries/Errors.sol";

import "./math/SimpleInterest.sol";

import "./interfaces/IPriceFeed.sol";
import "./interfaces/IFeeManager.sol";
import "./interfaces/IOfferManager.sol";
import "./interfaces/ILoanManager.sol";
import "./interfaces/ILoanToValueRatio.sol";
import "./interfaces/IActivity.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title LendingPool contract
 * @dev Main point of interaction with the DARSH protocol's market
 * - Users can:
 *   # Create Lending/Borrowing offers
 *   # Request for new terms on offers
 *   # Repay (Fully/Installment)
 *   # Claim principal and earnings
 *   # Claim back collateral
 *   # Cancel/Reject/Accept requests
 * - All admin functions are callable by the deployer address
 * @author Arogundade Ibrahim
 **/
contract LendingPool is
    LendingPoolProvider,
    Context,
    ReentrancyGuard,
    SimpleInterest,
    Ownable2Step,
    Pausable
{
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /// @dev contract version
    uint256 public constant LENDINGPOOL_VERSION = 0x2;

    IActivity private _activity;
    IPriceFeed private _priceFeed;
    ILoanToValueRatio private _ltvRatio;
    ILoanManager private _loanManager;
    IOfferManager private _offerManager;
    IFeeManager private _feeManager;

    /// @dev for convienency this address is used to represent FTM just like ERC20
    address public constant nativeAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor() ReentrancyGuard() Ownable2Step() {}

    // ============= Create Lending / Borrowing Offer ============ //

    /// @notice This function creates a new lending offer
    /// @dev the principalAmount_ parameter is use for ERC20 tokens only
    function createLendingOffer(
        uint256 principalAmount_,
        address principalToken,
        address[] memory collateralTokens,
        uint16 daysToMaturity,
        uint256 interestRate,
        uint16 daysToExpire
    ) public payable whenNotPaused {
        uint256 principalAmount;

        /* extract tokens from lender */
        if (principalToken == nativeAddress) {
            principalAmount = msg.value;
        } else {
            principalAmount = principalAmount_;
            ERC20(principalToken).safeTransferFrom(
                _msgSender(),
                address(this),
                principalAmount
            );
        }

        /* create the lending offer */
        uint256 offerId = _offerManager.createLendingOffer(
            principalToken,
            principalAmount,
            interestRate,
            daysToMaturity,
            daysToExpire,
            collateralTokens,
            _msgSender()
        );

        transfer(
            offerId,
            _msgSender(),
            principalAmount,
            principalToken,
            Type.ADDED
        );
    }

    /// @notice This function creates a new borrowing offer
    function createBorrowingOffer(
        address principalToken,
        uint256 principalAmount,
        address collateralToken,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire
    ) public payable whenNotPaused {
        uint256 principalAmountInUSD = _priceFeed.amountInUSD(
            principalToken,
            principalAmount
        );

        uint160 ltvRatio = _ltvRatio.getRelativeLTV(
            _msgSender(),
            principalAmountInUSD
        );

        uint256 collateralNormalAmount = _priceFeed.exchangeRate(
            principalToken,
            collateralToken,
            principalAmount
        );

        uint256 collateralAmount = percentageOf(
            collateralNormalAmount,
            ltvRatio / _ltvRatio.getBase()
        );

        if (collateralToken == nativeAddress) {
            require(msg.value >= collateralAmount);
        } else {
            ERC20(collateralToken).safeTransferFrom(
                _msgSender(),
                address(this),
                collateralAmount
            );
        }

        _offerManager.createBorrowingOffer(
            principalToken,
            collateralToken,
            collateralAmount,
            principalAmount,
            interestRate,
            daysToMaturity,
            hoursToExpire,
            _msgSender()
        );

        uint256 amountInUSD = _priceFeed.amountInUSD(
            collateralToken,
            collateralAmount
        );

        _activity.dropCollateral(_msgSender(), amountInUSD);
    }

    // ============ Create Lending / Borrowing Request ============= //

    /// @notice This function creates a new lending request on a borrowing offer
    function createLendingRequest(
        uint256 offerId,
        uint16 percentage,
        uint16 daysToMaturity,
        uint256 interestRate,
        uint16 hoursToExpire
    ) public payable whenNotPaused {
        checkPercentage(percentage);

        OfferLibrary.Offer memory offer = _offerManager.getOffer(offerId);

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            percentage
        );

        if (offer.principalToken == nativeAddress) {
            require(msg.value >= principalAmount);
        } else {
            ERC20(offer.principalToken).safeTransferFrom(
                _msgSender(),
                address(this),
                principalAmount
            );
        }

        /* create the lending request */
        _offerManager.createLendingRequest(
            percentage,
            interestRate,
            daysToMaturity,
            hoursToExpire,
            _msgSender(),
            offerId
        );
    }

    /// @notice This function creates a new borrowing request on a lending offer
    function createBorrowingRequest(
        uint256 offerId,
        uint16 percentage,
        address collateralToken,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire
    ) public payable whenNotPaused {
        checkPercentage(percentage);

        OfferLibrary.Offer memory offer = _offerManager.getOffer(offerId);

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

        uint160 ltvRatio = _ltvRatio.getRelativeLTV(
            _msgSender(),
            principalPriceInUSD
        );

        uint256 collateralNormalAmount = _priceFeed.exchangeRate(
            offer.principalToken,
            collateralToken,
            principalAmount
        );

        uint256 collateralAmount = percentageOf(
            collateralNormalAmount,
            ltvRatio / _ltvRatio.getBase()
        );

        if (collateralToken == nativeAddress) {
            require(collateralAmount >= msg.value);
        } else {
            ERC20(collateralToken).safeTransferFrom(
                _msgSender(),
                address(this),
                collateralAmount
            );
        }

        uint256 collateralPriceInUSD = _priceFeed.amountInUSD(
            collateralToken,
            collateralAmount
        );

        _offerManager.createBorrowingRequest(
            percentage,
            collateralToken,
            collateralAmount,
            collateralPriceInUSD,
            ltvRatio,
            interestRate,
            daysToMaturity,
            hoursToExpire,
            _msgSender(),
            offerId
        );

        _activity.dropCollateral(_msgSender(), collateralPriceInUSD);
    }

    // ============ Accept Lending / Borrowing Offer =============== //

    /// @notice This function accepts a borrowing offer | LEND
    /// @dev The percentage params specifies the portion of the offer to accept
    function acceptBorrowingOffer(uint256 offerId, uint16 percentage)
        public
        payable
        whenNotPaused
    {
        checkPercentage(percentage);

        OfferLibrary.Offer memory offer = _offerManager.getOffer(offerId);

        uint256 collateralAmount = percentageOf(
            offer.initialCollateral,
            percentage
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            percentage
        );

        if (offer.principalToken == nativeAddress) {
            require(msg.value >= principalAmount);
        } else {
            ERC20(offer.principalToken).safeTransferFrom(
                _msgSender(),
                address(this),
                principalAmount
            );
        }

        transfer(
            offerId,
            _msgSender(),
            principalAmount,
            offer.principalToken,
            Type.ADDED
        );

        transfer(
            offerId,
            offer.creator,
            collateralAmount,
            offer.collateralToken,
            Type.LOCKED
        );

        uint256 collateralPriceInUSD = _priceFeed.amountInUSD(
            offer.collateralToken,
            collateralAmount
        );

        _loanManager.createLoan(
            offer.offerId,
            offer.offerType,
            offer.principalToken,
            offer.collateralToken,
            principalAmount,
            collateralAmount,
            collateralPriceInUSD,
            offer.interestRate,
            offer.daysToMaturity,
            principalAmount,
            offer.creator,
            _msgSender()
        );

        _offerManager.afterBorrowingLoan(
            offerId,
            principalAmount,
            collateralAmount
        );

        uint256 borrowedAmountInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );

        _activity.borrowLoan(_msgSender(), offer.creator, borrowedAmountInUSD);
    }

    /// @notice This function accepts a lending offer | BORROW
    /// @dev The percentage params specifies the portion of the offer to accept
    function acceptLendingOffer(
        uint256 offerId,
        uint16 percentage,
        address collateralToken
    ) public payable whenNotPaused {
        checkPercentage(percentage);

        OfferLibrary.Offer memory offer = _offerManager.getOffer(offerId);

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

        uint160 ltvRatio = _ltvRatio.getRelativeLTV(
            _msgSender(),
            principalPriceInUSD
        );

        /* calculate the collateral amount */
        uint256 collateralNormalAmount = _priceFeed.exchangeRate(
            offer.principalToken,
            collateralToken,
            principalAmount
        );

        uint256 collateralAmount = percentageOf(
            collateralNormalAmount,
            ltvRatio / _ltvRatio.getBase()
        );

        if (collateralToken == nativeAddress) {
            require(collateralAmount >= msg.value, "ERR_COLLATERAL_AMOUNT");
        } else {
            ERC20(collateralToken).safeTransferFrom(
                _msgSender(),
                address(this),
                collateralAmount
            );
        }

        transfer(
            offerId,
            _msgSender(),
            collateralAmount,
            collateralToken,
            Type.LOCKED
        );

        if (offer.principalToken == nativeAddress) {
            payable(_msgSender()).transfer(principalAmount);
        } else {
            ERC20(offer.principalToken).safeTransfer(
                _msgSender(),
                principalAmount
            );
        }

        transfer(
            offerId,
            _msgSender(),
            principalAmount,
            offer.principalToken,
            Type.CLAIMED
        );

        uint256 collateralPriceInUSD = _priceFeed.amountInUSD(
            collateralToken,
            collateralAmount
        );

        _loanManager.createLoan(
            offerId,
            offer.offerType,
            offer.principalToken,
            collateralToken,
            principalAmount,
            collateralAmount,
            collateralPriceInUSD,
            offer.interestRate,
            offer.daysToMaturity,
            0,
            _msgSender(),
            offer.creator
        );

        _offerManager.afterLendingLoan(offerId, principalAmount);

        uint256 amountBorrowedInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );

        _activity.borrowLoan(offer.creator, _msgSender(), amountBorrowedInUSD);

        _activity.dropCollateral(_msgSender(), collateralPriceInUSD);
    }

    // =========== Withdraw From Offer ============== //
    function removePrincipal(uint256 offerId, uint16 percentage)
        public
        whenNotPaused
    {
        checkPercentage(percentage);
        OfferLibrary.Offer memory offer = _offerManager.getOffer(offerId);

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            percentage
        );

        if (offer.principalToken == nativeAddress) {
            payable(_msgSender()).transfer(principalAmount);
        } else {
            ERC20(offer.principalToken).safeTransfer(
                _msgSender(),
                principalAmount
            );
        }

        transfer(
            offerId,
            _msgSender(),
            principalAmount,
            offer.principalToken,
            Type.REMOVED
        );

        _offerManager.removePrincipal(offerId, _msgSender(), principalAmount);
    }

    function removeCollateral(uint256 offerId, uint16 percentage)
        public
        whenNotPaused
    {
        checkPercentage(percentage);
        OfferLibrary.Offer memory offer = _offerManager.getOffer(offerId);

        uint256 collateralAmount = percentageOf(
            offer.initialCollateral,
            percentage
        );

        if (offer.collateralToken == nativeAddress) {
            payable(_msgSender()).transfer(collateralAmount);
        } else {
            ERC20(offer.collateralToken).safeTransfer(
                _msgSender(),
                collateralAmount
            );
        }

        transfer(
            offerId,
            _msgSender(),
            collateralAmount,
            offer.collateralToken,
            Type.REMOVED
        );

        _offerManager.removeCollateral(offerId, _msgSender(), collateralAmount);
    }

    // ============ Accept Lending / Borrowing Request =============== //

    /// @notice This funcion accepts a borrowing request placed on a lender's offer
    function acceptBorrowingRequest(uint256 requestId) public whenNotPaused {
        RequestLibrary.Request memory request = _offerManager.getRequest(
            requestId
        );

        require(
            request.requestType == RequestLibrary.Type.BORROWING_REQUEST,
            "ERR_REQUEST_TYPE"
        );

        OfferLibrary.Offer memory offer = _offerManager.getOffer(
            request.offerId
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            request.percentage
        );

        transfer(
            request.offerId,
            request.creator,
            request.collateralAmount,
            request.collateralToken,
            Type.LOCKED
        );

        _loanManager.createLoan(
            request.offerId,
            offer.offerType,
            offer.principalToken,
            request.collateralToken,
            principalAmount,
            request.collateralAmount,
            request.collateralPriceInUSD,
            request.interestRate,
            request.daysToMaturity,
            principalAmount,
            request.creator,
            _msgSender()
        );

        notify(_msgSender(), request.creator, ACCEPT_REQUEST, request.offerId);

        _offerManager.afterLendingLoan(request.offerId, principalAmount);
        _offerManager.acceptRequest(requestId, _msgSender());

        uint256 amountBorrowedInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );

        _activity.borrowLoan(
            _msgSender(),
            request.creator,
            amountBorrowedInUSD
        );
    }

    /// @notice This funcion accepts a lending request placed on a borrower's offer
    function acceptLendingRequest(uint256 requestId)
        public
        payable
        whenNotPaused
    {
        RequestLibrary.Request memory request = _offerManager.getRequest(
            requestId
        );

        require(
            request.requestType == RequestLibrary.Type.LENDING_REQUEST,
            "ERR_REQUEST_TYPE"
        );

        OfferLibrary.Offer memory offer = _offerManager.getOffer(
            request.offerId
        );

        uint256 collateralAmount = percentageOf(
            offer.initialCollateral,
            request.percentage
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            request.percentage
        );

        transfer(
            request.offerId,
            _msgSender(),
            collateralAmount,
            offer.collateralToken,
            Type.LOCKED
        );

        if (offer.principalToken == nativeAddress) {
            payable(_msgSender()).transfer(principalAmount);
        } else {
            ERC20(offer.principalToken).safeTransfer(
                _msgSender(),
                principalAmount
            );
        }

        transfer(
            request.offerId,
            _msgSender(),
            principalAmount,
            offer.principalToken,
            Type.CLAIMED
        );

        notify(_msgSender(), request.creator, ACCEPT_REQUEST, request.offerId);

        uint256 collateralPriceInUSD = _priceFeed.amountInUSD(
            offer.collateralToken,
            collateralAmount
        );

        _loanManager.createLoan(
            request.offerId,
            offer.offerType,
            offer.principalToken,
            offer.collateralToken,
            principalAmount,
            collateralAmount,
            collateralPriceInUSD,
            request.interestRate,
            request.daysToMaturity,
            0,
            _msgSender(),
            request.creator
        );

        _offerManager.afterBorrowingLoan(
            offer.offerId,
            principalAmount,
            collateralAmount
        );

        _offerManager.acceptRequest(requestId, _msgSender());

        uint256 amountBorrowedInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );

        _activity.borrowLoan(
            request.creator,
            _msgSender(),
            amountBorrowedInUSD
        );
    }

    // ============= ReActivating Lending / Borrowing Offer ============= //

    /// @notice This function will reactivate a offer when they expires
    function reActivateOffer(uint256 offerId, uint16 toExpire)
        public
        whenNotPaused
    {
        _offerManager.reActivateOffer(offerId, toExpire, _msgSender());
    }

    // =============== Loan Repayment ============= //

    /// @notice This function is use to repay a loan
    /// @dev The percentage params specifies the portion to be repaid
    function repayLoan(uint256 loanId, uint16 percentage)
        public
        payable
        whenNotPaused
    {
        checkPercentage(percentage);

        LoanLibrary.Loan memory loan = _loanManager.getLoan(loanId);

        require(loan.borrower == _msgSender(), "ERR_NOT_BORROWER");

        uint256 time = block.timestamp;
        uint256 ellapsedSecs = (time - loan.startDate);

        uint256 principalAmount = percentageOf(
            loan.initialPrincipal,
            percentage
        );

        uint256 collateralAmount = percentageOf(
            loan.initialCollateral,
            percentage
        );

        uint256 repaymentPrincipal = getFullInterestAmount(
            principalAmount,
            ellapsedSecs,
            loan.interestRate
        );

        uint256 interestPaid = (repaymentPrincipal - principalAmount);
        uint256 fee = percentageOf(interestPaid, _feeManager.feePercentage());

        uint256 unClaimedInterest = (interestPaid - fee);

        _feeManager.credit(loan.principalToken, fee);

        bool completed = _loanManager.repayLoan(
            loanId,
            unClaimedInterest,
            principalAmount,
            collateralAmount
        );

        if (loan.principalToken == nativeAddress) {
            require(msg.value >= repaymentPrincipal);
        } else {
            ERC20(loan.principalToken).safeTransferFrom(
                _msgSender(),
                address(this),
                repaymentPrincipal
            );
        }

        transfer(
            loan.offerId,
            _msgSender(),
            principalAmount.add(unClaimedInterest),
            loan.principalToken,
            Type.ADDED
        );

        uint256 interestPaidInUSD = _priceFeed.amountInUSD(
            loan.principalToken,
            (repaymentPrincipal - principalAmount)
        );

        notify(_msgSender(), loan.lender, REPAID_LOAN, loan.offerId);

        _activity.repayLoan(
            loan.lender,
            _msgSender(),
            interestPaidInUSD,
            completed
        );
    }

    /// @notice This function is use to repay a liquidated loan
    /// @dev Liquidated loans cannot be repaid by percentage
    function repayLiquidatedLoan(uint256 loanId) public payable whenNotPaused {}

    // =========== Cancel / Reject Request Functions =========== //

    /// @notice This function will reject a request
    /// @dev Request can only be rejected by the offer creator
    function rejectRequest(uint256 requestId) public whenNotPaused {
        _offerManager.rejectRequest(requestId, _msgSender());
        RequestLibrary.Request memory request = _offerManager.getRequest(
            requestId
        );
        notify(_msgSender(), request.creator, REJECT_REQUEST, request.offerId);
    }

    /// @notice This function will cancel a request
    /// @dev Request can only be calncelled by the request creator
    function cancelRequest(uint256 requestId) public whenNotPaused {
        RequestLibrary.Request memory request = _offerManager.getRequest(
            requestId
        );

        OfferLibrary.Offer memory offer = _offerManager.getOffer(
            request.offerId
        );

        if (request.requestType == RequestLibrary.Type.LENDING_REQUEST) {
            uint256 principalAmount = percentageOf(
                offer.initialPrincipal,
                request.percentage
            );

            if (offer.principalToken == nativeAddress) {
                payable(_msgSender()).transfer(principalAmount);
            } else {
                ERC20(offer.principalToken).safeTransfer(
                    _msgSender(),
                    principalAmount
                );
            }
        } else {
            if (request.collateralToken == nativeAddress) {
                payable(_msgSender()).transfer(request.collateralAmount);
            } else {
                ERC20(request.collateralToken).safeTransfer(
                    _msgSender(),
                    request.collateralAmount
                );
            }
        }

        _offerManager.cancelRequest(requestId, _msgSender());
    }

    // =========== Claim Functions =========== //

    /// @notice This function is use to claim back unlocked collateral from a loan
    /// @dev Can only be called by the borrower
    function claimCollateral(uint256 loanId) public nonReentrant whenNotPaused {
        (uint256 amount, uint256 offerId, address token) = _loanManager
            .claimCollateral(loanId, _msgSender());

        if (token == nativeAddress) {
            payable(_msgSender()).transfer(amount);
        } else {
            ERC20(token).safeTransfer(_msgSender(), amount);
        }

        transfer(offerId, _msgSender(), amount, token, Type.CLAIMED);
    }

    /// @notice This function is use to claim borrowed loan principal
    /// @dev Can only be called by the borrower
    function claimBorrowedPrincipal(uint256 loanId)
        public
        nonReentrant
        whenNotPaused
    {
        (uint256 amount, uint256 offerId, address token) = _loanManager
            .claimBorrowedPrincipal(loanId, _msgSender());

        if (token == nativeAddress) {
            payable(_msgSender()).transfer(amount);
        } else {
            ERC20(token).safeTransfer(_msgSender(), amount);
        }

        transfer(offerId, _msgSender(), amount, token, Type.CLAIMED);
    }

    /// @notice This function is use to claim back repaid principal + interests from a loan
    /// @dev Can only be called by the lender
    function claimPrincipal(uint256 loanId) public nonReentrant whenNotPaused {
        (uint256 amount, uint256 offerId, address token) = _loanManager
            .claimPrincipal(loanId, _msgSender());

        if (token == nativeAddress) {
            payable(_msgSender()).transfer(amount);
        } else {
            ERC20(token).safeTransfer(_msgSender(), amount);
        }

        transfer(offerId, _msgSender(), amount, token, Type.CLAIMED);
    }

    /// @notice This function is use to claim defaulted loan collateral
    /// @dev Can only be called by the lender
    function claimDefaultCollateral(uint256 loanId)
        public
        nonReentrant
        whenNotPaused
    {
        (uint256 amount, uint256 offerId, address token) = _loanManager
            .claimDefaultCollateral(loanId, _msgSender());

        if (token == nativeAddress) {
            payable(_msgSender()).transfer(amount);
        } else {
            ERC20(token).safeTransfer(_msgSender(), amount);
        }

        transfer(offerId, _msgSender(), amount, token, Type.CLAIMED);
    }

    // =========== Loan Liquidation ============= //

    /// @dev this function will liquidate a loan when it has pass
    /// maturity date + grace days.
    /// It can be call by anyone
    function liquidateLoan(uint256 loanId) public nonReentrant {
        LoanLibrary.Loan memory loan = _loanManager.getLoan(loanId);

        // calculate the duration of the loan
        uint256 time = block.timestamp;
        uint256 ellapsedSecs = (time - loan.startDate);

        uint256 repaymentPrincipal = getFullInterestAmount(
            loan.currentPrincipal,
            ellapsedSecs,
            loan.interestRate
        );

        uint256 repaymentCollateral = _priceFeed.exchangeRate(
            loan.principalToken,
            loan.collateralToken,
            repaymentPrincipal
        );

        uint256 interestInCollateral = _priceFeed.exchangeRate(
            loan.principalToken,
            loan.collateralToken,
            (repaymentPrincipal - loan.currentPrincipal)
        );

        uint256 principalPaid;
        uint256 collateralRetrieved;
        uint256 collateralFee;

        uint256 fee = percentageOf(
            interestInCollateral,
            _feeManager.feePercentage()
        );

        if (loan.currentCollateral >= (repaymentCollateral - fee)) {
            collateralRetrieved = (repaymentCollateral - fee);
            principalPaid = loan.currentPrincipal;

            if (loan.currentCollateral >= repaymentCollateral) {
                collateralFee = fee;
            } else {
                collateralRetrieved = loan.currentCollateral;
                collateralFee = (loan.currentCollateral -
                    (repaymentCollateral - fee));
            }
        } else {
            collateralRetrieved = loan.currentCollateral;

            uint256 collateralInPrincipal = _priceFeed.exchangeRate(
                loan.collateralToken,
                loan.principalToken,
                collateralRetrieved
            );

            principalPaid = collateralInPrincipal;
            collateralFee = 0;
        }

        notify(_msgSender(), loan.borrower, LIQUIDATION, loan.offerId);

        _feeManager.credit(loan.collateralToken, collateralFee);

        _loanManager.liquidateLoan(
            loanId,
            principalPaid,
            collateralRetrieved,
            (collateralRetrieved - collateralFee)
        );
    }

    // ============= ABOUT ============ //

    function getVersion() public pure returns (uint256) {
        return LENDINGPOOL_VERSION;
    }

    // ============= ADMIN FUNCTIONS =============== //

    function setFeeds(
        address ltv_,
        address activity_,
        address priceFeed_
    ) public onlyOwner nonReentrant {
        _ltvRatio = ILoanToValueRatio(ltv_);
        _activity = IActivity(activity_);
        _priceFeed = IPriceFeed(priceFeed_);
    }

    function setManagers(
        address loanManager_,
        address offerManager_,
        address feeManager_
    ) public onlyOwner nonReentrant {
        _loanManager = ILoanManager(loanManager_);
        _offerManager = IOfferManager(offerManager_);
        _feeManager = IFeeManager(feeManager_);
    }

    /// @dev to claim developer revenue
    function claim(
        address token,
        address payable receiver,
        uint256 amount
    ) public onlyOwner nonReentrant {
        require(amount > 0, "ERR_ZERO_AMOUNT");
        _feeManager.debit(token, amount);
        if (token == nativeAddress) {
            receiver.transfer(amount);
        } else {
            ERC20(token).safeTransfer(receiver, amount);
        }
    }
}
