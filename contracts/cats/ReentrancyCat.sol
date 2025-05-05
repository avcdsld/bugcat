// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "../core/BaseCat.sol";
import "./ERC721.sol";
import "./Minter.sol";

contract ReentrancyCat is ERC721, BaseCat {
    string public name = "ReentrancyCat";
    string public symbol = "BUGCAT";
    uint256 public totalSupply = 0;
    mapping(uint256 => string) public metadata;

    function kind() external pure override returns (string memory) {
        return "Reentrancy";
    }

    function glitch() external payable override {
        Minter minter = new Minter(address(this));
        minter.mint(msg.sender);
    }

    function mint(address to) public {
        uint256 tokenId = totalSupply;
        metadata[tokenId] = string.concat(metadata[tokenId], "lonely...");
        _safeMint(to, tokenId);
        totalSupply++;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory quote = "proposal #59: lonely, so lonely";
        string memory svg = generateSVG(metadata[tokenId], quote);

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"ReentrancyCat #',
                Strings.toString(tokenId),
                '","description":"A cat that calls again.","image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '"}'
            )))
        ));
    }

    function generateSVG(string memory centerText, string memory ringText) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' width='300' height='300'>",
            "<style>",
            "@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(-360deg); } }",
            ".circle-text { font: 12px monospace; fill: white; }",
            ".center { font: 16px monospace; fill: white; dominant-baseline: middle; text-anchor: middle; }",
            ".spinning { animation: spin 10s linear infinite; transform-origin: 150px 150px; }",
            "</style>",
            "<rect width='100%' height='100%' fill='black'/>",
            "<circle cx='150' cy='150' r='100' fill='none' stroke='white' stroke-width='1'/>",
            "<defs>",
            "<path id='circlePath' d='M 150,150 m 0,-103 a 103,103 0 1,1 0,206 a 103,103 0 1,1 0,-206' fill='none'/>",
            "</defs>",
            "<text class='center' x='150' y='150'>", centerText, "</text>",
            "<g class='spinning'>",
            "<text class='circle-text'>",
            "<textPath href='#circlePath'>", ringText, "</textPath>",
            "</text>",
            "</g>",
            "</svg>"
        ));
    }
}
