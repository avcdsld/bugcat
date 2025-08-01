// SPDX-License-Identifier: WTFPL
pragma solidity ^0.4.26;

interface BugCat {
    event Meow(address indexed caretaker, string wound);
    function caress() external;
    function remember() external view returns (bool);
}
