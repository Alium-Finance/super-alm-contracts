/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// AliumToken - deflationary, upgradeable token.
contract AliumToken is ERC20, Ownable {
    uint256 public constant SYSTEM_DECIMAL = 10_000;

    address public devFeeTo;
    uint256 public devFee;
    uint256 public burnFee;

    constructor(address _dev) ERC20("AliumToken", "ALM") {
        devFeeTo = _dev;
        devFee = 500; // 5%
        burnFee = 500; // 5%
    }

    // @dev Destroys `amount` tokens from the caller.
    function burn(uint256 _amount) public {
        _burn(_msgSender(), _amount);
    }

    /// @dev Creates `_amount` token to `_to`.
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    // _percent depended on SYSTEM_DECIMAL
    function setBurnFee(uint256 _percent) external onlyOwner {
        require(_percent + devFee <= SYSTEM_DECIMAL / 2, "SYSTEM_DECIMAL overset");

        burnFee = _percent;
        emit BurnFeeChanged(_percent);
    }

    function setDevFee(uint256 _percent) external onlyOwner {
        require(_percent + burnFee <= SYSTEM_DECIMAL / 2, "SYSTEM_DECIMAL overset");

        devFee = _percent;
        emit DevFeeChanged(_percent);
    }

    function setDevFeeTo(address _feeTo) external onlyOwner {
        require(address(0) != _feeTo, "ZERO_ADDRESS");

        devFeeTo = _feeTo;
        emit DevFeeToChanged(_feeTo);
    }

    function disableAllFees() external onlyOwner {
        devFee = 0;
        burnFee = 0;

        emit DevFeeChanged(0);
        emit BurnFeeChanged(0);
    }

    function transfer(address _recipient, uint256 _amount)
        public
        override(ERC20)
        returns (bool)
    {
        uint256 burned = _excludeFee(_amount, burnFee);
        uint256 toDev = _excludeFee(_amount, devFee);
        if (burned > 0) {
            _burn(_msgSender(), burned);
        }
        if (toDev > 0) {
            _transfer(_msgSender(), devFeeTo, toDev);
        }

        _transfer(_msgSender(), _recipient, (_amount - burned) - toDev);

        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override(ERC20) returns (bool) {
        uint256 burned = _excludeFee(_amount, burnFee);
        uint256 toDev = _excludeFee(_amount, devFee);
        if (burned > 0) {
            _burn(_sender, burned);
        }
        if (toDev > 0) {
            _transfer(_sender, devFeeTo, toDev);
        }

        _transfer(_sender, _recipient, (_amount - burned) - toDev);

        uint256 currentAllowance = allowance(_sender, _msgSender());

        require(
            currentAllowance >= _amount,
            "ERC20: transfer amount exceeds allowance"
        );

        _approve(_sender, _msgSender(), currentAllowance - _amount);

        return true;
    }

    function _excludeFee(uint256 _amount, uint256 _fee)
        internal
        pure
        returns (uint256 excluded)
    {
        excluded = (_amount * _fee) / SYSTEM_DECIMAL;
    }
}
