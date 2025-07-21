// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface BugCat {
    event Meow(address indexed tender, string wound);
    function tend() external payable;
    function remember() external view returns (bool);
}
