/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IAliumToken.sol";
import "./GovernmentToken.sol";

contract SuperALM is GovernmentToken {
    using SafeERC20 for IERC20;

    uint256 public constant BASIC_PRICE = 5e18;
    uint256 public constant REWARD = 1e18;

    address public immutable alm;

    uint256 public minted;

    constructor(address _almToken) GovernmentToken("SuperALM", "sALM") {
        require(_almToken != address(0), "Zero address set");

        alm = _almToken;
    }

    function mint(uint256 _amount) external {
        require(_amount != 0, "Zero tokens mint");

        uint256 deposit = countMintPrice(_amount);

        minted += _amount;

        IERC20(alm).safeTransferFrom(msg.sender, address(this), deposit);
        IAliumToken(alm).burn(IERC20(alm).balanceOf(address(this)));

        uint256 reward = _amount * REWARD;
        _mint(msg.sender, reward);
        _moveDelegates(address(0), msg.sender, reward);
    }

    // @dev Destroys `amount` tokens from the caller.
    function burn(uint256 _amount) external {
        _burn(_msgSender(), _amount);
        _moveDelegates(_delegates[_msgSender()], address(0), _amount);
    }

    // @dev An = A1 + (n - 1)·d; where d = A1, An - price
    function countMintPrice(uint256 _amount)
        public
        view
        returns (uint256 price)
    {
        uint256 tokenId = minted;
        uint256 x = BASIC_PRICE;
        for (uint256 i; i < _amount; i++) {
            price += x + tokenId * x;
            tokenId++;
        }
    }
}
