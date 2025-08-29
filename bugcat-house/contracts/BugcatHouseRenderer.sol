// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import "./utils/ENSResolver.sol";
import "solady/src/utils/LibString.sol";

interface IBugcatHouse {
    function memoryCount(uint256 tokenId) external view returns (uint256);
}

interface IBugCatsRegistry {
    function bugs(uint256) external view returns (address);
}

interface IRender {
    function render(
        uint256 tokenId,
        address caretaker,
        address registry,
        uint8   lastCat,
        uint64  lastTs
    ) external view returns (string memory);
}

contract BugcatHouseRenderer is IRender {

    function render(
        uint256 tokenId,
        address caretaker,
        address registry,
        uint8   lastCat,
        uint64  lastTs
    ) external view override returns (string memory) {
        string memory careStr;
        try ENSResolver.resolveAddress(caretaker) returns (string memory nameOrAddr) {
            careStr = nameOrAddr;
        } catch {
            careStr = LibString.toHexStringChecksummed(caretaker);
        }
        address catAddr = IBugCatsRegistry(registry).bugs(lastCat);
        string memory label = senseWound(catAddr);
            if (bytes(label).length == 0) label = "unknown";

        string memory title = string.concat("BUGCAT House #", _u(tokenId));
        string memory line1 = string.concat("Caretaker ", unicode"—", " ", careStr);
        string memory line2 = string.concat(
            "Remembers the ", _ordinal(IBugcatHouse(msg.sender).memoryCount(tokenId)),
            " return: ", label, " cat ", unicode"·", " ", _timestampISO(lastTs));

        string memory hexText = _hexFromBytes(registry.code, 0);
        if (bytes(hexText).length == 0) {
            hexText = _repeat01(800);
        }

        string memory html = string.concat(
            "<!DOCTYPE html>",
            "<html lang=\"ja\">",
            "<head>",
            "<meta charset=\"utf-8\" />",
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />",
            "<title>", title, "</title>",
                "<style>",
            "html, body { height: 100%; margin: 0; background: #000000; }",
            "body { display: grid; place-items: center; font-family: 'Courier New', Courier, monospace; }",
            ".container { width: min(95vw, 600px); max-height: 95vh; }",
            "svg { width: 100%; height: 100%; display: block; }",
            ".hex-char { fill: #ffffff; font-size: 11px; font-weight: normal; text-anchor: middle; dominant-baseline: middle; }",
            ".face-top { fill: #666666; opacity: 0.6; }",
            ".face-right { fill: #555555; opacity: 0.5; }",
            ".face-front { fill: #777777; opacity: 0.55; }",
            ".edge-char { fill: #ffffff; font-size: 11px; font-weight: normal; text-anchor: middle; dominant-baseline: middle; }",
            ".entrance-char { fill: #ffffff; font-size: 11px; font-weight: normal; text-anchor: middle; dominant-baseline: middle; }",
            "</style>",
            "</head>",
            "<body>",
            "<div class=\"container\">",
            "<div id=\"info\" style=\"color: #ffffff; font-size: min(1.4vw, 16px); margin-bottom: 0.5vw; text-align: center; line-height: 1.3;\">",
            "<div style=\"font-size: min(1.7vw, 18px); font-weight: bold; margin-bottom: 1.2vw; opacity: 1;\">", title, "</div>",
            "<div id=\"caretaker-info\" style=\"margin-bottom: 0.6vw; opacity: 0.9; font-size: min(1.4vw, 16px);\">", line1, "</div>",
            "<div id=\"return-info\" style=\"opacity: 0.8; font-size: min(1.4vw, 16px);\">", line2, "</div>",
            "</div>",
            "<svg id=\"house\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 600 450\">",
            "<g id=\"faces\"></g>",
            "<g id=\"edges\"></g>",
            "<g id=\"entrance\"></g>",
            "</svg>",
            "</div>",
            "<script>",
            "(function() {",
            "const NS = 'http://www.w3.org/2000/svg';",
            "const GRID_STEP = 10;",
            "const SVG_WIDTH = 600;",
            "const SVG_HEIGHT = 450;",
            "const ISO_ANGLE = Math.PI / 6;",
            "const SIZE = 200;",
            "const CENTER = { x: 300, y: 225 };",
            "const bytecode = '", hexText, "';",
            "const hexChars = bytecode.slice(2).toUpperCase().split('');",
            "const getHex = index => hexChars[index % hexChars.length];",
            "const project = (x, y, z) => ({",
            "x: CENTER.x + (x - z) * Math.cos(ISO_ANGLE),",
            "y: CENTER.y + (x + z) * Math.sin(ISO_ANGLE) - y",
            "});",
            "const createText = (x, y, char, className = 'hex-char') => {",
            "const el = document.createElementNS(NS, 'text');",
            "el.setAttribute('x', x.toFixed(1));",
            "el.setAttribute('y', y.toFixed(1));",
            "el.setAttribute('class', className);",
            "el.textContent = char;",
            "return el;",
            "};",
            "const inside = (x, y, corners) => {",
            "let result = false;",
            "for (let i = 0, j = corners.length - 1; i < corners.length; j = i++) {",
            "if ((corners[i].y > y) != (corners[j].y > y) &&",
            "x < (corners[j].x - corners[i].x) * (y - corners[i].y) / (corners[j].y - corners[i].y) + corners[i].x) {",
            "result = !result;",
            "}",
            "}",
            "return result;",
            "};",
            "const offsetPolygon = (corners, offset) => {",
            "const cx = corners.reduce((sum, p) => sum + p.x, 0) / corners.length;",
            "const cy = corners.reduce((sum, p) => sum + p.y, 0) / corners.length;",
            "const lines = [];",
            "for (let i = 0; i < corners.length; i++) {",
            "const p1 = corners[i];",
            "const p2 = corners[(i + 1) % corners.length];",
            "const dx = p2.x - p1.x;",
            "const dy = p2.y - p1.y;",
            "const len = Math.hypot(dx, dy);",
            "let nx = -dy / len;",
            "let ny = dx / len;",
            "const midX = (p1.x + p2.x) / 2;",
            "const midY = (p1.y + p2.y) / 2;",
            "const toCenterX = cx - midX;",
            "const toCenterY = cy - midY;",
            "if (nx * toCenterX + ny * toCenterY < 0) {",
            "nx = -nx;",
            "ny = -ny;",
            "}",
            "lines.push({",
            "p1: { x: p1.x + nx * offset, y: p1.y + ny * offset },",
            "p2: { x: p2.x + nx * offset, y: p2.y + ny * offset }",
            "});",
            "}",
            "const newCorners = [];",
            "for (let i = 0; i < corners.length; i++) {",
            "const line1 = lines[i];",
            "const line2 = lines[(i + 1) % corners.length];",
            "const x1 = line1.p1.x, y1 = line1.p1.y;",
            "const x2 = line1.p2.x, y2 = line1.p2.y;",
            "const x3 = line2.p1.x, y3 = line2.p1.y;",
            "const x4 = line2.p2.x, y4 = line2.p2.y;",
            "const denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);",
            "if (Math.abs(denom) > 0.001) {",
            "const t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom;",
            "newCorners.push({",
            "x: x1 + t * (x2 - x1),",
            "y: y1 + t * (y2 - y1)",
            "});",
            "} else {",
            "newCorners.push(corners[(i + 1) % corners.length]);",
            "}",
            "}",
            "return newCorners;",
            "};",
            "const placeOnGrid = (container, checkFunction, className, startIndex) => {",
            "let index = startIndex;",
            "const texts = [];",
            "for (let y = 0; y <= SVG_HEIGHT; y += GRID_STEP) {",
            "for (let x = 0; x <= SVG_WIDTH; x += GRID_STEP) {",
            "if (checkFunction(x, y)) {",
            "const el = createText(x, y, getHex(index++), className);",
            "container.appendChild(el);",
            "texts.push(el);",
            "}",
            "}",
            "}",
            "return { texts, nextIndex: index };",
            "};",
            "const placeOnLine = (container, p1, p2, className, startIndex, occupied = new Set()) => {",
            "const texts = [];",
            "const dx = p2.x - p1.x;",
            "const dy = p2.y - p1.y;",
            "const len = Math.hypot(dx, dy);",
            "const numSteps = Math.floor(len / GRID_STEP);",
            "let index = startIndex;",
            "for (let i = 0; i <= numSteps; i++) {",
            "const distance = i * GRID_STEP;",
            "if (distance <= len) {",
            "const t = distance / len;",
            "const x = p1.x + t * dx;",
            "const y = p1.y + t * dy;",
            "const key = `${Math.round(x)},${Math.round(y)}`;",
            "if (!occupied.has(key)) {",
            "const el = createText(x, y, getHex(index++), className);",
            "container.appendChild(el);",
            "texts.push(el);",
            "occupied.add(key);",
            "}",
            "}",
            "}",
            "return texts;",
            "};",
            "const v3d = [",
            "{x: -1, y: -1, z: -1}, {x: 1, y: -1, z: -1}, {x: 1, y: 1, z: -1}, {x: -1, y: 1, z: -1},",
            "{x: -1, y: -1, z: 1}, {x: 1, y: -1, z: 1}, {x: 1, y: 1, z: 1}, {x: -1, y: 1, z: 1}",
            "].map(v => ({",
            "x: v.x * SIZE / 2,",
            "y: v.y * SIZE / 2,",
            "z: v.z * SIZE / 2",
            "}));",
            "const v2d = v3d.map(v => project(v.x, v.y, v.z));",
            "const front = [v2d[4], v2d[5], v2d[6], v2d[7]];",
            "const cx = front.reduce((sum, p) => sum + p.x, 0) / 4;",
            "const cy = front.reduce((sum, p) => sum + p.y, 0) / 4;",
            "const entrance = front.map(p => ({",
            "x: cx + (p.x - cx) * 0.35,",
            "y: cy + (p.y - cy) * 0.35",
            "}));",
            "const facesGroup = document.getElementById('faces');",
            "const faces = [",
            "{ className: 'hex-char face-top', check: (x, y) => inside(x, y, [v2d[3], v2d[2], v2d[6], v2d[7]]) },",
            "{ className: 'hex-char face-right', check: (x, y) => inside(x, y, [v2d[1], v2d[5], v2d[6], v2d[2]]) },",
            "{ className: 'hex-char face-front', check: (x, y) => {",
            "if (!inside(x, y, [v2d[4], v2d[5], v2d[6], v2d[7]])) return false;",
            "return !inside(x, y, offsetPolygon(entrance, -9));",
            "} }",
            "];",
            "faces.forEach((face, idx) => {",
            "placeOnGrid(facesGroup, face.check, face.className, idx * 500);",
            "});",
            "const edgesGroup = document.getElementById('edges');",
            "const edges = [",
            "[v2d[4], v2d[5]], [v2d[5], v2d[6]], [v2d[6], v2d[7]], [v2d[7], v2d[4]],",
            "[v2d[1], v2d[5]], [v2d[1], v2d[2]], [v2d[2], v2d[6]],",
            "[v2d[3], v2d[7]], [v2d[3], v2d[2]]",
            "];",
            "const edgeTexts = [];",
            "const edgeOccupied = new Set();",
            "edges.forEach(([p1, p2]) => {",
            "const texts = placeOnLine(edgesGroup, p1, p2, 'edge-char', 2000, edgeOccupied);",
            "edgeTexts.push(texts);",
            "});",
            "const entranceGroup = document.getElementById('entrance');",
            "const entranceTexts = [];",
            "const entranceOccupied = new Set();",
            "const entranceEdges = [",
            "[entrance[0], entrance[1]], [entrance[1], entrance[2]],",
            "[entrance[2], entrance[3]], [entrance[3], entrance[0]]",
            "];",
            "entranceEdges.forEach(([p1, p2]) => {",
            "const texts = placeOnLine(entranceGroup, p1, p2, 'entrance-char', 3000, entranceOccupied);",
            "entranceTexts.push(texts);",
            "});",
            "let offset = 0;",
            "setInterval(() => {",
            "offset++;",
            "edgeTexts.forEach((texts, idx) => {",
            "texts.forEach((el, i) => {",
            "el.textContent = getHex((1000 + offset + idx * 30 + i) % hexChars.length);",
            "});",
            "});",
            "entranceTexts.forEach((texts, idx) => {",
            "texts.forEach((el, i) => {",
            "el.textContent = getHex((1500 + offset + idx * 20 + i) % hexChars.length);",
            "});",
            "});",
            "}, 500);",
            "})();",
            "</script>",
            "</body>",
            "</html>"
            );

        return html;
    }

    function senseWound(address cat) public view returns (string memory) {
        bytes memory code = cat.code;
        if (code.length == 0) return "";
        
        string memory wound = _extractWoundFromBytecode(code);
        if (bytes(wound).length > 0) return wound;
        
        string memory run = _longestAsciiRun(code, 6);
        if (bytes(run).length != 0) return run;
        return "";
    }

    function _extractWoundFromBytecode(bytes memory code) internal pure returns (string memory) {
        string memory saddestWound = "";
        uint256 saddestValue = 0;
        
        for (uint256 i = 0; i < code.length; i++) {
            if (code[i] >= 0x60 && code[i] <= 0x7f) {
                uint8 opcode = uint8(code[i]);
                uint256 pushSize = opcode - 0x5f;
                
                if (i + pushSize + 1 < code.length) {
                    bytes memory data = new bytes(pushSize);
                    for (uint256 j = 0; j < pushSize; j++) {
                        data[j] = code[i + 1 + j];
                    }
                    
                    if (_isPaddedString(data)) {
                        bytes memory cleaned = _removePadding(data);
                        if (_isValidAscii(cleaned)) {
                            string memory candidate = string(cleaned);
                            uint256 sadness = _measureSadness(candidate);
                            if (sadness > saddestValue) {
                                saddestValue = sadness;
                                saddestWound = candidate;
                            }
                        }
                    }
                }
                i += pushSize;
            }
            
            else if (i + 10 < code.length) {
                if (code[i] == 0x90 && 
                    code[i+1] == 0x82 && 
                    code[i+2] == 0x01 && 
                    code[i+3] == 0x52 && 
                    code[i+4] == 0x7f) {
                    
                    uint256 maxLen = 32;
                    if (i + 5 + maxLen > code.length) {
                        maxLen = code.length - i - 5;
                    }
                    
                    bytes memory data = new bytes(maxLen);
                    for (uint256 j = 0; j < maxLen; j++) {
                        data[j] = code[i + 5 + j];
                    }
                    
                    bytes memory cleaned = _extractValidString(data);
                    if (cleaned.length > 0) {
                        string memory candidate = string(cleaned);
                        uint256 sadness = _measureSadness(candidate);
                        if (sadness > saddestValue) {
                            saddestValue = sadness;
                            saddestWound = candidate;
                        }
                    }
                    
                    i += 4 + maxLen;
                }
            }
        }
        
        return saddestWound;
    }

    function _measureSadness(string memory candidate) internal pure returns (uint256) {
        bytes memory b = bytes(candidate);
        if (b.length < 3 || b.length > 20) return 0;
        
        uint256 sadness = 0;
        
        for (uint256 i = 0; i < b.length; i++) {
            uint8 char = uint8(b[i]);
            if (char >= 0x61 && char <= 0x7a) { // a-z
                sadness += 10;
            } else if (char >= 0x41 && char <= 0x5a) { // A-Z
                sadness += 8;
            } else if (char >= 0x30 && char <= 0x39) { // 0-9
                sadness += 5;
            } else if (char == 0x20 || char == 0x2d || char == 0x5f) { // space, -, _
                sadness += 3;
            } else {
                sadness = 0;
                break;
            }
        }
        
        return sadness + (b.length * 2);
    }

    function _isPaddedString(bytes memory data) internal pure returns (bool) {
        if (data.length < 3) return false;
        
        uint8 lastByte = uint8(data[data.length - 1]);
        uint8 secondLast = uint8(data[data.length - 2]);
        
        if (lastByte == 0x1b && (secondLast == 0xb0 || secondLast == 0xa8)) {
            return true;
        }
        
        return _isValidAscii(data);
    }

    function _removePadding(bytes memory data) internal pure returns (bytes memory) {
        uint256 end = data.length;
        
        if (end >= 2 && uint8(data[end-1]) == 0x1b) {
            end -= 2;
        }
        
        while (end > 0 && data[end-1] == 0) {
            end--;
        }
        
        bytes memory result = new bytes(end);
        for (uint256 i = 0; i < end; i++) {
            result[i] = data[i];
        }
        
        return result;
    }

    function _extractValidString(bytes memory data) internal pure returns (bytes memory) {
        uint256 validEnd = 0;
        
        for (uint256 i = 0; i < data.length; i++) {
            uint8 char = uint8(data[i]);
            if (char >= 0x20 && char <= 0x7E) {
                validEnd = i + 1;
            } else if (char != 0x00) {
                break;
            }
        }
        
        if (validEnd < 3) return new bytes(0);
        
        bytes memory result = new bytes(validEnd);
        for (uint256 i = 0; i < validEnd; i++) {
            result[i] = data[i];
        }
        
        return result;
    }

    function _isValidAscii(bytes memory data) internal pure returns (bool) {
        if (data.length == 0) return false;
        
        uint256 validCount = 0;
        for (uint256 i = 0; i < data.length; i++) {
            uint8 char = uint8(data[i]);
            if (char >= 0x20 && char <= 0x7E) {
                validCount++;
            } else if (char != 0x00 && char != 0xb0 && char != 0xa8 && char != 0x1b) {
                return false;
            }
        }
        
        return validCount >= 3;
    }

    function _longestAsciiRun(bytes memory code, uint256 minLen) internal pure returns (string memory) {
        uint256 bestStart; uint256 bestLen;
        uint256 curStart;  uint256 curLen;
        for (uint256 i = 0; i < code.length; i++) {
            uint8 c = uint8(code[i]);
            bool isAscii = (c >= 0x20 && c <= 0x7E);
            if (isAscii) {
                if (curLen == 0) curStart = i;
                curLen++;
            } else {
                if (curLen >= minLen && curLen > bestLen) { bestStart = curStart; bestLen = curLen; }
                curLen = 0;
            }
        }
        if (curLen >= minLen && curLen > bestLen) { bestStart = curStart; bestLen = curLen; }
        if (bestLen == 0) return "";
        bytes memory out = new bytes(bestLen);
        for (uint256 k = 0; k < bestLen; k++) out[k] = code[bestStart + k];
        return string(out);
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

    function _repeat01(uint256 pairs) internal pure returns (string memory s) {
        bytes memory b = new bytes(pairs * 2);
        for (uint256 i = 0; i < pairs; i++) {
            b[2*i] = "0";
            b[2*i+1] = "1";
        }
        s = string(b);
    }

    function _ordinal(uint256 n) internal pure returns (string memory) {
        uint256 mod100 = n % 100;
        if (mod100 >= 11 && mod100 <= 13) return string.concat(_u(n), "th");
        uint256 mod10 = n % 10;
        if (mod10 == 1) return string.concat(_u(n), "st");
        if (mod10 == 2) return string.concat(_u(n), "nd");
        if (mod10 == 3) return string.concat(_u(n), "rd");
        return string.concat(_u(n), "th");
    }

    function _timestampISO(uint64 time) internal pure returns (string memory) {
        uint256 days_ = uint256(time) / 86400;
        uint256 secs  = uint256(time) % 86400;
        uint256 hh = secs / 3600; secs %= 3600;
        uint256 mm = secs / 60;   secs %= 60;
        uint256 ss = secs;
        (uint256 y, uint256 m, uint256 d) = _daysToDate(days_);
        return string.concat(
            _u4(y), "-", _u2(m), "-", _u2(d), " ",
            _u2(hh), ":", _u2(mm), ":", _u2(ss), "Z"
        );
    }

    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        int256 __days = int256(_days);
        int256 L = __days + 68569 + 2440588;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;
        year = uint256(_year); month = uint256(_month); day = uint256(_day);
    }

    function _u(uint256 v) internal pure returns (string memory) {
        return _toString(v);
    }

    function _u2(uint256 v) internal pure returns (string memory) {
        if (v < 10) return string.concat("0", _toString(v));
        return _toString(v);
    }

    function _u4(uint256 v) internal pure returns (string memory) {
        if (v < 10) return string.concat("000", _toString(v));
        if (v < 100) return string.concat("00", _toString(v));
        if (v < 1000) return string.concat("0", _toString(v));
        return _toString(v);
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
