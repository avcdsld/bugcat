// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import "./utils/ENSResolver.sol";
import "solady/src/utils/LibString.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IBugcatsRegistry {
    function bugs(uint256) external view returns (address);
}

contract BugcatCodexRenderer {
    IBugcatsRegistry public immutable bugcatRegistry;
    
    string private specialCodeLight;
    string private specialCodeDark;

    constructor(address _bugcatRegistry) {
        bugcatRegistry = IBugcatsRegistry(_bugcatRegistry);
        specialCodeLight = "+-+++-.--------+++++--.---+----+++++--------++++++++-.-------+++---.-#########-...----++++++-.---+++\n+-+++-.------.---+++--.----------++--.-.+----------+-.---------++--..#########-.-##------+++-.----+-\n+-----..----.+##+..........-----------####-----------.---------##+...+########-....-###-----...-----\n+--+++-------+####+----------.-----.+#####+.-----------------.-----+##########-++..-+---------------\n#--++++++++--+###++#+.-------.----+###++###.--------++++++++-.-++--#########--.------.--------++++++\n#------+++++-+###+++##+-----++++-##-#######--------------------+++-..#########---+---.-++++-----++++\n+------------+####+-##############++#######------------------+++-.-##############+++-.-----------+++\n+............-####+############+###+-++#+##--....-.....-##-++..-############+..............---------\n+++++-.-------##############################-..-.##+++#######--+#####++####--++++-++--+------.---+--\n+++++-.-------+###############+#############----+##################+++#+--.+##+-----++++++++-.-+++++\n+--++-.-------##################################++############+######+####+#####+--+###+++++---+++++\n+--++-.-----.##############################################################--++++++++---++---.--++++\n+----....-..-###+-#.+#########-#--+##############################+#########++++#+----..-----...-----\n+--++++++----###+-#+-########-+##+-##############################################--+++--------------\n+---++++++---#####+++########+---+#############################################++--###+-------++++++\n+---+--+++----#####################################+#########################+.+##---.---------+++++\n+------++++++++++####+---+#####################################################+--+##.----------+++-\n+---......---++++######+#############################################+######+####-....--..........--\n+++++-.-++----+#++#####++############+##########################################--.###++--++-.--++++\n#++++------+#+-++--.-##############################################################+++..-----.-+++++\n+-+++-.--++---++-----..-+########################################+####################--+----.--++++\n+--+-----------------..-+################################+############################+.-+---.---+++\n+..-...................-###############+###############++##############################--.......----\n++++++++++++--.----------#############+################+########################++####++------++++++\n+-+++++++++++-.---------.-###########++###############+#######################-.-######-##+-++++++++\n+-----+++++++-.----------.-##########--##############################++###+------+#####-.+#+--++++-+\n+---------+---.-------------#########-+++###############+#############------------#####+-.------+++-\n+----........................+#####++++##############+-....-+#########+++-........#######++-......--\n+++++-.-------+++++++---------..+++###############+.----------...+######.----.-----######+--.-++++++\n+++++----------++++++-.-----.--###################...---++++++++--######++++------.#########-.--++++\n+-+++-.----------++++-.--.-#######################+-------++++++--+#####+------+++--+#####+-.----+++\n+----------------------+#######################+-..----------++----#######--------+---..-----.------\n+------------..---..-###################+++####-...------......-...+#######--.................------\n+--+++++++++--.---+#################---++####+-.-----+++++++-.-----.-#####-.-+++++++-.-++++++++++++-\n#---+++++++++-.-###############-...-########+---------++++++-.-------......--+++++++-.----+++++++++-\n#------+++--+##############+------+#########+.----------++++------------------++++++-.------+++++++-\n+----------######+#######---------#######++--.----------------------------------++++-.----+-----+++-\n+---......+#+##++######--.......-########+++--..-..............................................-----\n+++++-.---.-+##+####+.--+-------#######+--++++++++++-.         BUGCAT CODEX: COMPLETE        .-+++++\n+-+++-.--------..-----.-----+-+#######-.---+++++++++-. [reentrancy] [predictable] [overflow] .--++++\n+--++------------++++-.------+#######+---------+++++-.      [unprotected] [misspelled]       .---+++\n+-----.---------------.----+########+.---------------.          All wounds witnessed.        .------\n+------------..-------.+###########-..........................................--.............-------\n++-++++++++++-.---+--.############-.--++++++-.---+++++++++++-.-----+++++++++---+++++++++++++++++++++\n#+--+++++++++-.------.##########-.---+++++++-.-------+++++++-.-------+++++++---+++++----++++++++++++\n#+--+++++++++-.----++----++-------+++--------.---------++++--.----------++++---++++-------++++++++++";
        specialCodeDark = "-+---+#++++++++-----++#+++-++++-----++++++++--------+#+++++++---+++#+. .......+###++++------+#+++---\n-+---+#++++++#+++---++#++++++++++--++#+#-++++++++++-+#+++++++++--++##. .   .  +#+..++++++---+#++++++\n-+++++##++++#-..-##########+++++++++++.. .+++++++++++#+++++++++..-###-   ..   +####+...+++++###+++++\n-++---+++++++- ...-++++++++++#+++++#-.... -#+++++++++++++++++#+++++-.. ...    +--##+-+++++++++++++++\n.++--------++-...--.-#+++++++#++++-...--.. #++++++++--------+#+--++...     .++#++++++#++++++++------\n.++++++-----+-...---. -+++++----+..+.....  ++++++++++++++++++++---+##. ..  .  +++-+++#+----+++++----\n-++++++++++++- ...-+....... .  ...--.....  ++++++++++++++++++---+#+.... .........---+#+++++++++++---\n-############+. ..-.. .. .... .-...-+--.-. ++####+#####+..+--##+.......  ...-##############+++++++++\n-----+#+++++++....  .. ........... ......  .+##+#..---.......++- ....--....++----+--++-++++++#+++-++\n-----+#+++++++-..  .  .... ...-........ ....++++-..     ....... ...---.-++#-..-+++++--------+#+-----\n-++--+#+++++++. ..       ......  ........  . ...--  ..... .. .-... ..-....-.....-++-...-----+++-----\n-++--+#+++++#-  .... .   ..    ...   ..  . ...    .  .....       .....  ...++--------+++--+++#++----\n-++++####+##+. .-+.#-   .    .+.++-...  ......    ........      .-..  .....----.-++++##+++++###+++++\n-++------++++.  -+.-+.  ..  .+-..-+...   .....  . .......    ....      ........ .++---++++++++++++++\n-+++------+++.   .---. .... .-+++-   ........  ....  .......     ..    .....  .--++...-+++++++------\n-+++-++---++++ ..............  ...  ... .....  ....-.........  ....  ...  .  -#-..+++#+++++++++-----\n-++++++----------.  .-+++- .  ........  ...  . ..... ....   ...    ....  ..    -++-..#++++++++++---+\n-+++######+++----.... .-...................  .  ...  .... ..  ...  ..-......-... +####++##########++\n-----+#+--++++-.--.....--... ........-.  .      ....... . ..  ..     ..... ..  .++#...--++--+#++----\n.----++++++-.-+--++#+... ...    .....   .     ..  .      .......          .........---##+++++#+-----\n-+---+#++--+++--+++++##+-......   ....        ... ..... .....   .-.      ..  .... ....++-++++#++----\n-++-+++++++++++++++++##+-.             .       .... ..  .-..            ....  .  .....-#+-+++#+++---\n-##+###################+...  .  ..    .-.  .....   ....--.. .. ...        .  ....     .++#######++++\n------------++#++++++++++... ... .   .-. .......  ... .-. ....     .....     ...--.   --++++++------\n-+-----------+#+++++++++#+...........--.... ..      ..-.  ..     ..     ... ..+#+.  ...+..-+--------\n-+++++-------+#++++++++++#+........ .++. ..        ....   .      .. .--...-++++++-.   .+#-.-++----+-\n-+++++++++-+++#+++++++++++++. ..    .+---...  ......  ..-.....  .    .++++++++++++ ... -+#++++++---+\n-++++########################-.  ..----....  .  .....-+####+-.   ... .---+########.    ..--+######++\n-----+#+++++++-------+++++++++##---...   ...   .. -#++++++++++###-  .  .#++++#+++++     .-++#+------\n-----++++++++++------+#+++++#++. ..... ...    ....###+++--------++..   .----++++++#.  ... ..+#++----\n-+---+#++++++++++----+#++#+.. . ..........  ......-+++++++------++-.    -++++++---++-   ..-+#++++---\n-++++++++++++++++++++++-...         . .. ......-+##++++++++++--++++.   ...++++++++-+++##+++++#++++++\n-++++++++++++##+++##+............ ......---....+###++++++######+###-   ....++#################++++++\n-++---------++#+++-....     .   ....+++--. . -+#+++++-------+#+++++#+.. ..+#+-------+#+------------+\n.+++---------+#+.  .. ... .. ..+###+..     .-+++++++++------+#+++++++######++-------+#++++---------+\n.++++++---++-........  .  .-+++++++.....   .-#++++++++++----++++++++++++++++++------+#++++++-------+\n-++++++++++......- .    .+++++++++. ..  .--+##++++++++++++++++++++++++++++++++++----+#++++-+++++---+\n-+++######-.-. --.  ...++#######+.....  .---++##+##############################################+++++\n-----+#+++#+-..-.. .-#++-+++++++ .. .  -++----------+#         BUGCAT CODEX: COMPLETE        #+----+\n-+---+#++++++++##+++++#+++++-+-....  .+#+++---------+# [reentrancy] [predictable] [overflow] #++----\n-++--++++++++++++----+#++++++-..   ..-+++++++++-----+#      [unprotected] [misspelled]       #+++---\n-+++++#+++++++++++++++#++++-.    ...-#+++++++++++++++#          All wounds witnessed.        #++++++\n-++++++++++++##+++++++#-.... .   ..+##########################################++#############+++++++\n--+----------+#+++-++#............+#++------+#+++-----------+#+++++---------+++---------------------\n.-++---------+#++++++#.......  .+#+++-------+#+++++++-------+#+++++++-------+++-----++++------------\n.-++--------++#++++--++++--+++++++---++++++++#+++++++++----++#++++++++++----+++----+++++++----------";
    }

    function renderImage(uint256 tokenId, address caretaker, uint8 bugcatIndex, string memory code, bool light, bool compiled) external view returns (string memory) {
        address bugcat = bugcatRegistry.bugs(bugcatIndex);
        string memory svg = _generateSvg(tokenId, caretaker, bugcat, code, light, compiled);
        return string.concat("data:image/svg+xml;base64,", Base64.encode(bytes(svg)));
    }

    function renderAnimationUrl(uint256 tokenId, address caretaker, uint8 bugcatIndex, string memory code, bool light, bool compiled, uint8[] memory preservedBugcatIndexes) external view returns (string memory) {
        address bugcat = bugcatRegistry.bugs(bugcatIndex);
        string memory svg = _generateSvg(tokenId, caretaker, bugcat, code, light, compiled);
        string memory certificateSvg = _generateCertificateSvg(tokenId, caretaker, preservedBugcatIndexes, light);
        return _wrapInInteractiveHtml(svg, certificateSvg, light);
    }

    function _generateSvg(uint256 tokenId, address caretaker, address bugcat, string memory code, bool light, bool compiled) internal view returns (string memory) {
        string memory bgColor = light ? "#f5f5f5" : "#0a0a0a";
        string memory boxBgColor = light ? "#ffffff" : "#1a1a1a";
        string memory textColor = light ? "#3a3a3a" : "#e0e0e0";
        string memory hlBg = light ? "#dddddd" : "#444444";

        string memory bytecode = LibString.toHexString(bugcat.code);
        string memory content = compiled ? _twoColsAutoHighlight(bytecode) : _escapeHtml(code);
        string memory comment = compiled ? "" : string.concat("<!-- ", bytecode, " -->");
        
        return string.concat(
            "<svg width=\"100%\" height=\"100%\" viewBox=\"0 0 1000 1000\" preserveAspectRatio=\"xMidYMid meet\" style=\"background-color: ", bgColor, "\" xmlns=\"http://www.w3.org/2000/svg\">",
            "<defs><style>\n",
            ".header { font-family: monospace; font-size: 17px; line-height: 1.0; letter-spacing: 0.01em; white-space: pre-wrap; word-break: break-all; overflow: hidden; height: 100%; color: ", textColor, "; }\n",
            ".code { font-family: monospace; font-size: 17px; line-height: 1.3; letter-spacing: 0.1em; white-space: pre-wrap; word-break: break-all; overflow: hidden; height: 100%; color: ", textColor, "; }\n",
            ".cols { display: flex; gap: 28px; }\n",
            ".col { flex: 1 1 0; }\n",
            ".hl { background:", hlBg, "; padding: 0 2px; border-radius: 2px; }\n",
            "</style></defs>",
            "<rect width=\"1000\" height=\"1000\" fill=\"", boxBgColor, "\"/>",
            _getHeader(tokenId, caretaker),
            "<foreignObject x=\"60\" y=\"220\" width=\"880\" height=\"790\">",
            "<div xmlns=\"http://www.w3.org/1999/xhtml\" class=\"code\">",
            content,
            "</div></foreignObject>",
            comment,
            "</svg>"
        );
    }

    function _generateCertificateSvg(
        uint256 tokenId,
        address caretaker,
        uint8[] memory preservedBugcatIndexes,
        bool light
    ) internal view returns (string memory) {
        string memory bgColor = light ? "#f5f5f5" : "#0a0a0a";
        string memory boxBgColor = light ? "#ffffff" : "#1a1a1a";
        string memory textColor = light ? "#3a3a3a" : "#e0e0e0";

        string memory content;
        if (preservedBugcatIndexes.length == 5) {
            content = light ? specialCodeLight : specialCodeDark;
        } else {
            content = _buildIncompleteMessage(preservedBugcatIndexes);
        }

        return string.concat(
            "<svg width=\"100%\" height=\"100%\" viewBox=\"0 0 1000 1000\" preserveAspectRatio=\"xMidYMid meet\" style=\"background-color: ", bgColor, "\" xmlns=\"http://www.w3.org/2000/svg\">",
            "<defs><style>\n",
            ".header { font-family: monospace; font-size: 17px; line-height: 1.0; letter-spacing: 0.01em; white-space: pre-wrap; word-break: break-all; overflow: hidden; height: 100%; color: ", textColor, "; }\n",
            ".message { font-family: monospace; font-size: 17px; line-height: 0.95; letter-spacing: 0.01em; white-space: pre-wrap; word-break: break-all; overflow: hidden; height: 100%; color: ", textColor, "; }\n",
            "</style></defs>",
            "<rect width=\"1000\" height=\"1000\" fill=\"", boxBgColor, "\"/>",
            _getHeader(tokenId, caretaker),
            "<foreignObject x=\"60\" y=\"220\" width=\"880\" height=\"790\">",
            "<div xmlns=\"http://www.w3.org/1999/xhtml\" class=\"message\">",
            content,
            "</div></foreignObject>",
            "</svg>"
        );
    }

    function _getHeader(uint256 tokenId, address caretaker) internal view returns (string memory) {
        string memory caretakerStr;
        try ENSResolver.resolveAddress(caretaker) returns (string memory nameOrAddr) {
            caretakerStr = nameOrAddr;
        } catch {
            caretakerStr = LibString.toHexStringChecksummed(caretaker);
        }
        return string.concat(
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
            "</div></foreignObject>"
        );
    }

    function _buildIncompleteMessage(uint8[] memory preservedBugcatIndexes) internal view returns (string memory) {
        string memory statusLine = "";
        
        for (uint i = 0; i < 5; i++) {
            bool hasThisBugcat = false;
            string memory woundName = "";

            for (uint j = 0; j < preservedBugcatIndexes.length; j++) {
                if (preservedBugcatIndexes[j] == i) {
                    hasThisBugcat = true;
                    address bugcat = bugcatRegistry.bugs(i);
                    woundName = _extractWoundFromBytecode(bugcat);
                    break;
                }
            }
            
            woundName = hasThisBugcat ? woundName : "----------";
            statusLine = string.concat(statusLine, "[", woundName, "]");

            if (i < 4) {
                statusLine = string.concat(statusLine, " ");
            }
        }
        
        return string.concat(
            "BUGCAT CODEX: INCOMPLETE\n\n",
            statusLine,
            "\n\nSome wounds witnessed. The Codex remembers you."
        );
    }

    function _buildWoundsList(uint8[] memory preservedBugcatIndexes) internal view returns (string memory) {
        string memory result = "";
        for (uint i = 0; i < preservedBugcatIndexes.length; i++) {
            uint8 bugcatIndex = preservedBugcatIndexes[i];
            address bugcat = bugcatRegistry.bugs(bugcatIndex);
            string memory wound = _extractWoundFromBytecode(bugcat);
            result = string.concat(
                result,
                "<tspan x=\"100\" dy=\"25\">[x] I remember ", wound, " cat and its wound</tspan>"
            );
        }
        return result;
    }

    function _extractWoundFromBytecode(address bugcat) internal view returns (string memory) {
        bytes memory bytecode = bugcat.code;
        if (bytecode.length == 0) return "n/a";
        (bool found, string memory catName) = _extractFromPushInstructions(bytecode);
        if (found) {
            return catName;
        }
        catName = _findLongestValidString(bytecode);
        if (bytes(catName).length > 0) {
            return catName;
        }
        return "n/a";
    }

    function _extractFromPushInstructions(bytes memory bytecode) internal pure returns (bool found, string memory result) {
        uint256 bestScore = 0;
        bytes memory bestCandidate;
        
        uint256 pc = 0;
        while (pc < bytecode.length) {
            uint8 opcode = uint8(bytecode[pc]);
            if (opcode >= 0x60 && opcode <= 0x7f) {
                uint256 pushSize = opcode - 0x5f;
                if (pc + pushSize < bytecode.length) {
                    bytes memory data = new bytes(pushSize);
                    for (uint256 i = 0; i < pushSize; i++) {
                        data[i] = bytecode[pc + 1 + i];
                    }
                    if (_isValidWoundString(data)) {
                        uint256 score = pushSize * 10 + 100;
                        if (score > bestScore) {
                            bestScore = score;
                            bestCandidate = data;
                        }
                    }
                }
                pc += 1 + pushSize;
            } else {
                pc++;
            }
        }
        if (bestScore > 0) {
            return (true, string(bestCandidate));
        }

        return (false, "");
    }

    function _findLongestValidString(bytes memory bytecode) internal pure returns (string memory) {
        uint256 bestLength = 0;
        uint256 bestStart = 0;
        for (uint256 i = 0; i < bytecode.length; i++) {
            if (bytecode[i] >= 0x61 && bytecode[i] <= 0x7a) {
                uint256 start = i;
                uint256 end = i + 1;

                while (end < bytecode.length && bytecode[end] >= 0x61 && bytecode[end] <= 0x7a) {
                    end++;
                }
                
                uint256 length = end - start;
                
                if (length >= 6 && length <= 15 && length > bestLength) {
                    bytes memory candidate = new bytes(length);
                    for (uint256 j = 0; j < length; j++) {
                        candidate[j] = bytecode[start + j];
                    }
                    
                    if (_isValidWord(candidate)) {
                        bestLength = length;
                        bestStart = start;
                    }
                }
                
                i = end - 1;
            }
        }

        if (bestLength > 0) {
            bytes memory result = new bytes(bestLength);
            for (uint256 i = 0; i < bestLength; i++) {
                result[i] = bytecode[bestStart + i];
            }
            return string(result);
        }
        
        return "";
    }

    function _isValidWoundString(bytes memory data) internal pure returns (bool) {
        if (data.length < 6 || data.length > 15) return false;
        
        for (uint256 i = 0; i < data.length; i++) {
            uint8 b = uint8(data[i]);
            
            if (b == 0x60) return false;
            
            if (b == 0x20) return false;
            
            if (b < 0x20 || b > 0x7e) return false;
        }
        
        bool allLowercase = true;
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] < 0x61 || data[i] > 0x7a) {
                allLowercase = false;
                break;
            }
        }
        
        if (allLowercase) {
            return _hasReasonableVowels(data);
        }
        
        return false;
    }

    function _isValidWord(bytes memory data) internal pure returns (bool) {
        bool hasVowel = false;
        uint256 consonantStreak = 0;
        uint256 maxConsonantStreak = 0;
        
        for (uint256 i = 0; i < data.length; i++) {
            uint8 b = uint8(data[i]);
            
            if (b == 0x61 || b == 0x65 || b == 0x69 || b == 0x6f || b == 0x75) {
                hasVowel = true;
                consonantStreak = 0;
            } else {
                consonantStreak++;
                if (consonantStreak > maxConsonantStreak) {
                    maxConsonantStreak = consonantStreak;
                }
            }
        }
        
        return hasVowel && maxConsonantStreak <= 4;
    }

    function _hasReasonableVowels(bytes memory data) internal pure returns (bool) {
        uint256 vowelCount = 0;
        
        for (uint256 i = 0; i < data.length; i++) {
            uint8 b = uint8(data[i]);
            if (b == 0x61 || b == 0x65 || b == 0x69 || b == 0x6f || b == 0x75) {
                vowelCount++;
            }
        }
        
        return vowelCount > 0 && vowelCount * 100 / data.length <= 60;
    }

    function _containsPattern(bytes memory haystack, bytes memory needle) internal pure returns (bool) {
        if (needle.length == 0 || needle.length > haystack.length) {
            return false;
        }
        
        for (uint256 i = 0; i <= haystack.length - needle.length; i++) {
            bool matched = true;
            for (uint256 j = 0; j < needle.length; j++) {
                if (haystack[i + j] != needle[j]) {
                    matched = false;
                    break;
                }
            }
            if (matched) {
                return true;
            }
        }
        
        return false;
    }

    function _wrapInInteractiveHtml(string memory originalSvg, string memory certificateSvg, bool light) internal pure returns (string memory) {
        string memory bgColor = light ? "#f5f5f5" : "#0a0a0a";
        string memory html = string.concat(
            "data:text/html;base64,",
            Base64.encode(bytes(string.concat(
                "<!DOCTYPE html><html><head><style>",
                "body{margin:0;background:", bgColor, ";overflow:hidden;cursor:pointer;}",
                ".view{position:absolute;width:100%;height:100%;display:flex;justify-content:center;align-items:center;transition:opacity 0.3s;}",
                "#cert{opacity:0;pointer-events:none;}",
                "body.show-cert #orig{opacity:0;pointer-events:none;}",
                "body.show-cert #cert{opacity:1;pointer-events:all;}",
                "</style></head><body onclick=\"document.body.classList.toggle('show-cert')\">",
                "<div id=\"orig\" class=\"view\">", originalSvg, "</div>",
                "<div id=\"cert\" class=\"view\">", certificateSvg, "</div>",
                "</body></html>"
            )))
        );
        return html;
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
            if (i + 2 < hexLen) out[idx++] = 0x20;
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
