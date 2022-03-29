// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Signable {
    uint256 public constant SYSTEM_DECIMAL = 10_000;

    uint256 public timeForSigning = 14 days;
    uint256 public minProposerBalance = 23e18; // ~0.25%
    uint256 public minRequiredWeight = 444e18; // 8888/20 (5% of max total supply)

    IERC20 public governanceToken;

    constructor(IERC20 _govToken) {
        require(address(_govToken) != address(0), "Gov token zero");

        governanceToken = _govToken;
    }

    function canCreateProposal(address _account) public view returns (bool resolved) {
        uint256 balance = governanceToken.balanceOf(_account);
        resolved = !!(balance >= minProposerBalance);
    }

    function setTimeForSigning(uint256 _value) public onlyThis {
        timeForSigning = _value;
    }

    function setMinRequiredWeight(uint256 _value) public onlyThis {
        minRequiredWeight = _value;
    }

    function setMinProposerBalance(uint256 _value) public onlyThis {
        minProposerBalance = _value;
    }

    function requiredWeight() public view returns (uint256 weight) {
        uint256 supply = governanceToken.totalSupply();
        weight = supply / 2;
        if (weight < minRequiredWeight) {
            weight = minRequiredWeight; // 8888/20 (5% of total supply)
        }
    }

    modifier onlySigner() {
        require(governanceToken.balanceOf(msg.sender) != 0, "No permission");
        _;
    }

    modifier onlyThis() {
        require(
            msg.sender == address(this),
            "Call must come from this contract."
        );
        _;
    }
}
