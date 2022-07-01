// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC20.sol";

contract CrowdFund {
    event Launch(uint id, address indexed creator, uint goal, uint32 startAt, uint32 endAt);
    event Cancel(uint id);
    event Pledge(uint id, address indexed sender, uint amount);
    event Unpledge(uint id, address indexed reciever, uint amount);
    event Claim(uint id, uint pledged);
    event Refund(uint id, address indexed reciever);

    struct Campaign {
        address creator;
        uint pledged;
        uint goal;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }
    
    IERC20 public immutable token;
    Campaign[] public campaigns;
    // campaignId => userAddress => amount
    mapping(uint => mapping(address => uint)) public pledgedAmount;
    
    modifier onlyCreator(uint campaignId) {
        require(campaigns[campaignId].creator == msg.sender, "not creator");
        _;
    }
    
    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function launch(uint _goal, uint32 _startAt, uint32 _endAt) external {
        require(_startAt > block.timestamp, "cannot start campaign in the past");
        require(_endAt > _startAt, "end is before the start");
        require(_endAt - _startAt >= 90 days, "campaign is too long");

        campaigns.push(Campaign({
            creator: msg.sender,
            pledged: 0,
            goal: _goal,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        }));
        
        emit Launch(campaigns.length - 1, msg.sender, _goal, _startAt, _endAt);
    }

    function cancel(uint _id) external onlyCreator(_id) {
        require(campaigns[_id].startAt < block.timestamp, "already started");
        
        delete campaigns[_id];
        emit Cancel(_id);
    }

    function pledge(uint _id, uint _amount) external {
        Campaign memory campaign = campaigns[_id];
        require(campaign.startAt >= block.timestamp, "not started");
        require(campaign.endAt < block.timestamp, "already ended");

        pledgedAmount[_id][msg.sender] += _amount;
        campaign.pledged += _amount;

        token.transferFrom(msg.sender, address(this), _amount);
        emit Pledge(_id, msg.sender, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        require(campaigns[_id].endAt < block.timestamp, "ended");
        require(pledgedAmount[_id][msg.sender] > 0, "nothing to unpledge");

        pledgedAmount[_id][msg.sender] -= _amount;
        campaigns[_id].pledged -= _amount;
        
        token.transfer(msg.sender, _amount);
        emit Unpledge(_id, msg.sender, _amount);     
    }

    function claim(uint _id) external onlyCreator(_id) {
        Campaign storage campaign = campaigns[_id];
        require(!campaign.claimed, "claimed");
        require(campaign.endAt > block.timestamp, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");

        campaign.claimed = true;

        token.transfer(campaign.creator, campaign.pledged);
        emit Claim(_id, campaign.pledged);
    }

    function refund(uint _id) external {
        require(campaigns[_id].endAt > block.timestamp, "not ended");
        require(campaigns[_id].pledged < campaigns[_id].goal, "goal reached");

        uint amount = pledgedAmount[_id][msg.sender];
        pledgedAmount[_ix][msg.sender] = 0;
        
        token.transfer(msg.sender, amount);
        emit Refund(_id, msg.sender);
    }
}