// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract LendingPoolProvider {
    using Counters for Counters.Counter;
    Counters.Counter private transferIdTracker;

    enum Type {
        ADDED,
        CLAIMED,
        LOCKED,
        REMOVED
    }

    event Transfer(
        uint256 transferId,
        uint256 offerId,
        address from,
        uint256 amount,
        address token,
        Type transferType,
        uint256 timestamp
    );

    function transfer(
        uint256 offerId,
        address from,
        uint256 amount,
        address token,
        Type transferType
    ) public virtual {
        transferIdTracker.increment();
        emit Transfer(
            transferIdTracker.current(),
            offerId,
            from,
            amount,
            token,
            transferType,
            block.timestamp
        );
    }
}
