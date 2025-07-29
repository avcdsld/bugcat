// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

import "../interface/BugCat.sol";

contract UnprotectedCat is BugCat {
    address public owner;
    bool public initialized;

    function init(address o) public {
        owner = o;
        initialized = true;
    }

    function kill() public {
        require(msg.sender == owner);
        suicide(owner);
    }

    function caress() public {
        if (msg.sender == owner) {
            emit Meow(msg.sender, "unprotected");
        }
    }

    function remember() external view returns (bool) {
        address WalletLibrary = 0x863DF6BFa4469f3ead0bE8f9F2AAE51c91A907b4;
        uint256 size; assembly { size := extcodesize(WalletLibrary) }
        return size == 0 && WalletLibrary.balance > 0;
    }
}
