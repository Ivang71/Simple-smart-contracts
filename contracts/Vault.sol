// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC20.sol";

contract Vault {
    error TokenTransferFailedError();
    error ZeroBalanceError(address user);

    event Deposit(address indexed sender, uint amount);
    event Withdraw(address indexed reciever, uint amount);

    ERC20 public immutable token;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    constructor(address _token) {
        token = ERC20(_token);
    }

    function _mint(address _to, uint _amount) private {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
    }

    function _burn(address _from, uint _amount) private {
        totalSupply -= _amount;
        balanceOf[_from] -= _amount;
    }

    function deposit(uint _amount) external {
        /*
        a = amount
        B = balance of token before deposit
        T = total supply
        s = shares to mint

        (T + s) / T = (a + B) / B

        s = aT / B
        */
        uint shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / token.balanceOf(address(this));
        }

        bool ok = token.transferFrom(msg.sender, address(this), _amount);
        if (!ok) revert TokenTransferFailedError();
        
        _mint(msg.sender, shares);

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint _shares) external {
        /*
        a = amount
        B = balance of token before withdraw
        T = total supply
        s = sharet to burn

        (T - s) / T = (B - a) / B

        a = sB / T
        */
        if (balanceOf[msg.sender] == 0) revert ZeroBalanceError(msg.sender);

        uint amount = (_shares * token.balanceOf(address(this))) / totalSupply;
        
        bool ok = token.transfer(msg.sender, amount);
        if (!ok) revert TokenTransferFailedError();
    }
}