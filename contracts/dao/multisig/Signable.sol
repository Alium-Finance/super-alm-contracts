// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { IERC721, IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Signable {
    uint256 public constant SYSTEM_DECIMAL = 10_000;

    uint256 public timeForSigning = 14 days;
    uint256 public minProposerBalance = 23; // ~0.25%
    uint256 public minRequiredWeight = 444; // 8888/20 (5% of max total supply)

    address public governanceToken;

    constructor(address _govToken) {
        require(_govToken != address(0), "Gov token zero");

        governanceToken = _govToken;
    }

    function canCreateProposal(address _account) public view returns (bool resolved) {
        uint256 balance = IERC721(governanceToken).balanceOf(_account);
        resolved = !!(balance >= minProposerBalance);
    }

    // @dev should be called if it is possible as second method in batch transaction
    // on add/remove call.
    function setMinRequiredWeight(uint256 _value) public onlyThis {
        minRequiredWeight = _value;
    }

    function requiredWeight() public view returns (uint256 weight) {
        uint256 supply = IERC721Enumerable(governanceToken).totalSupply();
        weight = supply / 2;
        if (weight < minRequiredWeight) {
            weight = minRequiredWeight; // 8888/20 (5% of total supply)
        }
    }

    modifier onlySigner() {
        require(IERC721(governanceToken).balanceOf(msg.sender) != 0, "No permission");
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
