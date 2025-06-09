# 🛒 Auction Smart Contract

This smart contract implements a secure and transparent auction system on the Ethereum blockchain. It allows multiple participants to place bids in ETH, with automatic validation rules (minimum +5% increment) and secure fund handling, including **partial refunds**, **deadline extension**, and **final settlement**.

Deployed by: [`0x183be2B201923C59802a28FF1c85f21Cebcff855`](https://sepolia.etherscan.io/address/0x183be2B201923C59802a28FF1c85f21Cebcff855)  
📄 Verified Contract: [`0x2820c61cafcc3f83a760b4ecdd0e77ba01fcb28a`](https://sepolia.etherscan.io/address/0x2820c61cafcc3f83a760b4ecdd0e77ba01fcb28a#code)

---

## ⚙️ Features

### 📦 Constructor
Initializes the auction with a custom duration (in minutes). The deadline is computed from `block.timestamp`.

### 🏷️ Bidding
Allows users to place a bid only if:
- The auction is still active (`!finished && now < deadline`)
- The bid is **at least 5% higher** than the current highest bid
- If placed within the last 10 minutes, the deadline is **extended by 10 minutes**

### 🥇 Get Winner
Returns the winner’s address and their final bid amount — accessible only once the auction is finished and at least one bid exists.

### 📜 View All Bids
Returns the list of all bids and their associated addresses.

### 💸 Refund Deposits
When the auction ends:
- All **non-winning bidders** get their deposited ETH refunded (minus 2% fee)
- The owner receives **98% of the winning bid**

### 💰 Deposit Management
- All bids are **deposited into the contract**
- Funds are **tracked per user** using a mapping

---

## 🚀 Advanced Feature: Partial Refunds

### 🔁 Partial Refund
At any time during the auction, a participant may withdraw the **excess amount over their last valid bid**.

---

## 🔣 Functions

| Function            | Description |
|---------------------|-------------|
| `placeBid()`        | Places a new valid bid and stores it in the contract. |
| `withdrawExcess()`  | Refunds the difference between the user’s total deposits and their last valid bid. |
| `endAuction()`      | Ends the auction, refunds losing bidders, and transfers final amount to the owner. |
| `getWinner()`       | Returns the winner's address and their bid. Requires the auction to be finished and have bids. |
| `getAllBids()`      | Returns an array of all bids submitted. |

---

## 🧬 Variables

| Variable             | Type        | Description |
|----------------------|-------------|-------------|
| `owner`              | `address`   | Address of the auction creator |
| `deadline`           | `uint256`   | Auction end time (timestamp) |
| `finished`           | `bool`      | Whether the auction has ended |
| `highestBid`         | `Bid`       | Struct containing the highest bid and its bidder |
| `bidsHistory`        | `mapping`   | History of bids per address |
| `totalDeposits`      | `mapping`   | Total ETH deposited per address |
| `allBids`            | `Bid[]`     | List of all submitted bids |
| `noReentrancySem`    | `bool`      | Internal semaphore to prevent reentrancy |

---

## 📢 Events

| Event                             | Triggered When |
|----------------------------------|----------------|
| `NewBid(address,uint256)`        | A new valid bid is submitted |
| `AuctionExtended(uint256)`       | Deadline is extended by 10 minutes |
| `AuctionEnded(address,uint256)`  | The auction is finalized |
| `AuctionStarted(uint256)`        | Constructor is called |
| `DepositRefunded(address,uint256)` | A non-winning bidder is refunded |
| `DepositPartiallyRefunded(address,uint256)` | A user withdraws their excess |

---

## 🔐 Security

- All critical `require(...)` statements are extracted into **modifiers** for clarity and reuse.
- The contract uses a `noReentrancy` modifier to protect against reentrancy attacks in both `withdrawExcess()` and `endAuction()`.
- After withdrawing the excess, only the last valid bid remains stored to avoid repeat withdrawals.
- Only the owner can call `endAuction()`.

---