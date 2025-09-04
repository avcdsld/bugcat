// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import "./utils/ENSResolver.sol";
import "solady/src/utils/LibString.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

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

        string memory bytecode = LibString.toHexString(bugcat.code);

        string memory content = compiled ? _highlightUtf8Runs(bytecode) : _escapeHtml(code);
        string memory comment = compiled ? "" : string.concat("<!-- ", bytecode, " -->");

        string memory bgColor = light ? "#f5f5f5" : "#0a0a0a";
        string memory boxBgColor = light ? "#ffffff" : "#1a1a1a";
        string memory textColor = light ? "#3a3a3a" : "#e0e0e0";
        string memory hlBg = light ? "#fff7aa" : "#3b2f00";

        string memory codeClass = compiled ? "code twocol" : "code";

        string memory svg = string.concat(
            "<svg width=\"100%\" height=\"100%\" viewBox=\"0 0 1000 1000\" preserveAspectRatio=\"xMidYMid meet\" style=\"background-color: ", bgColor, "\" xmlns=\"http://www.w3.org/2000/svg\">",
            "<defs><style>",
            ".header { font-family: monospace; font-size: 17px; line-height: 1.0; letter-spacing: 0.01em; white-space: pre-wrap; word-break: break-all; overflow: hidden; height: 100%; color: ", textColor, "; }\n",
            ".code { font-family: monospace; font-size: 17px; line-height: 1.3; letter-spacing: 0.1em; white-space: pre-wrap; word-break: break-all; overflow: hidden; height: 100%; color: ", textColor, "; }\n",
            ".twocol{column-count:2;column-gap:28px;}\n",
            ".hl{background:", hlBg, ";padding:0 2px;border-radius:2px;}\n",
            "</style></defs>",
            "<rect width=\"1000\" height=\"1000\" fill=\"", boxBgColor, "\"/>",

            "<foreignObject x=\"55\" y=\"30\" width=\"880\" height=\"30\">",
            "<div class=\"code\" xmlns=\"http://www.w3.org/1999/xhtml\">",
            "Codex #", _toString(tokenId), " preserved by ", caretakerStr, "\n",
            "</div></foreignObject>",

            "<foreignObject x=\"55\" y=\"70\" width=\"880\" height=\"120\">",
            "<div class=\"header\" xmlns=\"http://www.w3.org/1999/xhtml\">",
            "/////////////////////////////////////////////////////////////////////////////////////////////\n",
            "//   ____  __ __   ___    ___  ___  ______      ___   ___   ____    ____ _   _             //\n",
            "//   || )) || ||  // \\\\  //   // \\\\ | || |     //    // \\\\  || \\\\  ||    \\\\ //             //\n",
            "//   ||=)  || || (( ___ ((    ||=||   ||      ((    ((   )) ||  )) ||==   )X(              //\n",
            "//   ||_)) \\\\_//  \\\\_||  \\\\__ || ||   ||       \\\\__  \\\\_//  ||_//  ||___ // \\\\             //\n",
            "//                                                                                         //\n",
            "/////////////////////////////////////////////////////////////////////////////////////////////\n",
            "</div></foreignObject>",

            "<foreignObject x=\"60\" y=\"220\" width=\"880\" height=\"790\">",
            "<div xmlns=\"http://www.w3.org/1999/xhtml\" class=\"", codeClass, "\">",
            content,
            "</div></foreignObject>",
            comment,
            "</svg>"
        );

        return string.concat("data:image/svg+xml;base64,", Base64.encode(bytes(svg)));
    }

    function _highlightUtf8Runs(string memory hexWith0x) internal pure returns (string memory) {
        bytes memory b = bytes(_strip0x(hexWith0x));
        bytes memory raw = _hexToBytes(b);

        string memory out = hexWith0x;
        uint256 i = 0;
        while (i < raw.length) {
            if (raw[i] < 0x20 || raw[i] > 0x7E) { unchecked { ++i; } continue; }
            uint256 start = i;
            while (i < raw.length && raw[i] >= 0x20 && raw[i] <= 0x7E) { unchecked { ++i; } }
            uint256 len = i - start;
            if (len >= 4) {
                string memory hexRun = _bytesToHex(raw, start, len);
                string memory wrapped = string.concat("<span class=\"hl\">", hexRun, "</span>");
                out = LibString.replace(out, hexRun, wrapped);
            }
        }
        return out;
    }

    function _strip0x(string memory s) internal pure returns (string memory) {
        bytes memory bs = bytes(s);
        if (bs.length >= 2 && bs[0] == "0" && (bs[1] == "x" || bs[1] == "X")) {
            bytes memory out = new bytes(bs.length - 2);
            for (uint256 i = 2; i < bs.length; ++i) out[i-2] = bs[i];
            return string(out);
        }
        return s;
    }

    function _hexToBytes(bytes memory hexChars) internal pure returns (bytes memory) {
        require(hexChars.length % 2 == 0, "hex length");
        bytes memory out = new bytes(hexChars.length / 2);
        for (uint256 i = 0; i < out.length; ++i) {
            out[i] = bytes1(
                ( _nibble(hexChars[2*i]) << 4 ) | _nibble(hexChars[2*i+1])
            );
        }
        return out;
    }

    function _bytesToHex(bytes memory data, uint256 start, uint256 len) internal pure returns (string memory) {
        bytes memory out = new bytes(len * 2);
        for (uint256 i = 0; i < len; ++i) {
            uint8 b = uint8(data[start + i]);
            out[2*i]     = _hexChar(b >> 4);
            out[2*i + 1] = _hexChar(b & 0x0f);
        }
        return string(out);
    }

    function _nibble(bytes1 c) private pure returns (uint8) {
        uint8 u = uint8(c);
        if (u >= 48 && u <= 57) return u - 48;        // '0'-'9'
        if (u >= 65 && u <= 70) return u - 55;        // 'A'-'F'
        if (u >= 97 && u <= 102) return u - 87;       // 'a'-'f'
        revert("bad hex");
    }

    function _hexChar(uint8 nib) private pure returns (bytes1) {
        return bytes1(nib + (nib < 10 ? 48 : 87));    // 0-9 / a-f
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

    function _escapeHtml(string memory input) internal pure returns (string memory) {
        string memory result = LibString.replace(input, "&", "&amp;");
        result = LibString.replace(result, "<", "&lt;");
        result = LibString.replace(result, ">", "&gt;");
        result = LibString.replace(result, "\"", "&quot;");
        result = LibString.replace(result, "'", "&apos;");
        return result;
    }
}
