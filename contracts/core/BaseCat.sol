// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface BaseCat {
    function kind() external pure returns (string memory);
    function glitch() external payable;
}
