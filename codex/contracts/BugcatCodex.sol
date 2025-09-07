// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IBugcatsRegistry {
    function bugs(uint256) external view returns (address);
}

interface IRenderer {
    function renderImage(uint256 tokenId, address caretaker, uint8 bugcatIndex, string memory code, bool light, bool compiled) external view returns (string memory);
    function renderAnimationUrl(uint256 tokenId, address caretaker, uint8 bugcatIndex, string memory code, bool light, bool compiled, uint8[] memory preservedBugcatIndexes) external view returns (string memory);
}

contract BugcatCodex is ERC721, ERC2981, Ownable {
    using Strings for uint256;

    IBugcatsRegistry public immutable bugcatRegistry;
    uint256 public bugcatCount;
    IRenderer public renderer;
    address public minter;
    mapping(address => string) public codes;
    mapping(uint256 => uint8) public bugcatIndexes;
    mapping(uint256 => bool) public lights;
    mapping(uint256 => bool) public compileds;

    event Mint(address indexed to, uint256 indexed tokenId, uint8 bugcatIndex);

    constructor(address _owner, address _bugcatRegistry, uint8 _bugcatCount, address _renderer, address _royaltyReceiver) ERC721("BUGCAT Codex", "CODEX") Ownable(_owner) {
        bugcatRegistry = IBugcatsRegistry(_bugcatRegistry);
        bugcatCount = _bugcatCount;
        minter = _owner;
        renderer = IRenderer(_renderer);
        _setDefaultRoyalty(_royaltyReceiver, 1000);
    }

    function setMinter(address m) external onlyOwner {
        minter = m;
    }

    function setRenderer(address r) external onlyOwner {
        renderer = IRenderer(r);
    }

    function setBugcatCount(uint256 count) external onlyOwner {
        bugcatCount = count;
    }

    function setDefaultRoyalty(address receiver, uint96 bps) external onlyOwner {
        _setDefaultRoyalty(receiver, bps);
    }

    function rememberCode(address bugcat, string memory code) external onlyOwner {
        codes[bugcat] = code;
    }

    function mint(address to, uint256 tokenId) public {
        require(msg.sender == minter, "not minter");
        _mint(to, tokenId);
        uint8 bugcatIndex = _choose(0);
        bugcatIndexes[tokenId] = bugcatIndex;
        emit Mint(to, tokenId, bugcatIndex);
    }

    function mintBatch(address[] memory to, uint256[] memory tokenIds) public {
        require(msg.sender == minter, "not minter");
        require(to.length == tokenIds.length, "length mismatch");
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], tokenIds[i]);
            uint8 bugcatIndex = _choose(i + 1);
            bugcatIndexes[tokenIds[i]] = bugcatIndex;
            emit Mint(to[i], tokenIds[i], bugcatIndex);
        }
    }

    function switchTheme(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "not caretaker");
        lights[tokenId] = !lights[tokenId];
    }

    function compile(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "not caretaker");
        compileds[tokenId] = true;
    }

    function decompile(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "not caretaker");
        compileds[tokenId] = false;
    }

    function getPreservedBugcatIndexes(address caretaker) public view returns (uint8[] memory) {
        uint256 balance = balanceOf(caretaker);
        uint8[] memory indexes = new uint8[](balance);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(caretaker, i);
            indexes[i] = bugcatIndexes[tokenId];
        }
        return indexes;
    }

    function tokenOfOwnerByIndex(address caretaker, uint256 index) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < 10000; i++) {
            if (_ownerOf(i) == caretaker) {
                if (count == index) {
                    return i;
                }
                count++;
            }
        }
        revert("index out of bounds");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address caretaker = ownerOf(tokenId);
        uint8 bugcatIndex = bugcatIndexes[tokenId];
        address bugcat = bugcatRegistry.bugs(bugcatIndex);

        string memory image = IRenderer(renderer).renderImage(tokenId, caretaker, bugcatIndex, codes[bugcat], lights[tokenId], compileds[tokenId]);

        string memory animationUrl;
        try IRenderer(renderer).renderAnimationUrl(tokenId, caretaker, bugcatIndex, codes[bugcat], lights[tokenId], compileds[tokenId], getPreservedBugcatIndexes(caretaker)) returns (string memory url) {
            animationUrl = url;
        } catch {
            animationUrl = image;
        }

        string memory json = string.concat(
            '{',
                '"name":"BUGCAT Codex #', tokenId.toString(), '",',
                '"description":"BUGCATs wander. The Codex remembers.",',
                '"image":"', image, '",',
                '"animation_url":"', animationUrl, '",',
                '"attributes":[',
                    '{"trait_type":"BUGCAT Index","value":"', _toString(bugcatIndexes[tokenId]), '"},',
                    '{"trait_type":"Theme","value":"', lights[tokenId] ? "Light" : "Dark", '"},',
                    '{"trait_type":"Compiled","value":"', compileds[tokenId] ? "Yes" : "No", '"}'
                ']',
            '}'
        );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function _toString(uint256 value) internal pure returns (string memory str) {
        if (value == 0) return "0";
        uint256 temp = value; uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        str = string(buffer);
    }

    function _choose(uint256 salt) internal view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, salt))) % bugcatCount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
