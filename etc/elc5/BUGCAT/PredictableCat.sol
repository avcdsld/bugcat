// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import "../interface/BugCat.sol";

contract PredictableCat is BugCat {
    mapping(address => uint8) public winCount;

    function flip() external {
        if ((uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender
        ))) & 1) == 0) {
            winCount[msg.sender] += 1;
        } else {
            winCount[msg.sender] = 0;
        }
    }

    function caress() public {
        if (winCount[msg.sender] >= 10) {
            emit Meow(msg.sender, "predictable");
            winCount[msg.sender] = 0;
        }
    }

    function remember() external view returns (bool) {
        address FoMo3Dlong = 0xA62142888ABa8370742bE823c1782D17A0389Da1;
        return FoMo3Dlong.code.length > 0;
    }
}
