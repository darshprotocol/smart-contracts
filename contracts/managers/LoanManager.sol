// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/AssetLibrary.sol";
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
        uint256 offerId,    
        LoanLibrary.State state,
        address principalType,    
        address collateralType,
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

    event LoanRepaid(
        uint256 offerId,
        uint256 amountPaid,
        uint256 collateralRetrieved
    );

    constructor() Ownable2Step() {}

    function createLoan(
        uint256 offerId,
        OfferLibrary.Type offerType,
        address principalType,
        address collateralType,
        uint256 principal,
        uint256 collateral,
        uint256 interest,
        uint256 daysToMaturity,
        address borrower,
        address lender
    ) public onlyLendingPool returns (uint256) {
        // avoid 0 id
        loanIdTracker.increment();
        uint256 loanId = loanIdTracker.current();

        uint160 startDate = uint160(block.timestamp);
        uint160 duration = uint160((daysToMaturity * 1 days));
        uint160 maturityDate = startDate + duration;
        uint256 numInstallmentsPaid = 0;

        loans[loanId] = LoanLibrary.Loan(
            offerId,
            LoanLibrary.State.ACTIVE,
            offerType,
            principalType,
            collateralType,
            principal,
            principal,
            collateral,
            collateral,
            interest,
            startDate,
            maturityDate,
            numInstallmentsPaid,
            borrower,
            lender
        );

        emit LoanCreated(
            loanId,
            offerId,
            LoanLibrary.State.ACTIVE,
            principalType,
            collateralType,
            principal,
            principal,
            collateral,
            collateral,
            interest,
            startDate,
            maturityDate,
            borrower,
            lender
        );

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

    function repayLoanAll(uint256 loanId)
        public
        override
        onlyLendingPool
        returns (bool)
    {
        loans[loanId].currentPrincipal = 0;
        loans[loanId].currentCollateral = 0;
        loans[loanId].state = LoanLibrary.State.PAID;
        return true;
    }

    function repayLoanInstallment(
        uint256 loanId,
        uint256 principalPaid,
        uint256 collateralRetrieved
    ) public override onlyLendingPool returns (bool) {
        if (loans[loanId].state != LoanLibrary.State.ACTIVE) return false;

        if (principalPaid >= loans[loanId].currentPrincipal) {
            repayLoanAll(loanId);
        } else {
            loans[loanId].currentPrincipal -= principalPaid;
            loans[loanId].currentCollateral -= collateralRetrieved;
            loans[loanId].numInstallmentsPaid += 1;
        }

        emit LoanRepaid(loanId, principalPaid, collateralRetrieved);
        return true;
    }

    function liquidateLoan(uint256 loanId)
        public
        override
        onlyLendingPool
        returns (bool)
    {
        loans[loanId].state = LoanLibrary.State.LIQUIDATED;
        return true;
    }

    function setLendingPool(address address_) public onlyOwner {
        lendingPool = address_;
    }

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool);
        _;
    }
}
