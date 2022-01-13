/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAliumToken is IERC20 {
    // @dev Destroys `amount` tokens from the caller.
    function burn(uint256 _amount) external;

    /// @dev Creates `_amount` token to `_to`.
    function mint(address _to, uint256 _amount) external;
}
