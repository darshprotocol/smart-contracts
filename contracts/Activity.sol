// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Activity {
    
    struct Model {
        uint repaidNumbers;
        uint borrowedNumbers;
        uint256 borrowedValue;
        uint256 repaidValue;
        uint256 defaultNumbers;
    }

    mapping(address => Model) public models;

    function incrementBorrowed(address user, uint256 amount) external {
        models[user].borrowedNumbers += 1;
        models[user].borrowedValue += amount;
    }

    function incrementRepaid(address user, uint256 amount) external {
        models[user].repaidNumbers += 1;
        models[user].repaidValue += amount;
    }

    function pendingLoans(address user) external view returns(uint) {
        return models[user].borrowedNumbers - models[user].repaidNumbers;
    }

    function isDefaulter(address user) external view returns(bool) {
        return models[user].defaultNumbers > 0;
    }

    function model(address user) external view returns(Model memory) {
        return models[user];
    }

}
