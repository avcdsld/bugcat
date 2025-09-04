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
        string memory content;
        string memory comment;
        if (compiled) {
            content = bytecode;
            comment = "";
        } else {
            content = code;
            comment = string.concat("<!-- ", bytecode, " -->");
        }

        string memory bgColor = light ? "#f5f5f5" : "#0a0a0a";
        string memory boxBgColor = light ? "#ffffff" : "#1a1a1a";
        string memory codeTextColor = light ? "#3a3a3a" : "#e0e0e0";
        string memory headerTextColor = light ? "#000000" : "#ffffff";

        string memory svg = string.concat(
            "<svg width=\"100%\" height=\"100%\" viewBox=\"0 0 1000 1000\" preserveAspectRatio=\"xMidYMid meet\" style=\"background-color: ", bgColor, "\" xmlns=\"http://www.w3.org/2000/svg\">",
            "<defs>",
            "<style>",
            ".header { font-family: 'Courier New', Consolas, Menlo, Monaco, monospace; font-size: 9px; line-height: 1.2; white-space: pre; font-weight: normal; letter-spacing: 0em; color: ", headerTextColor, "; }\n",
            ".code { font-family: monospace; font-size: 17px; line-height: 1.4; letter-spacing: 0.1em; white-space: pre-wrap; word-break: break-all; overflow: hidden; height: 100%; color: ", codeTextColor, "; }",
            "</style>",
            "</defs>",
            "<rect width=\"1000\" height=\"1000\" fill=\"", boxBgColor, "\"/>",
            "<foreignObject x=\"55\" y=\"20\" width=\"880\" height=\"160\">",
            "<div class=\"header\" xmlns=\"http://www.w3.org/1999/xhtml\">",
            " Codex #", _toString(tokenId), " preserved by ", caretakerStr, "\n",
            "==============================================================================================================================================================================\n",
            "\n",
            "`7MM\"\"\"Yp, `7MMF'   `7MF' .g8\"\"\"bgd    .g8\"\"\"bgd     db   MMP\"\"MM\"\"YMM       .g8\"\"\"bgd               `7MM                    \n",
            "  MM    Yb   MM       M .dP'     `M  .dP'     `M    ;MM:  P'   MM   `7     .dP'     `M                 MM                    \n",
            "  MM    dP   MM       M dM'       `  dM'       `   ,V^MM.      MM          dM'       ` ,pW\"Wq.    ,M\"\"bMM  .gP\"Ya `7M'   `MF'\n",
            "  MM\"\"\"bg.   MM       M MM           MM           ,M  `MM      MM          MM         6W'   `Wb ,AP    MM ,M'   Yb  `VA ,V'  \n",
            "  MM    `Y   MM       M MM.    `7MMF'MM.          AbmmmqMA     MM          MM.        8M     M8 8MI    MM 8M\"\"\"\"\"\"    XMX    \n",
            "  MM    ,9   YM.     ,M `Mb.     MM  `Mb.     ,' A'     VML    MM          `Mb.     ,'YA.   ,A9 `Mb    MM YM.    ,  ,V' VA.  \n",
            ".JMMmmmd9     `bmmmmd\"'   `\"bmmmdPY    `\"bmmmd'.AMA.   .AMMA..JMML.          `\"bmmmd'  `Ybmd9'   `Wbmd\"MML.`Mbmmd'.AM.   .MA.\n",
            "\n",
            "==============================================================================================================================================================================\n",
            "</div>",
            "</foreignObject>",
            "<foreignObject x=\"60\" y=\"190\" width=\"880\" height=\"780\">",
            "<div xmlns=\"http://www.w3.org/1999/xhtml\" class=\"code\">",
            _escapeHtml(content),
            "</div>",
            "</foreignObject>",
            comment,
            "</svg>"
        );

        return string.concat("data:image/svg+xml;base64,", Base64.encode(bytes(svg)));
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
