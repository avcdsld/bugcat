// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "../core/BaseCat.sol";
import "./ERC721.sol";
import "./Minter.sol";

contract ReentrancyCat is ERC721, BaseCat {
    string public name = "ReentrancyCat";
    string public symbol = "BUGCAT";
    uint256 public totalSupply = 0;

    function kind() external pure override returns (string memory) {
        return "Reentrancy - one is not enough.";
    }

    function mint() external {
        _safeMint(msg.sender, totalSupply++);
        require(balanceOf[msg.sender] == 0);
    }

    function glitch() external payable override {
        Minter minter = new Minter(address(this));
        minter.mint(msg.sender);
    }
}
