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

        string memory content = compiled ? _twoColsAutoHighlight(bytecode) : _escapeHtml(code);
        string memory comment = compiled ? "" : string.concat("<!-- ", bytecode, " -->");

        string memory bgColor = light ? "#f5f5f5" : "#0a0a0a";
        string memory boxBgColor = light ? "#ffffff" : "#1a1a1a";
        string memory textColor = light ? "#3a3a3a" : "#e0e0e0";
        string memory hlBg = light ? "#dddddd" : "#444444";

        string memory svg = string.concat(
            "<svg width=\"100%\" height=\"100%\" viewBox=\"0 0 1000 1000\" preserveAspectRatio=\"xMidYMid meet\" style=\"background-color: ", bgColor, "\" xmlns=\"http://www.w3.org/2000/svg\">",
            "<defs><style>\n",
            ".header { font-family: monospace; font-size: 17px; line-height: 1.0; letter-spacing: 0.01em; white-space: pre-wrap; word-break: break-all; overflow: hidden; height: 100%; color: ", textColor, "; }\n",
            ".code { font-family: monospace; font-size: 17px; line-height: 1.3; letter-spacing: 0.1em; white-space: pre-wrap; word-break: break-all; overflow: hidden; height: 100%; color: ", textColor, "; }\n",
            ".cols { display: flex; gap: 28px; }\n",
            ".col { flex: 1 1 0; }\n",
            ".hl { background:", hlBg, "; padding: 0 2px; border-radius: 2px; }\n",
            "</style></defs>",
            "<rect width=\"1000\" height=\"1000\" fill=\"", boxBgColor, "\"/>",

            "<foreignObject x=\"55\" y=\"30\" width=\"945\" height=\"30\">",
            "<div class=\"code\" xmlns=\"http://www.w3.org/1999/xhtml\">",
            "Codex #", _toString(tokenId), " preserved by ", caretakerStr, "\n",
            "</div></foreignObject>",

            "<foreignObject x=\"55\" y=\"70\" width=\"925\" height=\"120\">",
            "<div class=\"header\" xmlns=\"http://www.w3.org/1999/xhtml\">",
            "/////////////////////////////////////////////////////////////////////////////////////////////////////\n",
            "//          ____  __ __   ___    ___  ___  ______      ___   ___   ____    ____ _   _              //\n",
            "//          || )) || ||  // \\\\  //   // \\\\ | || |     //    // \\\\  || \\\\  ||    \\\\ //              //\n",
            "//          ||=)  || || (( ___ ((    ||=||   ||      ((    ((   )) ||  )) ||==   )X(               //\n",
            "//          ||_)) \\\\_//  \\\\_||  \\\\__ || ||   ||       \\\\__  \\\\_//  ||_//  ||___ // \\\\              //\n",
            "//                                                                                                 //\n",
            "/////////////////////////////////////////////////////////////////////////////////////////////////////\n",
            "</div></foreignObject>",

            "<foreignObject x=\"60\" y=\"220\" width=\"880\" height=\"790\">",
            "<div xmlns=\"http://www.w3.org/1999/xhtml\" class=\"code\">",
            content,
            "</div></foreignObject>",
            comment,
            "</svg>"
        );

        return string.concat("data:image/svg+xml;base64,", Base64.encode(bytes(svg)));
    }

    function _twoColsAutoHighlight(string memory hex0x) internal pure returns (string memory) {
        string memory hexStr = _strip0x(hex0x);
        bytes memory hb = bytes(hexStr);
        bytes memory raw = _hexToBytes(hb);

        uint256 bestStart = type(uint256).max;
        uint256 bestLen = 0;
        uint256 i = 0;
        while (i < raw.length) {
            if (raw[i] >= 0x61 && raw[i] <= 0x7A) {
                uint256 j = i + 1;
                while (j < raw.length && raw[j] >= 0x61 && raw[j] <= 0x7A) { unchecked { ++j; } }
                uint256 len = j - i;
                if (len >= 6 && len > bestLen) { bestLen = len; bestStart = i; }
                i = j;
            } else { unchecked { ++i; } }
        }

        uint256 pairs = hb.length / 2;
        uint256 leftPairs = pairs / 2;
        uint256 split = leftPairs * 2;

        string memory runHex = "";
        uint256 runPosHex = type(uint256).max;
        if (bestLen >= 6) {
            runHex = _bytesToHex(raw, bestStart, bestLen);
            runPosHex = LibString.indexOf(hexStr, runHex);
            if (runPosHex <= split && split < runPosHex + bytes(runHex).length) {
                split = runPosHex + bytes(runHex).length;
                if ((split & 1) == 1) split++;
                if (split > hb.length) split = hb.length;
            }
        }

        string memory left  = LibString.slice(hexStr, 0, split);
        string memory right = LibString.slice(hexStr, split);

        string memory leftG  = _groupPairsHex(left);
        string memory rightG = _groupPairsHex(right);

        if (runPosHex != type(uint256).max) {
            string memory runHexG = _groupPairsHex(runHex);
            string memory wrapped = string.concat("<span class=\"hl\">", runHexG, "</span>");
            if (runPosHex < split) {
                leftG  = _replaceOnce(leftG,  runHexG, wrapped);
            } else {
                rightG = _replaceOnce(rightG, runHexG, wrapped);
            }
        }

        return string.concat(
            "<div class=\"cols\"><div class=\"col\">", leftG, "</div><div class=\"col\">", rightG, "</div></div>"
        );
    }

    function _groupPairsHex(string memory hexWithOpt0x) internal pure returns (string memory) {
        bytes memory s = bytes(hexWithOpt0x);
        uint256 start = 0;
        bool has0x = false;
        if (s.length >= 2 && s[0] == "0" && (s[1] == "x" || s[1] == "X")) { has0x = true; start = 2; }
        uint256 hexLen = s.length - start;
        if (hexLen == 0) return hexWithOpt0x;

        uint256 pairs = hexLen / 2;
        uint256 spaces = pairs > 0 ? pairs - 1 : 0;
        uint256 outLen = (has0x ? 3 : 0) + hexLen + spaces;
        bytes memory out = new bytes(outLen);
        uint256 idx = 0;

        if (has0x) { out[idx++] = "0"; out[idx++] = "x"; out[idx++] = 0x20; }

        for (uint256 i = 0; i < hexLen; i += 2) {
            out[idx++] = s[start + i];
            if (i + 1 < hexLen) out[idx++] = s[start + i + 1];
            if (i + 2 < hexLen) out[idx++] = 0x20; // space
        }
        return string(out);
    }

    function _replaceOnce(string memory s, string memory needle, string memory replacement) internal pure returns (string memory) {
        uint256 p = LibString.indexOf(s, needle);
        if (p == type(uint256).max) return s;
        string memory head = LibString.slice(s, 0, p);
        string memory tail = LibString.slice(s, p + bytes(needle).length);
        return string.concat(head, replacement, tail);
    }

    function _strip0x(string memory s) internal pure returns (string memory) {
        bytes memory bs = bytes(s);
        if (bs.length >= 2 && bs[0] == "0" && (bs[1] == "x" || bs[1] == "X")) {
            bytes memory out = new bytes(bs.length - 2);
            for (uint256 k = 2; k < bs.length; ++k) out[k-2] = bs[k];
            return string(out);
        }
        return s;
    }

    function _hexToBytes(bytes memory hexChars) internal pure returns (bytes memory) {
        require(hexChars.length % 2 == 0, "hex length");
        bytes memory out = new bytes(hexChars.length / 2);
        for (uint256 k = 0; k < out.length; ++k) {
            out[k] = bytes1(( _nibble(hexChars[2*k]) << 4 ) | _nibble(hexChars[2*k+1]));
        }
        return out;
    }

    function _bytesToHex(bytes memory data, uint256 start, uint256 len) internal pure returns (string memory) {
        bytes memory out = new bytes(len * 2);
        for (uint256 k = 0; k < len; ++k) {
            uint8 b = uint8(data[start + k]);
            out[2*k]     = _hexChar(b >> 4);
            out[2*k + 1] = _hexChar(b & 0x0f);
        }
        return string(out);
    }

    function _nibble(bytes1 c) private pure returns (uint8) {
        uint8 u = uint8(c);
        if (u >= 48 && u <= 57) return u - 48;
        if (u >= 65 && u <= 70) return u - 55;
        if (u >= 97 && u <= 102) return u - 87;
        revert("bad hex");
    }

    function _hexChar(uint8 nib) private pure returns (bytes1) {
        return bytes1(nib + (nib < 10 ? 48 : 87));
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
