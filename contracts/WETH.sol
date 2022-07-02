// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract WETH is ERC20 {
    event Deposit(address sender, uint amount);
    event Withdraw(address sender, uint amount);

    constructor() ERC20("Wrapped Ether", "WETH", 18) {}

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) external {
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }
}