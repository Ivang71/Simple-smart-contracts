// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract MultisigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint txId);
    event Revoke(address indexed owner, uint txId);
    event Execute(uint indexed txId);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }
    
    address[] owners;
    mapping(address => bool) isOwner;
    uint required;
    Transaction[] transactions;
    // mapping txId => owner => approve
    mapping(uint => mapping(address => bool)) approved;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint txId) {
        require(txId < transactions.length, "tx does not exists");
        _;
    }

    modifier notApproved(uint txId) {
        require(!approved[txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuted(uint txId) {
        require(!transactions[txId].executed, "tx already executed");
        _;
    }
    
    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <= _owners.length, "invalid required number of owners");

        for (uint i; i < _owners.length; i++) {
            address owner = owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");
            
            owners.push(owner);
            isOwner[owner] = true;
        }
        
        required = _required;
    }
    
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner {
        require(_to != address(0), "invalid address");
        
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        
        emit Submit(transactions.length - 1);
    }

    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function countApprovals(uint _txId) private view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count++;
            }
        }
    }

    function execute(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        uint numberOfApprovals = countApprovals(_txId);
        require(numberOfApprovals >= required, "not enough approvals");

        Transaction storage _tx = transactions[_txId];
        _tx.executed = true;
        (bool success, ) = _tx.to.call{value: _tx.value}(_tx.data);
        require(success, "tx failed");

        emit Execute(_txId);
    }

    function revoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}