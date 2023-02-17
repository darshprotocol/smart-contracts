// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/PoolLibrary.sol";
import "../libraries/LoanLibrary.sol";
import "../libraries/OfferLibrary.sol";

import "../interfaces/ILoanManager.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LoanManager is ILoanManager, Ownable2Step {
    uint256 public constant ONE_DAY = 60 * 60 * 24;
    uint256 public constant ONE_HOUR = 60 * 60;

    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private loanIdTracker;
    mapping(uint256 => LoanLibrary.Loan) private loans;

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
        uint256 interest,
        uint16 daysToMaturity,
        address borrower,
        address lender
    ) public onlyLendingPool returns (uint256) {
        // avoid 0 id
        loanIdTracker.increment();
        uint256 loanId = loanIdTracker.current();

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
            interest,
            startDate,
            maturityDate,
            graceDays,
            0, // numInstallmentsPaid
            0, // unclaimed principal
            0, // unclaimed collateral
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
        loan.unClaimedPrincipal += interestPaid;
        loan.unClaimedCollateral += collateralRetrieved;
        loan.currentPrincipal -= principalPaid;
        loan.currentCollateral -= collateralRetrieved;

        if (loan.currentPrincipal <= 10) {
            loan.state = LoanLibrary.State.PAID;
            loan.repaidOn = block.timestamp;
        }

        _emit(loanId, loan);
        return loan.state == LoanLibrary.State.PAID;
    }

    function claimPrincipal(uint256 loanId) public override onlyLendingPool {
        LoanLibrary.Loan storage loan = loans[loanId];
        require(loan.unClaimedPrincipal > 0, "ERR_ZERO_BALANCE");
        loan.unClaimedPrincipal = 0;
    }

    function claimCollateral(uint256 loanId) public override onlyLendingPool {
        LoanLibrary.Loan storage loan = loans[loanId];
        require(loan.unClaimedCollateral > 0, "ERR_ZERO_BALANCE");
        loan.unClaimedCollateral = 0;
    }

    // function liquidateLoan(
    //     uint160 loanId,
    //     uint256 principalTaken,
    //     uint256 collateralTaken
    // ) public override onlyLendingPool returns (bool) {
    //     LoanLibrary.Loan storage loan = loans[loanId];
    //     require(loan.state == LoanLibrary.State.ACTIVE, "ERR_LOAN_NOT_ACTIVE");

    //     uint160 graceDate = loan.graceDays * 1 days;
    //     uint160 defaultDate = loan.maturityDate + graceDate;
    //     uint160 currentDate = uint160(block.timestamp);

    //     require(defaultDate >= currentDate, "ERR_LOAN_NOT_MATURED");

    //     loan.currentPrincipal -= principalTaken;
    //     loan.currentCollateral -= collateralTaken;
    //     loan.state = LoanLibrary.State.LIQUIDATED;

    //     _emit(loanId, loan);
    //     return true;
    // }

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
            loan.interest,
            loan.startDate,
            loan.maturityDate,
            loan.graceDays,
            loan.borrower,
            loan.lender
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
