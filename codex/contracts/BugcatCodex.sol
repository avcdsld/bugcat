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

interface IRender {
    function render(
        uint256 tokenId,
        address caretaker,
        address bugcat,
        string memory code,
        bool light,
        bool compiled
    ) external view returns (string memory);
}

contract BugcatCodex is ERC721, ERC2981, Ownable {
    using Strings for uint256;

    IBugcatsRegistry public immutable registry;
    uint256 public immutable bugcatCount;

    address public minter;
    address public renderer;
    mapping(address => string) public codes;
    mapping(uint256 => uint8) public bugcatIndexes;
    mapping(uint256 => bool) public lights;
    mapping(uint256 => bool) public compileds;

    event Mint(address indexed to, uint256 indexed tokenId, uint8 bugcatIndex);

    constructor(
        address _owner,
        address _registry,
        uint8 _bugcatCount,
        address _renderer,
        address _royaltyReceiver
    ) ERC721("BUGCAT Codex", "CODEX") Ownable(_owner) {
        registry = IBugcatsRegistry(_registry);
        bugcatCount = _bugcatCount;
        minter = _owner;
        renderer = _renderer;
        _setDefaultRoyalty(_royaltyReceiver, 1000);
    }

    function setMinter(address m) external onlyOwner {
        minter = m;
    }

    function setRenderer(address r) external onlyOwner {
        renderer = r;
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

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address bugcat = IBugcatsRegistry(registry).bugs(bugcatIndexes[tokenId]);
        string memory html = IRender(renderer).render(tokenId, ownerOf(tokenId), bugcat, codes[bugcat], lights[tokenId], compileds[tokenId]);
        string memory json = string.concat(
            '{',
            '"name":"BUGCAT Codex #', tokenId.toString(), '",',
            '"description":"BUGCATs wander. The Codex remembers.",',
            '"image":"', string.concat("data:text/html;base64,", Base64.encode(bytes(html))), '"',
            '}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function _choose(uint256 salt) internal view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, salt))) % bugcatCount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
