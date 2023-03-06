// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract LendingPoolProvider {
    using Counters for Counters.Counter;
    Counters.Counter private transferIdTracker;

    uint256 public constant ACCEPT_REQUEST = 100;
    uint256 public constant REJECT_REQUEST = 101;
    uint256 public constant EXPIRE_REQUEST = 102;
    uint256 public constant REPAID_LOAN = 103;
    uint256 public constant LIQUIDATION = 104;

    enum Type {
        ADDED,
        CLAIMED,
        LOCKED,
        REMOVED
    }

    event Notify(
        uint256 id,
        uint256 timestamp,
        address from,
        address to,
        uint256 fieldId
    );

    function notify(
        address from,
        address to,
        uint256 notification,
        uint256 fieldId
    ) public virtual {
        emit Notify(notification, block.timestamp, from, to, fieldId);
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
