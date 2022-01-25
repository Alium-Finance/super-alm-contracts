// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../libs/VotingLibrary.sol";

interface IProposal {
    function set(VotingLibrary.Proposal calldata _details) external;

    function setEta(uint256 _value) external;

    function setStatus(VotingLibrary.Status _value) external;

    function get() external view returns (VotingLibrary.Proposal memory _details);
}