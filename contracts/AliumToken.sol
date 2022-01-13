/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// AliumToken - deflationary, upgradeable token.
contract AliumToken is ERC20("AliumToken", "ALM"), Ownable {
    // @dev Destroys `amount` tokens from the caller.
    function burn(uint256 _amount) public {
        _burn(_msgSender(), _amount);
    }

    /// @dev Creates `_amount` token to `_to`.
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
