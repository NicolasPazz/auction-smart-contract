// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.30;

contract Auction {

    struct Bid {
        address bidder;
        uint256 amount;
    }

    address public owner;
    uint256 public deadline;
    bool public finished;
    Bid public highestBid;
    bool private noReentrancySem;

    mapping(address => uint256[]) public bidsHistory;
    mapping(address => uint256) public totalDeposits;
    Bid[] public allBids;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);

    event AuctionStarted(uint256 deadline);
    event AuctionExtended(uint256 newDeadline);
    event DepositRefunded(address indexed bidder, uint256 amount);
    event DepositPartiallyRefunded(address indexed bidder, uint256 amount);

    modifier auctionActive() {
        require(block.timestamp < deadline && !finished, "Auction finished.");
        _;
    }

    modifier validBid() {
        require(msg.value >= highestBid.amount * 105 / 100, "Bid must be at least 5% higher.");
        _;
    }

    modifier auctionFinished() {
        require(finished, "Auction not finished yet.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You don't have permissions to do this.");
        _;
    }

    modifier noReentrancy() {
        require(!noReentrancySem, "Reentrancy not allowed");
        noReentrancySem = true;
        _;
        noReentrancySem = false;
    }

    modifier notFinalized() {
        require(!finished, "Already finalized");
        _;
    }

    modifier deadlineReached() {
        require(block.timestamp >= deadline, "Auction still active");
        _;
    }

    modifier hasExcess() {
        require(bidsHistory[msg.sender].length > 1, "No excess to withdraw.");
        _;
    }

    modifier hasBids() {
        require(highestBid.amount > 0, "No bids have been placed.");
        _;
    }

    constructor(uint256 durationInMinutes) {
        owner = msg.sender;
        deadline = block.timestamp + (durationInMinutes * 1 minutes);
        finished = false;
        noReentrancySem = false;
        emit AuctionStarted(deadline);
    }

    function placeBid() external payable auctionActive validBid {
        if (block.timestamp >= deadline - 10 minutes) {
            deadline += 10 minutes;
            emit AuctionExtended(deadline);
        }

        bidsHistory[msg.sender].push(msg.value);
        totalDeposits[msg.sender] += msg.value;
        allBids.push(Bid(msg.sender, msg.value));

        highestBid = Bid(msg.sender, msg.value);

        emit NewBid(msg.sender, msg.value);
    }

    function getWinner() public view auctionFinished hasBids returns (address, uint256) {
        return (highestBid.bidder, highestBid.amount);
    }

    function getAllBids() public view hasBids returns (Bid[] memory) {
        return allBids;
    }

    function endAuction() external onlyOwner noReentrancy notFinalized deadlineReached {
        finished = true;
        emit AuctionEnded(highestBid.bidder, highestBid.amount);

        for (uint256 i = 0; i < allBids.length; i++) {
            address bidder = allBids[i].bidder;
            if (bidder != highestBid.bidder && totalDeposits[bidder] > 0) {
                uint256 refundAmount = totalDeposits[bidder] * 98 / 100;
                totalDeposits[bidder] = 0;
                payable(bidder).transfer(refundAmount);
                emit DepositRefunded(bidder, refundAmount);
            }
        }

        if (highestBid.amount > 0) {
            payable(owner).transfer(highestBid.amount);
        }
    }

    function withdrawExcess() external auctionActive noReentrancy hasExcess hasBids {
        uint256[] memory userBids = bidsHistory[msg.sender];
        uint256 lastValidUserBid  = userBids[userBids.length - 1];
        uint256 total = totalDeposits[msg.sender];
        uint256 excess = total - lastValidUserBid;

        totalDeposits[msg.sender] = lastValidUserBid;
        delete bidsHistory[msg.sender];
        bidsHistory[msg.sender].push(lastValidUserBid);

        uint256 refundAmount = excess * 98 / 100;
        payable(msg.sender).transfer(refundAmount);
        emit DepositPartiallyRefunded(msg.sender, refundAmount);
    }
}