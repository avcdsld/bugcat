// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

contract TheDAOMock {
    function proposals(uint256) external pure returns (
        address recipient,
        uint256 amount,
        string memory description,
        uint256 votingDeadline,
        bool open,
        bool proposalPassed,
        bytes32 proposalHash,
        uint256 proposalDeposit,
        bool newCurator,
        uint256 yea,
        uint256 nay,
        address creator
    ) {
        return (
            address(0),
            0,
            "lonely, so lonely",
            0,
            false,
            false,
            bytes32(0),
            0,
            false,
            0,
            0,
            address(0)
        );
    }
} 