pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SuperALM is ERC20("SuperALM", "sALM"), Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant BASIC_PRICE = 5e18;
    uint256 public constant REWARD = 1e18;

    address public immutable alm;
    address public bank;

    uint256 public minted;

    constructor(address _almToken, address _bank) {
        require(
            _almToken != address(0) && _bank != address(0),
            "Zero address set"
        );

        alm = _almToken;
        bank = _bank;
    }

    function mint(uint256 _amount) external {
        require(_amount != 0, "Zero tokens mint");

        uint256 deposit = countMintPrice(_amount);

        minted += _amount;

        IERC20(alm).safeTransferFrom(msg.sender, bank, deposit);
        _mint(msg.sender, _amount * REWARD);
    }

    // @dev An = A1 + (n - 1)·d; where d = A1, An - price
    function countMintPrice(uint256 _amount) public view returns (uint256 price) {
        uint256 tokenId = minted;
        uint256 x = BASIC_PRICE;
        for (uint256 i; i < _amount; i++) {
            price += x + tokenId * x;
            tokenId++;
        }
    }

    function setBank(address _bank) external onlyOwner {
        require(_bank != address(0), "Zero address set");

        bank = _bank;
    }
}