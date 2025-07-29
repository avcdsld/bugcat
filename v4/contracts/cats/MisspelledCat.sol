// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

import "../interface/BugCat.sol";

contract MisspelledCat is BugCat {
    address public owner;
    bool public initialized;

    function MisspeledCat(address o) {
        owner = o;
        initialized = true;
    }

    function caress() public {
        if (msg.sender == owner) {
            emit Meow(msg.sender, "misspelled");
        }
    }

    function remember() external view returns (bool) {
        address Rubixi = 0x863DF6BFa4469f3ead0bE8f9F2AAE51c91A907b4;
        uint256 size; assembly { size := extcodesize(Rubixi) }
        return size > 0;
    }
}
