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
    uint256[] private _allTokenIds;
    mapping(uint256 => Memory[]) private memories;

    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    event Mint(address indexed to, uint256 indexed tokenId, uint8 cat);
    event Return(uint256 indexed tokenId, uint8 cat, uint64 time);

    constructor(
        address _initialOwner,
        address _registry,
        uint256 _catCount,
        address _minter,
        address _renderer,
        address _royaltyReceiver
    ) ERC721("BUGCAT House", "HOUSE") Ownable(_initialOwner) {
        require(_registry != address(0), "registry=0");
        require(_catCount > 0, "catCount=0");
        registry = IBugcatsRegistry(_registry);
        catCount = _catCount;
        minter = _minter;
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

    function mint(address to, uint256 tokenId) public onlyMinter {
        _mint(to, tokenId);
        _allTokenIds.push(tokenId);

        uint8 cat = _pickCat(to, tokenId, 0);
        _logMemory(tokenId, cat);
        emit Mint(to, tokenId, cat);
    }

    function mintBatch(address[] memory to, uint256[] memory tokenIds) public onlyMinter {
        require(to.length == tokenIds.length, "length mismatch");
        uint256 n = to.length;

        bool[] memory used = new bool[](catCount);
        for (uint256 i = 0; i < n; i++) {
            _mint(to[i], tokenIds[i]);
            _allTokenIds.push(tokenIds[i]);

            uint8 cat;
            {
                uint256 r;

                bytes32 blockHash1 = blockhash(block.number - 1);
                bytes32 blockHash2 = blockhash(block.number - 2);
                
                r = uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            blockHash1,
                            blockHash2,
                            to[i],
                            tokenIds[i],
                            address(this),
                            i + 1
                        )
                    )
                );
                uint256 start = r % catCount;
                bool found;
                for (uint256 j = 0; j < catCount; j++) {
                    uint256 index = (start + j) % catCount;
                    if (!used[index] && _isContract(registry.bugs(index))) {
                        cat = uint8(index);
                        used[index] = true;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    cat = _pickCat(to[i], tokenIds[i], i + 1);
                }
            }

            _logMemory(tokenIds[i], cat);
            emit Mint(to[i], tokenIds[i], cat);
        }
    }

    function call(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "not caretaker");
        uint8 cat = _pickCat(msg.sender, tokenId, memories[tokenId].length + 1);
        _logMemory(tokenId, cat);
    }

    function remember(
        uint256 tokenId,
        uint256 offset,
        uint256 limit
    ) external view returns (uint64[] memory times, uint8[] memory cats) {
        Memory[] storage arr = memories[tokenId];
        uint256 n = arr.length;
        if (offset >= n) {
            return (new uint64[](0), new uint8[](0));
        }
        uint256 end = offset + limit;
        if (end > n) end = n;
        uint256 m = end - offset;

        times = new uint64[](m);
        cats  = new uint8[](m);
        for (uint256 i = 0; i < m; i++) {
            Memory storage v = arr[offset + i];
            times[i] = v.time;
            cats[i]  = v.cat;
        }
    }

    function latest(uint256 tokenId) public view returns (uint8 cat, uint64 ts) {
        Memory[] storage arr = memories[tokenId];
        if (arr.length == 0) return (0, 0);
        Memory storage v = arr[arr.length - 1];
        return (v.cat, v.time);
    }

    function totalMinted() external view returns (uint256) {
        return _allTokenIds.length;
    }

    function memoryCount(uint256 tokenId) external view returns (uint256) {
        return memories[tokenId].length;
    }

    function ownerOfCat(uint256 catIndex) external view returns (address) {
        uint256 n = _allTokenIds.length;
        require(n > 0, "no houses");
        uint256 r = uint256(keccak256(abi.encodePacked(catIndex, blockhash(block.number - 1), address(this))));
        uint256 tokenId = _allTokenIds[r % n];
        return ownerOf(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address care = ownerOf(tokenId);
        (uint8 lastCat, uint64 lastTime) = latest(tokenId);

        string memory html = "";
        if (renderer != address(0)) {
            html = IRender(renderer).render(
                tokenId,
                care,
                address(registry),
                lastCat,
                lastTime
            );
        }

        string memory json = string.concat(
            '{"name":"BUGCAT House #', tokenId.toString(),
            '","description":"BUGCATs wander. The house remembers."',
            ',"image":"', string.concat("data:text/html;base64,", Base64.encode(bytes(html))), '"}'
        );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function _logMemory(uint256 tokenId, uint8 cat) internal {
        address catAddr = registry.bugs(uint256(cat));
        bool bugcatIsHere;
        assembly { let s := extcodesize(catAddr) switch s case 0 { bugcatIsHere := 0 } default { bugcatIsHere := 1 } }
        require(bugcatIsHere, "BUGCAT not present");

        memories[tokenId].push(Memory(uint64(block.timestamp), cat));
        emit Return(tokenId, cat, uint64(block.timestamp));
    }

    function _pickCat(address to, uint256 tokenId, uint256 salt) internal view returns (uint8) {
        uint256 r;

        bytes32 blockHash1 = blockhash(block.number - 1);
        bytes32 blockHash2 = blockhash(block.number - 2);
        
        r = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    blockHash1,
                    blockHash2,
                    to,
                    tokenId,
                    address(this),
                    salt
                )
            )
        );
        
        uint256 start = r % catCount;

        for (uint256 j = 0; j < catCount; j++) {
            uint256 index = (start + j) % catCount;
            address catAddr = registry.bugs(index);
            uint256 size;
            assembly { size := extcodesize(catAddr) }
            if (size > 0) {
                return uint8(index);
            }
        }
        revert("no BUGCAT alive");
    }

    function _isContract(address x) internal view returns (bool ok) {
        assembly { let s := extcodesize(x) switch s case 0 { ok := 0 } default { ok := 1 } }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
