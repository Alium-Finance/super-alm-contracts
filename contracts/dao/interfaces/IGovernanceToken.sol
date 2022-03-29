// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IGovernanceToken {
    function getCurrentVotes(address account) external view returns (uint256);
}