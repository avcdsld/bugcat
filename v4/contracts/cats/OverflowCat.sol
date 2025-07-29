// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

import "../interface/BugCat.sol";

contract OverflowCat is BugCat {
    mapping(address => uint) public balance;

    function batchTransfer(address[] memory _receivers, uint256 _value) public {
        uint count = _receivers.length;
        uint amount = count * _value;
        require(_value > 0 && balance[msg.sender] >= amount);
        balance[msg.sender] -= amount;
        for (uint i = 0; i < count; i++) {
            balance[_receivers[i]] += _value;
        }
    }

    function caress() public {
        if (balance[msg.sender] > 0) {
            emit Meow(msg.sender, "overflow");
        }
    }

    function remember() external view returns (bool) {
        address BecToken = 0xC5d105E63711398aF9bbff092d4B6769C82F793D;
        uint256 size; assembly { size := extcodesize(BecToken) }
        return size > 0;
    }
}
