// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface TheDAO {
    function proposals(uint256) external view returns (
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
    );
}

contract Render {
    TheDAO public dao;

    constructor(address _dao) {
        dao = TheDAO(_dao);
    }

    function tokenURI(uint256 id, string memory wound) external view returns (string memory) {
        string memory scar = "proposal #59: ";
        try dao.proposals(59) returns (
            address, uint256, string memory desc, uint256, bool, bool, bytes32, uint256, bool, uint256, uint256, address
        ) {
            scar = string.concat(scar, desc);
        } catch {
            scar = string.concat(scar, "error: not found");
        }
        string memory svg = generateSVG(wound, scar);
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"ReentrancyCat #',
                Strings.toString(id),
                '","description":"A cat that calls again.","image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '"}'
            )))
        ));
    }

    function generateSVG(string memory wound, string memory scar) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' width='100%' height='100%' viewBox='0 0 300 300'>",
            "<style>@keyframes spin{from{transform:rotate(0)}to{transform:rotate(-360deg)}}",
            ".circle-text{font:12px monospace;fill:white}",
            ".center{font:16px monospace;fill:white;dominant-baseline:middle;text-anchor:middle}",
            ".spinning{animation:spin 10s linear infinite;transform-origin:center}</style>",
            "<rect width='100%' height='100%' fill='black'/>",
            "<circle cx='150' cy='150' r='100' fill='none' stroke='white' stroke-width='1'/>",
            "<defs><path id='circlePath' d='M150,150m0,-103a103,103 0 1,1 0,206a103,103 0 1,1 0,-206'/></defs>",
            "<text class='center' x='150' y='150'>", wound, "</text>",
            "<g class='spinning'><text class='circle-text'><textPath href='#circlePath'>", scar, "</textPath></text></g>",
            "</svg>"
        ));
    }
}
