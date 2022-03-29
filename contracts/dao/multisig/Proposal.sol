// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libs/VotingLibrary.sol";
import "../interfaces/IProposal.sol";

contract Proposal is IProposal, Ownable {
    VotingLibrary.Proposal internal _proposal;

    function set(VotingLibrary.Proposal calldata _details) external override onlyOwner {
        _proposal = _details;
    }

    function setEta(uint256 _value) external override onlyOwner {
        _proposal.eta = _value;
    }

    function setStatus(VotingLibrary.Status _value) external override onlyOwner {
        _proposal.status = _value;
    }

    function get() external view override returns (VotingLibrary.Proposal memory _details) {
        _details = _proposal;
    }
}