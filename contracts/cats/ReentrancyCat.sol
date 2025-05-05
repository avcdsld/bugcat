// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "../core/BugCat.sol";
import "./Render.sol";

contract ReentrancyCat is BugCat {
    mapping(uint256 => string) public wound;
    Render public render;

    constructor(address _render) BugCat("ReentrancyCat", "BUGCAT", "Reentrancy") {
        render = Render(_render);
    }

    function mint(address to) public {
        uint256 id = totalSupply;
        wound[id] = string.concat(wound[id], "lonely...");
        _safeMint(to, id);
        totalSupply++;
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        return render.tokenURI(id, wound[id]);
    }
}
