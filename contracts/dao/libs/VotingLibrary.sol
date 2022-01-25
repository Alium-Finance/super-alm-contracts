// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

library VotingLibrary {
    enum Status {
        EMPTY, // zero state
        INITIALIZED, // created with one sign
        CANCELLED, // canceled by consensus
        QUEUED, // approved and send to timelock
        EXECUTED // executed
    }

    struct Proposal {
        // @dev actual weight
        uint256 weight;
        Status status;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;
        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        /// @notice The ordered list of function signatures to be called
        string[] signatures;
        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        address callFrom;
        string description;
        uint256 initiatedAt;
    }
}
