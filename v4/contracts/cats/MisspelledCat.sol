// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

import "../interface/BugCat.sol";

contract MisspelledCat is BugCat {
    address public owner;

    function MisspeledCat(address o) {
        owner = o;
    }

    function caress() public {
        if (msg.sender == owner) {
            emit Meow(msg.sender, "misspelled");
        }
    }

    function remember() external view returns (bool) {
        address Rubixi = 0xe82719202e5965Cf5D9B6673B7503a3b92DE20be;
        uint256 size; assembly { size := extcodesize(Rubixi) }
        return size > 0;
    }
}
