// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import "./interface/BugCat.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BUGCATS is Ownable {
    address[] public bugs;

    constructor(address _owner) Ownable(_owner) {}

    function remember(uint256 index) external view returns (bool) {
        return BugCat(bugs[index]).remember();
    }

    function inject(address bug) external onlyOwner {
        bugs.push(bug);
    }
}
