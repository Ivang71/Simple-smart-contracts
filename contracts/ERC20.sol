// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}

 
contract JustAnotherToken is IERC20 {
  string public name;
  string public symbol;
  uint constant public totalSupply = 1e6;  
  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;

  constructor(string memory _name, string memory _symbol) {
    balanceOf[msg.sender] += totalSupply;
    name = _name;
    symbol = _symbol;
  }
    
  function transfer(address recipient, uint amount) external returns (bool) {
    require(balanceOf[msg.sender] >= amount, "not enough tokens");
    balanceOf[msg.sender] -= amount;
    balanceOf[recipient] += amount;
    emit Transfer(recipient, msg.sender, amount);
    return true;
  }
  
  function approve(address spender, uint amount) external returns (bool) {
    allowance[msg.sender][spender] += amount;
    emit Approval(spender, msg.sender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint amount) external returns (bool) {
    require(allowance[sender][msg.sender] >= amount, "not allowed to transfer that much");
    allowance[sender][msg.sender] -= amount;
    balanceOf[sender] -= amount;
    balanceOf[recipient] += amount;
    return true;
  }
}