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
        string memory codeBgColor = light ? "#ffffff" : "#1a1a1a";
        string memory textColor = light ? "#3a3a3a" : "#e0e0e0";
        string memory headerColor = light ? "#3a3a3a" : "#e0e0e0";

        string memory svg = string.concat(
            "<svg width=\"100%\" height=\"100%\" viewBox=\"0 0 1000 1000\" preserveAspectRatio=\"xMidYMid meet\" style=\"background-color: ", bgColor, "\" xmlns=\"http://www.w3.org/2000/svg\">",
            "<defs>",
            "<style>",
            ".header { font-family: monospace; font-size: 15px; line-height: 1.5; letter-spacing: 0.1em; }",
            ".code { font-family: monospace; font-size: 18px; line-height: 1.5; letter-spacing: 0.1em; white-space: pre-wrap; word-break: break-all; overflow: hidden; height: 100%; color: ", textColor, "; }",
            "</style>",
            "</defs>",
            "<rect width=\"1000\" height=\"1000\" fill=\"", codeBgColor, "\"/>",
            "<foreignObject x=\"60\" y=\"20\" width=\"880\" height=\"200\">",
            "<div xmlns=\"http://www.w3.org/1999/xhtml\" style=\"font-family: monospace; font-size: 15px; line-height: 1.5; letter-spacing: 0.1em; color: ", headerColor, "; white-space: pre-wrap;\">",
            "Codex #", _toString(tokenId), " preserved by ", caretakerStr, "\n",
            "/*\n",
            ".:: .::   .::     .::   .::::       .::         .:       .::: .::::::         .::                  .::\n",
            ".:    .:: .::     .:: .:    .::  .::   .::     .: ::          .::          .::   .::               .::\n",
            ".:     .::.::     .::.::        .::           .:  .::         .::         .::          .::         .::   .::    .::   .::\n",
            ".::: .:   .::     .::.::        .::          .::   .::        .::         .::        .::  .::  .:: .:: .:   .::   .: .::\n",
            ".:     .::.::     .::.::   .::::.::         .:::::: .::       .::         .::       .::    .::.:   .::.::::: .::   .:\n",
            ".:      .:.::     .:: .::    .:  .::   .:: .::       .::      .::          .::   .:: .::  .:: .:   .::.:         .:  .::\n",
            ".:::: .::   .:::::     .:::::      .::::  .::         .::     .::            .::::     .::     .:: .::  .::::   .::   .::\n",
            "*/",
            "</div>",
            "</foreignObject>",
            "<foreignObject x=\"60\" y=\"280\" width=\"880\" height=\"660\">",
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
