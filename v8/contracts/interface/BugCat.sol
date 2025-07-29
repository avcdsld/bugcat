// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface BugCat {
    event Meow(address indexed caretaker, string wound);
    function caress() external;
    function remember() external view returns (bool);
}
