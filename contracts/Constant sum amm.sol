// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC20.sol";

contract CSAMM {
    error InvalidTokenError();

    IERC20 public immutable token0;
    IERC20 public immutable token1;
    
    uint reserve0;
    uint reserve1;
    
    uint totalSupply;
    mapping(address => uint) balanceOf;

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function _mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    function update(uint _reserve0, uint _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function swap(address _tokenIn, uint _amount) external returns (uint amountOut) {
        if (
            _tokenIn != address(token0) &&
            _tokenIn != address(token1)
        ) revert InvalidTokenError();

        bool isToken0 = _tokenIn == address(token0);
        (IERC20 tokenIn, IERC20 tokenOut, uint resIn, uint resOut) = isToken0
            ? (token0, token1, reserve0, reserve1) 
            : (token1, token0, reserve1, reserve0);
        
        tokenIn.transferFrom(msg.sender, address(this), _amount);
        
        uint amountIn = tokenIn.balanceOf(address(this)) - resIn;
        // 0.3% fee
        amountOut = (amountIn * 997) / 1000;

        (uint res0, uint res1) = isToken0
            ? (resIn + amountIn, resOut - amountOut)
            : (resOut - amountOut, resIn + amountIn);

        update(res0, res1);
        tokenOut.transfer(msg.sender, _amount);
    }
    // addLiquidity
    // removeLiquidity
}