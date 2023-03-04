// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/LoanLibrary.sol";
import "../libraries/OfferLibrary.sol";

import "../interfaces/ILoanManager.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LoanManager is ILoanManager, Ownable2Step {
    uint256 public constant ONE_DAY = 60 * 60 * 24;
    uint256 public constant ONE_HOUR = 60 * 60;
    uint256 public DUST_AMOUNT = 100;

    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private loanIdTracker;
    mapping(uint256 => LoanLibrary.Loan) public loans;

    // offerId => wallet addresses
    mapping(uint256 => address[]) private borrowers;

    address lendingPool;
    uint16 graceDays = 5;

    constructor() Ownable2Step() {}

    function createLoan(
        uint256 offerId,
        OfferLibrary.Type offerType,
        address principalToken,
        address collateralToken,
        uint256 principalAmount,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint256 unClaimedBorrowedPrincipal,
        address borrower,
        address lender
    ) public override onlyLendingPool returns (uint256) {
        // avoid 0 id
        loanIdTracker.increment();
        uint256 loanId = loanIdTracker.current();

        require(lender != borrower, "ERR_CANT_BORROW_OWN");

        if (offerType == OfferLibrary.Type.LENDING_OFFER) {
            require(
                !_hasBorrowedFrom(offerId, borrower),
                "ERR_ALREADY_BORROWED"
            );
            borrowers[offerId].push(borrower);
        } else {
            require(!_hasBorrowedFrom(offerId, lender), "ERR_ALREADY_BORROWED");
            borrowers[offerId].push(lender);
        }

        uint256 startDate = block.timestamp;
        uint256 duration = ONE_DAY.mul(daysToMaturity);
        uint256 maturityDate = startDate.add(duration);

        loans[loanId] = LoanLibrary.Loan(
            offerId,
            LoanLibrary.State.ACTIVE,
            principalToken,
            collateralToken,
            principalAmount,
            principalAmount,
            collateralAmount,
            collateralAmount,
            collateralPriceInUSD,
            interestRate,
            startDate,
            maturityDate,
            graceDays,
            0, // numInstallmentsPaid
            0, // unclaimed principal
            0, // unclaimed collateral
            0, // unclaimed default collateral
            unClaimedBorrowedPrincipal,
            0, // total interestRate paid
            0, // repaidOn
            borrower,
            lender
        );

        _emit(loanId, loans[loanId]);
        return loanId;
    }

    function getLoan(uint256 loanId)
        public
        view
        override
        returns (LoanLibrary.Loan memory)
    {
        return loans[loanId];
    }

    function repayLoan(
        uint256 loanId,
        uint256 interestPaid,
        uint256 principalPaid,
        uint256 collateralRetrieved
    ) public override onlyLendingPool returns (bool) {
        LoanLibrary.Loan storage loan = loans[loanId];
        require(loan.state == LoanLibrary.State.ACTIVE, "ERR_LOAN_NOT_ACTIVE");

        loan.numInstallmentsPaid += 1;
        loan.totalInterestPaid += interestPaid;
        loan.unClaimedPrincipal += principalPaid.add(interestPaid);
        loan.unClaimedCollateral += collateralRetrieved;
        loan.currentPrincipal -= principalPaid;
        loan.currentCollateral -= collateralRetrieved;
        loan.repaidOn = block.timestamp;

        if (loan.currentPrincipal <= DUST_AMOUNT) {
            loan.state = LoanLibrary.State.REPAID;
        }

        _emit(loanId, loan);
        return loan.state == LoanLibrary.State.REPAID;
    }

    function claimPrincipal(uint256 loanId, address user)
        public
        override
        onlyLendingPool
        returns (
            uint256,
            uint256,
            address
        )
    {
        LoanLibrary.Loan storage loan = loans[loanId];
        require(loan.lender == user, "ERR_NOT_LENDER");
        require(loan.unClaimedPrincipal > 0, "ERR_ZERO_BALANCE");
        uint256 amount = loan.unClaimedPrincipal;
        loan.unClaimedPrincipal = 0;

        _emit(loanId, loan);
        return (amount, loan.offerId, loan.principalToken);
    }

    function claimDefaultCollateral(uint256 loanId, address user)
        public
        override
        onlyLendingPool
        returns (
            uint256,
            uint256,
            address
        )
    {
        LoanLibrary.Loan storage loan = loans[loanId];
        require(loan.lender == user, "ERR_NOT_LENDER");
        require(loan.unClaimedDefaultCollateral > 0, "ERR_ZERO_BALANCE");
        uint256 amount = loan.unClaimedDefaultCollateral;
        loan.unClaimedDefaultCollateral = 0;

        _emit(loanId, loan);
        return (amount, loan.offerId, loan.collateralToken);
    }

    function claimCollateral(uint256 loanId, address user)
        public
        override
        onlyLendingPool
        returns (
            uint256,
            uint256,
            address
        )
    {
        LoanLibrary.Loan storage loan = loans[loanId];
        require(loan.borrower == user, "ERR_NOT_BORROWER");
        require(loan.unClaimedCollateral > 0, "ERR_ZERO_BALANCE");
        uint256 amount = loan.unClaimedCollateral;
        loan.unClaimedCollateral = 0;

        _emit(loanId, loan);
        return (amount, loan.offerId, loan.collateralToken);
    }

    function claimBorrowedPrincipal(uint256 loanId, address user)
        public
        override
        onlyLendingPool
        returns (
            uint256,
            uint256,
            address
        )
    {
        LoanLibrary.Loan storage loan = loans[loanId];
        require(loan.borrower == user, "ERR_NOT_BORROWER");
        require(loan.unClaimedBorrowedPrincipal > 0, "ERR_ZERO_BALANCE");
        uint256 amount = loan.unClaimedBorrowedPrincipal;
        loan.unClaimedBorrowedPrincipal = 0;

        _emit(loanId, loan);
        return (amount, loan.offerId, loan.principalToken);
    }

    function liquidateLoan(
        uint256 loanId,
        uint256 principalPaid,
        uint256 collateralRetrieved,
        uint256 collateralPaid
    ) public override onlyLendingPool {
        LoanLibrary.Loan storage loan = loans[loanId];
        require(loan.state == LoanLibrary.State.ACTIVE, "ERR_LOAN_NOT_ACTIVE");

        uint256 graceDate = ONE_DAY.mul(loan.graceDays);
        uint256 defaultDate = loan.maturityDate.add(graceDate);
        uint256 currentDate = block.timestamp;

        require(defaultDate >= currentDate, "ERR_LOAN_NOT_MATURED");

        loan.currentPrincipal -= principalPaid;
        loan.currentCollateral -= collateralRetrieved;
        loan.unClaimedDefaultCollateral += collateralPaid;

        if (loan.currentCollateral > 0) {
            loan.unClaimedCollateral = loan.currentCollateral;
            loan.currentCollateral = 0;
        }

        if (loan.currentPrincipal <= 10) {
            loan.state = LoanLibrary.State.REPAID_DEFAULTED;
        } else {
            loan.state = LoanLibrary.State.ACTIVE_DEFAULTED;
        }

        _emit(loanId, loan);
    }

    function _emit(uint256 loanId, LoanLibrary.Loan memory loan) private {
        emit LoanLibrary.LoanCreated(
            loanId,
            loan.offerId,
            loan.state,
            loan.principalToken,
            loan.collateralToken,
            loan.initialPrincipal,
            loan.currentPrincipal,
            loan.initialCollateral,
            loan.currentCollateral,
            loan.interestRate,
            loan.startDate,
            loan.maturityDate,
            loan.graceDays,
            loan.borrower,
            loan.lender
        );
        emit LoanLibrary.LoanCreatedProperty(
            loanId,
            loan.collateralPriceInUSD,
            loan.numInstallmentsPaid,
            loan.unClaimedPrincipal,
            loan.unClaimedCollateral,
            loan.unClaimedDefaultCollateral,
            loan.unClaimedBorrowedPrincipal,
            loan.totalInterestPaid,
            loan.repaidOn
        );
    }

    function _hasBorrowedFrom(uint256 offerId, address user)
        private
        view
        returns (bool)
    {
        for (uint16 index = 0; index < borrowers[offerId].length; index++) {
            if (borrowers[offerId][index] == user) {
                return true;
            }
        }
        return false;
    }

    function setGraceDays(uint16 days_) public onlyOwner {
        graceDays = days_;
    }

    function setLendingPool(address address_) public onlyOwner {
        lendingPool = address_;
    }

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool);
        _;
    }
}
