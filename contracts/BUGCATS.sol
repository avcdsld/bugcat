// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BUGCATS {
    address[] public bugs;

    function owner() public view returns (address) {
        // TODO: get the owner of the bugcat
        return IERC721(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85).ownerOf(9724528409280397360129153152005364550111598890501967246845225370105154660239);
    }

    function inject(address bug) external {
        // require(msg.sender == owner());
        bugs.push(bug);
    }
}
