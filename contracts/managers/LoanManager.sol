// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/PoolLibrary.sol";
import "../libraries/LoanLibrary.sol";
import "../libraries/OfferLibrary.sol";

import "../interfaces/ILoanManager.sol";

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LoanManager is ILoanManager, Ownable2Step {
    using Counters for Counters.Counter;

    Counters.Counter private loanIdTracker;
    mapping(uint256 => LoanLibrary.Loan) private loans;

    address lendingPool;

    event LoanCreated(
        uint256 loanId,
        uint160 offerId,
        LoanLibrary.State state,
        address principalToken,
        address collateralToken,
        uint256 initialPrincipal,
        uint256 currentPrincipal,
        uint256 initialCollateral,
        uint256 currentCollateral,
        uint256 interest,
        uint160 startDate,
        uint160 maturityDate,
        address borrower,
        address lender
    );

    constructor() Ownable2Step() {}

    function createLoan(
        uint160 offerId,
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

        uint160 startDate = uint160(block.timestamp);
        uint160 duration = uint160((daysToMaturity * 1 days));
        uint160 maturityDate = startDate + duration;
        uint8 numInstallmentsPaid = 0;

        loans[loanId] = LoanLibrary.Loan(
            offerId,
            LoanLibrary.State.ACTIVE,
            offerType,
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
            numInstallmentsPaid,
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
        uint256 principalPaid,
        uint256 collateralRetrieved
    ) public override onlyLendingPool returns (bool) {
        LoanLibrary.Loan storage loan = loans[loanId];

        require(loan.state == LoanLibrary.State.ACTIVE, "ERR_LOAN_NOT_ACTIVE");

        loan.currentPrincipal -= principalPaid;
        loan.currentCollateral -= collateralRetrieved;
        loan.numInstallmentsPaid += 1;

        if (loan.currentPrincipal == 0) {
            // mark loan as paid
            loan.state = LoanLibrary.State.PAID;
        }

        _emit(loanId, loan);
        return true;
    }

    function liquidateLoan(uint256 loanId)
        public
        override
        onlyLendingPool
        returns (bool)
    {
        LoanLibrary.Loan storage loan = loans[loanId];

        require(loan.state == LoanLibrary.State.ACTIVE, "ERR_LOAN_NOT_ACTIVE");
        loan.state = LoanLibrary.State.LIQUIDATED;

        _emit(loanId, loan);
        return true;
    }

    function _emit(uint256 loanId, LoanLibrary.Loan memory loan) private {
        emit LoanCreated(
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
            loan.borrower,
            loan.lender
        );
    }

    function setLendingPool(address address_) public onlyOwner {
        lendingPool = address_;
    }

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool);
        _;
    }
}
