/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    IUniswapV2Router01,
    IUniswapV2Router02
} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FeeRedistributor is Ownable {
    using SafeERC20 for IERC20;

    enum Mode {
        TRANSFER,
        SWAP_AND_TRANSFER
    }

    struct SwapInfo {
        address router;
        address alium;
        bool deflationary;
    }

    struct Recipient {
        address account;
        uint256 share;
        Mode mode;
    }

    Recipient[] public recipients;
    SwapInfo public swapInfo;

    address public immutable WETH;
    uint256 public totalShares;

    uint256 public errorsCounter;
    event ErrorHandled(string);

    constructor(SwapInfo memory _swapInfo, Recipient[] memory _recipients) {
        require(_recipients.length <= 10 && _recipients.length != 0, "Wrong constructor arguments set");

        swapInfo = _swapInfo;

        WETH = IUniswapV2Router01(swapInfo.router).WETH();

        for (uint i; i < _recipients.length; i++) {
            recipients[i] = _recipients[i];
            totalShares += _recipients[i].share;
        }
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function release() external {
        uint256 balance = IERC20(swapInfo.alium).balanceOf(address(this));
        uint256 reward;
        for (uint i; i < recipients.length; i++) {
            reward = recipients[i].share * balance / totalShares;
            if (recipients[i].mode == Mode.TRANSFER) {
                IERC20(swapInfo.alium).safeTransfer(recipients[i].account, reward);
            }
            if (recipients[i].mode == Mode.SWAP_AND_TRANSFER) {
                address[] memory path;
                path[0] = swapInfo.alium;
                path[1] = WETH;
                if (swapInfo.deflationary) {
                    try IUniswapV2Router02(swapInfo.router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                        reward,
                        0,
                        path,
                        recipients[i].account,
                        block.timestamp + 15 * 60
                    ) returns (uint256[] memory amounts) {
                        Address.sendValue(payable(recipients[i].account), amounts[amounts.length - 1]);
                    } catch Error(string memory reason) {
                        errorsCounter++;
                        emit ErrorHandled(reason);
                    }
                } else {
                    try IUniswapV2Router01(swapInfo.router).swapExactTokensForETH(
                        reward,
                        0,
                        path,
                        recipients[i].account,
                        block.timestamp + 15 * 60
                    ) returns (uint256[] memory amounts) {
                        Address.sendValue(payable(recipients[i].account), amounts[amounts.length - 1]);
                    } catch Error(string memory reason) {
                        errorsCounter++;
                        emit ErrorHandled(reason);
                    }
                }

            }
        }
    }

    function withdraw(address payable _to) external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(_to, balance);
    }

    function withdrawToken(address _token, address _to) external onlyOwner {
        require(_token != swapInfo.alium, "Unresolved token");

        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_to, balance);
    }
}