// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IBugcatsRegistry {
    function bugs(uint256) external view returns (address);
    function count() external view returns (uint256);
}

interface IRender {
    function render(
        uint256 tokenId,
        address caretaker,
        address registry,
        uint8   lastCat,
        uint64  lastTime
    ) external view returns (string memory);
}

contract BugcatHouse is ERC721, ERC2981, Ownable {
    using Strings for uint256;

    IBugcatsRegistry public immutable registry;
    uint256 public immutable catCount;

    struct Memory {
        uint64 time;
        uint8  cat;
    }

    address public minter;
    address public renderer;
    uint256[] private _tokenIds;
    mapping(uint256 => Memory[]) private memories;



    event Mint(address indexed to, uint256 indexed tokenId, uint8 cat);
    event Return(uint256 indexed tokenId, uint8 cat, uint64 time);

    constructor(
        address _owner,
        address _registry,
        uint256 _catCount,
        address _renderer,
        address _royaltyReceiver
    ) ERC721("BUGCAT House", "HOUSE") Ownable(_owner) {
        registry = IBugcatsRegistry(_registry);
        catCount = _catCount;
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

    function mint(address to, uint256 tokenId) public {
        require(msg.sender == minter, "not minter");
        _mint(to, tokenId);
        _tokenIds.push(tokenId);
        uint8 cat = _choose(0);
        _remember(tokenId, cat);
        emit Mint(to, tokenId, cat);
    }

    function mintBatch(address[] memory to, uint256[] memory tokenIds) public {
        require(msg.sender == minter, "not minter");
        require(to.length == tokenIds.length, "length mismatch");
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], tokenIds[i]);
            _tokenIds.push(tokenIds[i]);
            uint8 cat = _choose(i + 1);
            _remember(tokenIds[i], cat);
            emit Mint(to[i], tokenIds[i], cat);
        }
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds.length;
    }

    function call(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "not caretaker");
        uint8 cat = _choose(memories[tokenId].length + 1);
        _remember(tokenId, cat);
    }

    function remember(uint256 tokenId, uint256 offset, uint256 limit) external view returns (Memory[] memory mems) {
        uint256 totalMemories = memories[tokenId].length;
        if (offset >= totalMemories) return new Memory[](0);
        uint256 count = (offset + limit > totalMemories) ? totalMemories - offset : limit;
        mems = new Memory[](count);
        for (uint256 i = 0; i < count; i++) {
            mems[i] = memories[tokenId][offset + i];
        }
    }

    function memoryCount(uint256 tokenId) external view returns (uint256) {
        return memories[tokenId].length;
    }

    function ownerOfCat(uint256 catIndex) external view returns (address) {
        require(_tokenIds.length > 0, "no houses");
        return ownerOf(_tokenIds[catIndex % _tokenIds.length]);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        Memory[] memory mems = memories[tokenId];
        string memory html = IRender(renderer).render(tokenId, ownerOf(tokenId), address(registry), mems[mems.length - 1].cat, mems[mems.length - 1].time);
        string memory json = string.concat(
            '{"name":"BUGCAT House #', tokenId.toString(),
            '","description":"BUGCATs wander. The house remembers."',
            ',"image":"', string.concat("data:text/html;base64,", Base64.encode(bytes(html))), '"}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function _remember(uint256 tokenId, uint8 cat) internal {
        memories[tokenId].push(Memory(uint64(block.timestamp), cat));
        emit Return(tokenId, cat, uint64(block.timestamp));
    }

    function _choose(uint256 salt) internal view returns (uint8) {
        return uint8((block.timestamp + salt) % catCount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
