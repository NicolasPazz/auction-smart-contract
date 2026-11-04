# Auction Smart Contract

Solidity contract for an ETH auction with minimum bid increments, deadline extension, partial withdrawals and automatic refunds when the auction ends.

Deployed and verified on Sepolia: [`0x2820c61c...b28a`](https://sepolia.etherscan.io/address/0x2820c61cafcc3f83a760b4ecdd0e77ba01fcb28a#code)

## Rules

- A bid is accepted only while the auction is active and if it is at least 5% higher than the current highest bid.
- A bid placed in the last 10 minutes extends the deadline by 10 minutes.
- During the auction, a bidder can withdraw any amount deposited above their last valid bid.
- When the owner ends the auction, losing bidders are refunded their deposits minus a 2% fee, and the owner receives the winning bid.

## Functions

| Function | Description |
| --- | --- |
| `placeBid()` | Places a bid (payable). |
| `withdrawExcess()` | Refunds the difference between the caller's deposits and their last valid bid. |
| `endAuction()` | Owner only. Ends the auction, refunds losing bidders and pays the owner. |
| `getWinner()` | Returns the winner and the winning amount once the auction has ended. |
| `getAllBids()` | Returns every bid placed. |

## Events

`AuctionStarted`, `NewBid`, `AuctionExtended`, `AuctionEnded`, `DepositRefunded`, `DepositPartiallyRefunded`.

## Security

- Preconditions are implemented as modifiers.
- `withdrawExcess()` and `endAuction()` are protected against reentrancy with a lock.
- After a partial withdrawal only the last valid bid stays deposited, so the same excess cannot be withdrawn twice.

## Usage

The contract is a single file, `Auction.sol`. It can be compiled and deployed from [Remix](https://remix.ethereum.org/) by passing the auction duration in minutes to the constructor.
