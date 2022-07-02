// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

// The contract to delay execution of the functions of other contracts 
// to increase security and reduce owner's control
contract Timelock {
    error NotOwnerError();
    error AlreadyEnqueueError(bytes32 txId);
    error TimestampNotInRangeError(uint blockTimestamp, uint timestamp);
    error NotQueuedError(bytes32 txId);
    error ExpiredError(bytes32 txId);
    error TxFailedError(bytes32 txId);

    event Queued(
        address target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );

    event Execute(
        address target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    
    event Cancel(bytes32 txId);

    address owner;
    mapping(bytes32 => bool) public queued;
    
    uint constant MIN_DELAY = 3 days;
    uint constant MAX_DELAY = 30 days;
    uint constant EXPIRATION_PERIOD = 10 days;
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerError();
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() external payable {}

    function getTxId(
        address target,
        uint value,
        string calldata func,
        bytes calldata data,
        uint timestamp
    ) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                target, value, func, data, timestamp
            )
        );
    }

    function queue(
        address target,
        uint value,
        string calldata func,
        bytes calldata data,
        uint timestamp
    ) external onlyOwner {
        bytes32 txId = getTxId(target, value, func, data, timestamp);

        if (queued[txId]) revert AlreadyEnqueueError(txId);
        if (
            timestamp < block.timestamp + MIN_DELAY ||
            timestamp > block.timestamp + MAX_DELAY
        ) revert TimestampNotInRangeError(block.timestamp, timestamp);
        
        queued[txId] = true;

        emit Queued(target, value, func, data, timestamp);
    }

    function execute(
        address target,
        uint value,
        string calldata func,
        bytes calldata data,
        uint timestamp
    ) external onlyOwner returns (bytes memory) {
        bytes32 txId = getTxId(target, value, func, data, timestamp);

        if (!queued[txId]) revert NotQueuedError(txId);
        if (block.timestamp > timestamp + EXPIRATION_PERIOD) revert ExpiredError(txId);
        
        queued[txId] = false;

        bytes memory _data;
        if (bytes(func).length > 0) {
            _data = abi.encodePacked(
                bytes4(keccak256(bytes(func))), data
            );
        } else {
            _data = data;
        }

        (bool ok, bytes memory result) = target.call{value: value}(_data);

        if (!ok) revert TxFailedError(txId);
        
        emit Execute(target, value, func, data, timestamp);

        return result;
    }

    function cancel(
        address target,
        uint value,
        string calldata func,
        bytes calldata data,
        uint timestamp
    ) external onlyOwner {
        bytes32 txId = getTxId(target, value, func, data, timestamp);

        if (!queued[txId]) revert NotQueuedError(txId);
        
        queued[txId] = false;

        emit Cancel(txId);
    }
}