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

    function _update(uint _reserve0, uint _reserve1) private {
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

    function addLiquidity(uint amount0, uint amount1) external returns (uint shares) {
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        bal0 = token0.balanceOf(address(this));
        bal1 = token1.balanceOf(address(this));
        
        d0 = bal0 - reserve0;
        d1 = bal1 - reserve1;

        if (totalSupply == 0) {
            shares = bal0 + bal1;
        } else {
            shares = ((d0 + d1) * totalSupply) / (reserve0 + reserve1);
        }
        
        require(shares > 0, "shares = 0");
        _mint(msg.sender, shares);
        _update(bal0, bal1);
    }
    
    function removeLiquidity(uint _shares) external returns (uint d0, uint d1) {
        d0 = (reserve0 * _shares) / totalSupply;
        d1 = (reserve0 * _shares) / totalSupply;

        _burn(msg.sender, amount);
        _update(reserve0 - d0, reserve1 - d1);

        if (d0 > 0) {
            token0.transfer(msg.sender, d0);
        }
        if (d1 > 0) {
            token1.transfer(msg.sender, d1);
        }
    }
}