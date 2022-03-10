// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Signable.sol";
import "./Proposal.sol";
import "../interfaces/ITimelock.sol";
import "../interfaces/IGovernanceToken.sol";
import "../interfaces/IProposal.sol";
import "../libs/TimelockLibrary.sol";
import "../libs/VotingLibrary.sol";

contract Multisig is Signable {
    using VotingLibrary for *;

    mapping(uint256 => address) public proposals;
    mapping(address => mapping(uint256 => bool)) public votedBy;

    /// @notice The total number of proposals
    uint256 public proposalTrackerId;

    address public timelock;

    event ProposalInitialized(uint256 id, address proposer);
    event Signed(uint256 id, address signer);
    event Executed(uint256 id);
    event Cancelled(uint256 id);

    constructor(address _timelock, IERC20 _govToken) Signable(_govToken) {
        require(_timelock != address(0), "Timelock zero");

        timelock = _timelock;
    }

    function create(
        address[] calldata targets,
        uint256[] calldata values,
        string[] calldata signatures,
        bytes[] calldata calldatas,
        string calldata description,
        address callFrom // Pass SAFE STORAGE address if want interact with it
    ) external anyProposalCreator {
        require(
            targets.length == values.length &&
            targets.length == signatures.length &&
            targets.length == calldatas.length,
            "Wrong arrays length"
        );

        VotingLibrary.Proposal memory proposal;
        proposal.targets = targets;
        proposal.values = values;
        proposal.signatures = signatures;
        proposal.calldatas = calldatas;
        proposal.description = description;
        proposal.proposer = msg.sender;
        proposal.callFrom = callFrom;
        proposal.initiatedAt = block.timestamp;

        uint256 proposalId = proposalTrackerId;
        proposals[proposalId] = address(new Proposal());
        IProposal(proposals[proposalId]).set(proposal);

        proposalTrackerId++;

        emit ProposalInitialized(proposalId, msg.sender);
    }

    function sign(uint256 _proposalId) external onlySigner {
        require(getStatus(_proposalId) == VotingLibrary.Status.INITIALIZED, "Wrong status");
        require(!votedBy[msg.sender][_proposalId], "Already signed");

        votedBy[msg.sender][_proposalId] = true;

        if (
            IGovernanceToken(address(governanceToken)).getCurrentVotes(proposals[_proposalId]) ==
            requiredWeight()
        ) {
            IProposal(proposals[_proposalId]).setStatus(VotingLibrary.Status.QUEUED);
            IProposal(proposals[_proposalId]).setEta(ITimelock(timelock).delay() + block.timestamp);

            VotingLibrary.Proposal memory proposal = IProposal(proposals[_proposalId]).get();

            TimelockLibrary.Transaction memory txn;
            for (uint256 i; i < proposal.targets.length; i++) {
                txn.target = proposal.targets[i];
                txn.value = proposal.values[i];
                txn.signature = proposal.signatures[i];
                txn.data = proposal.calldatas[i];
                txn.eta = proposal.eta;
                txn.hash = keccak256(
                    abi.encode(
                        _proposalId,
                        i,
                        txn.target,
                        txn.value,
                        txn.signature,
                        txn.data,
                        txn.eta
                    )
                );
                txn.callFrom = proposal.callFrom;

                ITimelock(timelock).queueTransaction(txn);
            }
        }

        emit Signed(_proposalId, msg.sender);
    }

    // _paidFromStorage - if call withdraw or ether should be paid from storage contract
    function execute(uint256 _proposalId, bool _paidFromStorage)
        public
        payable
        onlySigner
    {
        if (_paidFromStorage) {
            require(msg.value == 0, "Pay from storage");
        }

        require(getStatus(_proposalId) == VotingLibrary.Status.QUEUED, "Wrong status");

        VotingLibrary.Proposal memory proposal = IProposal(proposals[_proposalId]).get();
        IProposal(proposals[_proposalId]).setStatus(VotingLibrary.Status.EXECUTED);

        TimelockLibrary.Transaction memory txn;
        for (uint256 i; i < proposal.targets.length; i++) {
            txn.target = proposal.targets[i];
            txn.value = proposal.values[i];
            txn.signature = proposal.signatures[i];
            txn.data = proposal.calldatas[i];
            txn.eta = proposal.eta;
            txn.hash = keccak256(
                abi.encode(
                    _proposalId,
                    i,
                    txn.target,
                    txn.value,
                    txn.signature,
                    txn.data,
                    txn.eta
                )
            );
            txn.callFrom = proposal.callFrom;

            ITimelock(timelock).executeTransaction{
                value: (_paidFromStorage) ? 0 : txn.value
            }(txn);
        }

        emit Executed(_proposalId);
    }

    function cancel(uint256 _proposalId) external {
        VotingLibrary.Status status = getStatus(_proposalId);

        require(
            status == VotingLibrary.Status.INITIALIZED || status == VotingLibrary.Status.QUEUED,
            "Wrong status"
        );

        VotingLibrary.Proposal memory proposal = IProposal(proposals[_proposalId]).get();

        require(msg.sender == proposal.proposer, "Only proposer access");

        IProposal(proposals[_proposalId]).setStatus(VotingLibrary.Status.CANCELLED);

        TimelockLibrary.Transaction memory txn;
        for (uint256 i; i < proposal.targets.length; i++) {
            txn.target = proposal.targets[i];
            txn.value = proposal.values[i];
            txn.signature = proposal.signatures[i];
            txn.data = proposal.calldatas[i];
            txn.eta = proposal.eta;
            txn.hash = keccak256(
                abi.encode(
                    _proposalId,
                    i,
                    txn.target,
                    txn.value,
                    txn.signature,
                    txn.data,
                    txn.eta
                )
            );
            txn.callFrom = proposal.callFrom;

            ITimelock(timelock).cancelTransaction(txn);
        }

        emit Cancelled(_proposalId);
    }

    function getActions(uint256 _proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        VotingLibrary.Proposal memory p = IProposal(proposals[_proposalId]).get();
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getStatus(uint256 _proposalId) public view returns (VotingLibrary.Status) {
        VotingLibrary.Proposal memory p = IProposal(proposals[_proposalId]).get();
        uint256 weight = IGovernanceToken(address(governanceToken)).getCurrentVotes(proposals[_proposalId]);

        if (p.status == VotingLibrary.Status.CANCELLED) {
            return VotingLibrary.Status.CANCELLED;
        }
        if (p.status == VotingLibrary.Status.EXECUTED) {
            return VotingLibrary.Status.EXECUTED;
        }
        if (weight > 0) {
            if (p.eta != 0) {
                if (p.eta + TimelockLibrary.GRACE_PERIOD <= block.timestamp) {
                    return VotingLibrary.Status.CANCELLED;
                }
            } else {
                if (p.initiatedAt + timeForSigning < block.timestamp) {
                    return VotingLibrary.Status.CANCELLED;
                }
            }

            if (weight >= requiredWeight()) {
                return VotingLibrary.Status.QUEUED;
            }

            return VotingLibrary.Status.INITIALIZED;
        }

        return VotingLibrary.Status.EMPTY;
    }

    // @dev method should be called only from timelock contract.
    // Use this one for changes admin data.
    function adminCall(bytes memory data) public {
        require(msg.sender == timelock, "Only timelock");

        (bool success, ) = address(this).call(data);

        require(success, "admin call failed");
    }

    modifier anyProposalCreator() {
        require(canCreateProposal(msg.sender), "No permission");
        _;
    }
}
