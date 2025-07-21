// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../interface/BugCat.sol";

contract ReentrancyCat is BugCat {
    mapping(address => uint) public balance;

    function deposit() public payable {
        balance[msg.sender] += msg.value;
    }

    function withdraw() public {
        (bool success, ) = msg.sender.call{value: balance[msg.sender]}("");
        require(success);
        balance[msg.sender] = 0;
    }

    function tend() public payable {
        if (address(this).balance == 0) {
            emit Meow(msg.sender, "reentrancy");
        }
    }

    function remember() external view returns (bool) {
        address TheDAO = 0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413;
        return TheDAO.code.length > 0;
    }
}
