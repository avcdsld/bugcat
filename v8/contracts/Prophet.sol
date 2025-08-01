// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Prophet {
    function caress(address cat) external {
        if ((uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            address(this)
        ))) & 1) == 0) {
            for (uint i = 0; i < 10; i++) {
                cat.call(abi.encodeWithSignature("flip()"));
            }
            cat.call(abi.encodeWithSignature("caress()"));
        }
    }
}
