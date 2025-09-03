// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import "./utils/ENSResolver.sol";
import "solady/src/utils/LibString.sol";

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

contract BugcatCodexRenderer is IRender {

    function render(
        uint256 tokenId,
        address caretaker,
        address bugcat,
        string memory code,
        bool light,
        bool compiled
    ) external view override returns (string memory) {
        string memory caretakerStr;
        try ENSResolver.resolveAddress(caretaker) returns (string memory nameOrAddr) {
            caretakerStr = nameOrAddr;
        } catch {
            caretakerStr = LibString.toHexStringChecksummed(caretaker);
        }
        string memory bytecode = _hexFromBytes(bugcat.code, 0);
        string memory themeClass = light ? "light" : "dark";
        string memory codeContent;
        string memory commentContent;
        if (compiled) {
            codeContent = bytecode;
            commentContent = "";
        } else {
            codeContent = code;
            commentContent = string.concat("<!-- ", bytecode, " -->");
        }
        
        string memory html = string.concat(
            "<!DOCTYPE html>",
            "<html>",
            "<head>",
            "<meta charset=\"UTF-8\">",
            "<style>",
            "body{margin:0;height:100vh;font-family:monospace;font-size:1.7vmin;line-height:1.5;letter-spacing:0.1em;white-space:pre-wrap;display:flex;align-items:center;justify-content:center}",
            "body>div{width:100vmin;height:100vmin;display:flex;flex-direction:column;padding:4vmin 6vmin 6vmin 6vmin;box-sizing:border-box}",
            "body>div>div:first-child{font-size:1.4vmin;margin:1.5vmin 0 4vmin 0}",
            "body>div>div:last-child{flex:1;overflow:hidden;word-break:break-all}",
            ".light{background:#f5f5f5}",
            ".light>div{background:white;color:#3a3a3a}",
            ".light>div>div:first-child{color:#3a3a3a}",
            ".dark{background:#0a0a0a}",
            ".dark>div{background:#1a1a1a;color:#e0e0e0}",
            ".dark>div>div:first-child{color:#e0e0e0}",
            "</style>",
            "</head>",
            "<body class=\"", themeClass, "\">",
            "<div>",
            "<div>Codex #", _toString(tokenId), " preserved by ", caretakerStr, "</div>",
            "<div>", codeContent, "</div>",
            "</div>",
            commentContent,
            "</body>",
            "</html>"
            );

        return html;
    }

    function _hexFromBytes(bytes memory data, uint256 maxChars) internal pure returns (string memory) {
        if (data.length == 0) return "";
        bytes memory HEX = "0123456789abcdef";
        uint256 avail = data.length * 2;
        uint256 outLen = (maxChars == 0 || maxChars > avail) ? avail : maxChars;
        bytes memory out = new bytes(outLen);
        uint256 pairs = outLen / 2;
        for (uint256 i = 0; i < pairs; i++) {
            uint8 b = uint8(data[i]);
            out[2*i]   = HEX[b >> 4];
            out[2*i+1] = HEX[b & 0x0f];
        }
        return string(out);
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
}
