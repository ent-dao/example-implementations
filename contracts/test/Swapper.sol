//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IUniswapV2Router02.sol";

contract Swapper {
    using SafeERC20 for IERC20;

    address public sushiRouterAddress =
        0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    mapping(string => address) public tokenAddresses;

    constructor(string[] memory _tokenSymbols, address[] memory _tokenAddresses)
    {
        uint256 i = 0;
        while (i < _tokenSymbols.length) {
            tokenAddresses[_tokenSymbols[i]] = _tokenAddresses[i];
            i += 1;
        }
    }

    function howMuchETHShouldISendToSwap(address _toToken, uint256 _amount)
        public
        view
        returns (uint256)
    {
        IUniswapV2Router02 routerSushi = IUniswapV2Router02(sushiRouterAddress);

        address[] memory path = new address[](3);
        path[0] = tokenAddresses["WMATIC"];
        path[1] = tokenAddresses["USDC"];
        path[2] = _toToken;

        uint256[] memory amounts = routerSushi.getAmountsIn(_amount, path);
        return amounts[0];
    }

    function swap(address _toToken, uint256 _amount) public payable {
        IUniswapV2Router02 routerSushi = IUniswapV2Router02(sushiRouterAddress);

        address[] memory path = new address[](3);
        path[0] = tokenAddresses["WMATIC"];
        path[1] = tokenAddresses["USDC"];
        path[2] = _toToken;

        uint256[] memory amounts = routerSushi.swapETHForExactTokens{
            value: msg.value
        }(_amount, path, address(this), block.timestamp);

        IERC20(_toToken).transfer(msg.sender, _amount);

        if (msg.value > amounts[0]) {
            uint256 leftoverETH = msg.value - amounts[0];
            (bool success, ) = msg.sender.call{value: leftoverETH}(
                new bytes(0)
            );

            require(success, "Failed to send surplus ETH back to user.");
        }
    }

    fallback() external payable {}

    receive() external payable {}
}
