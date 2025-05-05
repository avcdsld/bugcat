// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "./ERC721.sol";

abstract contract BugCat is ERC721 {
    string public name;
    string public symbol;
    string public kind;
    uint256 public totalSupply;

    address[] public caretakers;
    mapping(address => uint256) public weight;
    uint256 public totalWeight;

    constructor(string memory _name, string memory _symbol, string memory _kind) {
        name = _name;
        symbol = _symbol;
        kind = _kind;
        care();
    }

    receive() external payable {
        care();
    }

    function care() public payable {
        if (weight[msg.sender] == 0 && msg.value > 0) caretakers.push(msg.sender);
        weight[msg.sender] += msg.value;
        totalWeight += msg.value;
    }

    function owner() public view returns (address) {
        uint256 pick = uint256(block.prevrandao) % totalWeight;
        uint256 sum;
        for (uint i = 0; i < caretakers.length; i++) {
            sum += weight[caretakers[i]];
            if (pick < sum) return caretakers[i];
        }
        return caretakers[0];
    }
}
