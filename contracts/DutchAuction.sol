// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC721 {
    function transferFrom(address _from, address _to, uint _nftId) external;
}

contract DutchAuction {
    uint private constant DURATION = 7 days;

    IERC721 public immutable nft;
    uint public immutable nftId;

    address payable public immutable seller;
    uint public immutable startingPrice;
    uint public immutable startedAt;
    uint public immutable expiresAt;
    uint public immutable discountRate;

    constructor(uint _startingPrice, uint _discountRate, address _nft, uint _nftId) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startedAt = block.timestamp;
        expiresAt = block.timestamp + DURATION;

        require(startingPrice >= discountRate * DURATION, "starting price < discount");

        nft = IERC721(_nft);
        nftId = _nftId;
    }
    
    function getPrice() public view returns (uint) {
        uint timeElapsed = block.timestamp - startedAt;
        return startingPrice - discountRate * timeElapsed;
    }

    function buy() external payable {
        require(block.timestamp < expiresAt, "auction expired");

        uint price = getPrice();
        require(msg.value >= price, "not enough ether to buy");
        
        nft.transferFrom(seller, msg.sender, nftId);
        if (price < msg.value) {
            uint refund = price - msg.value;
            payable(msg.sender).call{value: refund}("");
        }
        selfdestruct(seller);
    }
}