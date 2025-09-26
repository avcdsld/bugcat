const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("Generating all SVG combinations...");

    const [owner] = await ethers.getSigners();
    
    // 実際のレジストリアドレスを使用
    const REGISTRY_ADDRESS = "0x652f57021b4d39223e3769021a7d3edf01a1139e";
    const bugcatCount = 5;

    // ENSResolverをデプロイ
    const ENSResolver = await ethers.getContractFactory("ENSResolver");
    const ensResolver = await ENSResolver.deploy();

    // BugcatCodexRendererをデプロイ
    const BugcatCodexRenderer = await ethers.getContractFactory("BugcatCodexRenderer", {
        libraries: {
            ENSResolver: ensResolver.target
        }
    });
    const specialCodeLight = "+-+++-.--------+++++--.---+----+++++--------++++++++-.-------+++---.-#########-...----++++++-.---+++\n+-+++-.------.---+++--.----------++--.-.+----------+-.---------++--..#########-.-##------+++-.----+-\n+-----..----.+##+..........-----------####-----------.---------##+...+########-....-###-----...-----\n+--+++-------+####+----------.-----.+#####+.-----------------.-----+##########-++..-+---------------\n#--++++++++--+###++#+.-------.----+###++###.--------++++++++-.-++--#########--.------.--------++++++\n#------+++++-+###+++##+-----++++-##-#######--------------------+++-..#########---+---.-++++-----++++\n+------------+####+-##############++#######------------------+++-.-##############+++-.-----------+++\n+............-####+############+###+-++#+##--....-.....-##-++..-############+..............---------\n+++++-.-------##############################-..-.##+++#######--+#####++####--++++-++--+------.---+--\n+++++-.-------+###############+#############----+##################+++#+--.+##+-----++++++++-.-+++++\n+--++-.-------##################################++############+######+####+#####+--+###+++++---+++++\n+--++-.-----.##############################################################--++++++++---++---.--++++\n+----....-..-###+-#.+#########-#--+##############################+#########++++#+----..-----...-----\n+--++++++----###+-#+-########-+##+-##############################################--+++--------------\n+---++++++---#####+++########+---+#############################################++--###+-------++++++\n+---+--+++----#####################################+#########################+.+##---.---------+++++\n+------++++++++++####+---+#####################################################+--+##.----------+++-\n+---......---++++######+#############################################+######+####-....--..........--\n+++++-.-++----+#++#####++############+##########################################--.###++--++-.--++++\n#++++------+#+-++--.-##############################################################+++..-----.-+++++\n+-+++-.--++---++-----..-+########################################+####################--+----.--++++\n+--+-----------------..-+################################+############################+.-+---.---+++\n+..-...................-###############+###############++##############################--.......----\n++++++++++++--.----------#############+################+########################++####++------++++++\n+-+++++++++++-.---------.-###########++###############+#######################-.-######-##+-++++++++\n+-----+++++++-.----------.-##########--##############################++###+------+#####-.+#+--++++-+\n+---------+---.-------------#########-+++###############+#############------------#####+-.------+++-\n+----........................+#####++++##############+-....-+#########+++-........#######++-......--\n+++++-.-------+++++++---------..+++###############+.----------...+######.----.-----######+--.-++++++\n+++++----------++++++-.-----.--###################...---++++++++--######++++------.#########-.--++++\n+-+++-.----------++++-.--.-#######################+-------++++++--+#####+------+++--+#####+-.----+++\n+----------------------+#######################+-..----------++----#######--------+---..-----.------\n+------------..---..-###################+++####-...------......-...+#######--.................------\n+--+++++++++--.---+#################---++####+-.-----+++++++-.-----.-#####-.-+++++++-.-++++++++++++-\n#---+++++++++-.-###############-...-########+---------++++++-.-------......--+++++++-.----+++++++++-\n#------+++--+##############+------+#########+.----------++++------------------++++++-.------+++++++-\n+----------######+#######---------#######++--.----------------------------------++++-.----+-----+++-\n+---......+#+##++######--.......-########+++--..-..............................................-----\n+++++-.---.-+##+####+.--+-------#######+--++++++++++-.         BUGCAT CODEX: COMPLETE        .-+++++\n+-+++-.--------..-----.-----+-+#######-.---+++++++++-. [reentrancy] [predictable] [overflow] .--++++\n+--++------------++++-.------+#######+---------+++++-.      [unprotected] [misspelled]       .---+++\n+-----.---------------.----+########+.---------------.          All wounds witnessed.        .------\n+------------..-------.+###########-..........................................--.............-------\n++-++++++++++-.---+--.############-.--++++++-.---+++++++++++-.-----+++++++++---+++++++++++++++++++++\n#+--+++++++++-.------.##########-.---+++++++-.-------+++++++-.-------+++++++---+++++----++++++++++++\n#+--+++++++++-.----++----++-------+++--------.---------++++--.----------++++---++++-------++++++++++";
    
    const specialCodeDark = "-+---+#++++++++-----++#+++-++++-----++++++++--------+#+++++++---+++#+. .......+###++++------+#+++---\n-+---+#++++++#+++---++#++++++++++--++#+#-++++++++++-+#+++++++++--++##. .   .  +#+..++++++---+#++++++\n-+++++##++++#-..-##########+++++++++++.. .+++++++++++#+++++++++..-###-   ..   +####+...+++++###+++++\n-++---+++++++- ...-++++++++++#+++++#-.... -#+++++++++++++++++#+++++-.. ...    +--##+-+++++++++++++++\n.++--------++-...--.-#+++++++#++++-...--.. #++++++++--------+#+--++...     .++#++++++#++++++++------\n.++++++-----+-...---. -+++++----+..+.....  ++++++++++++++++++++---+##. ..  .  +++-+++#+----+++++----\n-++++++++++++- ...-+....... .  ...--.....  ++++++++++++++++++---+#+.... .........---+#+++++++++++---\n-############+. ..-.. .. .... .-...-+--.-. ++####+#####+..+--##+.......  ...-##############+++++++++\n-----+#+++++++....  .. ........... ......  .+##+#..---.......++- ....--....++----+--++-++++++#+++-++\n-----+#+++++++-..  .  .... ...-........ ....++++-..     ....... ...---.-++#-..-+++++--------+#+-----\n-++--+#+++++++. ..       ......  ........  . ...--  ..... .. .-... ..-....-.....-++-...-----+++-----\n-++--+#+++++#-  .... .   ..    ...   ..  . ...    .  .....       .....  ...++--------+++--+++#++----\n-++++####+##+. .-+.#-   .    .+.++-...  ......    ........      .-..  .....----.-++++##+++++###+++++\n-++------++++.  -+.-+.  ..  .+-..-+...   .....  . .......    ....      ........ .++---++++++++++++++\n-+++------+++.   .---. .... .-+++-   ........  ....  .......     ..    .....  .--++...-+++++++------\n-+++-++---++++ ..............  ...  ... .....  ....-.........  ....  ...  .  -#-..+++#+++++++++-----\n-++++++----------.  .-+++- .  ........  ...  . ..... ....   ...    ....  ..    -++-..#++++++++++---+\n-+++######+++----.... .-...................  .  ...  .... ..  ...  ..-......-... +####++##########++\n-----+#+--++++-.--.....--... ........-.  .      ....... . ..  ..     ..... ..  .++#...--++--+#++----\n.----++++++-.-+--++#+... ...    .....   .     ..  .      .......          .........---##+++++#+-----\n-+---+#++--+++--+++++##+-......   ....        ... ..... .....   .-.      ..  .... ....++-++++#++----\n-++-+++++++++++++++++##+-.             .       .... ..  .-..            ....  .  .....-#+-+++#+++---\n-##+###################+...  .  ..    .-.  .....   ....--.. .. ...        .  ....     .++#######++++\n------------++#++++++++++... ... .   .-. .......  ... .-. ....     .....     ...--.   --++++++------\n-+-----------+#+++++++++#+...........--.... ..      ..-.  ..     ..     ... ..+#+.  ...+..-+--------\n-+++++-------+#++++++++++#+........ .++. ..        ....   .      .. .--...-++++++-.   .+#-.-++----+-\n-+++++++++-+++#+++++++++++++. ..    .+---...  ......  ..-.....  .    .++++++++++++ ... -+#++++++---+\n-++++########################-.  ..----....  .  .....-+####+-.   ... .---+########.    ..--+######++\n-----+#+++++++-------+++++++++##---...   ...   .. -#++++++++++###-  .  .#++++#+++++     .-++#+------\n-----++++++++++------+#+++++#++. ..... ...    ....###+++--------++..   .----++++++#.  ... ..+#++----\n-+---+#++++++++++----+#++#+.. . ..........  ......-+++++++------++-.    -++++++---++-   ..-+#++++---\n-++++++++++++++++++++++-...         . .. ......-+##++++++++++--++++.   ...++++++++-+++##+++++#++++++\n-++++++++++++##+++##+............ ......---....+###++++++######+###-   ....++#################++++++\n-++---------++#+++-....     .   ....+++--. . -+#+++++-------+#+++++#+.. ..+#+-------+#+------------+\n.+++---------+#+.  .. ... .. ..+###+..     .-+++++++++------+#+++++++######++-------+#++++---------+\n.++++++---++-........  .  .-+++++++.....   .-#++++++++++----++++++++++++++++++------+#++++++-------+\n-++++++++++......- .    .+++++++++. ..  .--+##++++++++++++++++++++++++++++++++++----+#++++-+++++---+\n-+++######-.-. --.  ...++#######+.....  .---++##+##############################################+++++\n-----+#+++#+-..-.. .-#++-+++++++ .. .  -++----------+#         BUGCAT CODEX: COMPLETE        #+----+\n-+---+#++++++++##+++++#+++++-+-....  .+#+++---------+# [reentrancy] [predictable] [overflow] #++----\n-++--++++++++++++----+#++++++-..   ..-+++++++++-----+#      [unprotected] [misspelled]       #+++---\n-+++++#+++++++++++++++#++++-.    ...-#+++++++++++++++#          All wounds witnessed.        #++++++\n-++++++++++++##+++++++#-.... .   ..+##########################################++#############+++++++\n--+----------+#+++-++#............+#++------+#+++-----------+#+++++---------+++---------------------\n.-++---------+#++++++#.......  .+#+++-------+#+++++++-------+#+++++++-------+++-----++++------------\n.-++--------++#++++--++++--+++++++---++++++++#+++++++++----++#++++++++++----+++----+++++++----------";
    const renderer = await BugcatCodexRenderer.deploy(REGISTRY_ADDRESS, specialCodeLight, specialCodeDark);

    // レジストリコントラクトを取得
    const registry = new ethers.Contract(
        REGISTRY_ADDRESS,
        ["function bugs(uint256) external view returns (address)"],
        ethers.provider
    );

    // 出力ディレクトリを作成
    const outputDir = path.join(__dirname, "../generated-svgs");
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    // 各BUGCATのソースコード
    const sourceCodes = [
        `// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import "../interface/BugCat.sol";

contract ReentrancyCat is BugCat {
    mapping(address => uint) public balance;

    function deposit() public payable {
        balance[msg.sender] += msg.value;
    }

    function withdraw() public {
        (bool success, ) = msg.sender.call{value: balance[msg.sender]}("");
        require(success);
        balance[msg.sender] = 0;
    }

    function caress() public {
        if (address(this).balance == 0) {
            emit Meow(msg.sender, "reentrancy");
        }
    }

    function remember() external view returns (bool) {
        address TheDAO = 0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413;
        return TheDAO.code.length > 0;
    }
}`,
        `// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

import "../interface/BugCat.sol";

contract PredictableCat is BugCat {
    mapping(address => uint8) public winCount;

    function flip() external {
        if ((uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender
        ))) & 1) == 0) {
            winCount[msg.sender] += 1;
        } else {
            winCount[msg.sender] = 0;
        }
    }

    function caress() public {
        if (winCount[msg.sender] >= 10) {
            emit Meow(msg.sender, "predictable");
            winCount[msg.sender] = 0;
        }
    }

    function remember() external view returns (bool) {
        address FoMo3Dlong = 0xA62142888ABa8370742bE823c1782D17A0389Da1;
        return FoMo3Dlong.code.length > 0;
    }
}`,
        `// SPDX-License-Identifier: WTFPL
pragma solidity ^0.4.26;

import "../interface/BugCat.sol";

contract OverflowCat is BugCat {
    mapping(address => uint) public balance;

    function batchTransfer(address[] memory _receivers, uint256 _value) public {
        uint count = _receivers.length;
        uint amount = count * _value;
        require(_value > 0 && balance[msg.sender] >= amount);
        balance[msg.sender] -= amount;
        for (uint i = 0; i < count; i++) {
            balance[_receivers[i]] += _value;
        }
    }

    function caress() public {
        if (balance[msg.sender] > 0) {
            emit Meow(msg.sender, "overflow");
        }
    }

    function remember() external view returns (bool) {
        address BecToken = 0xC5d105E63711398aF9bbff092d4B6769C82F793D;
        uint256 size; assembly { size := extcodesize(BecToken) }
        return size > 0;
    }
}`,
        `// SPDX-License-Identifier: WTFPL
pragma solidity ^0.4.26;

import "../interface/BugCat.sol";

contract UnprotectedCat is BugCat {
    address public owner;
    bool public initialized;

    function init(address o) public {
        owner = o;
        initialized = true;
    }

    function kill() public {
        require(msg.sender == owner);
        suicide(owner);
    }

    function caress() public {
        if (msg.sender == owner) {
            emit Meow(msg.sender, "unprotected");
        }
    }

    function remember() external view returns (bool) {
        address WalletLibrary = 0x863DF6BFa4469f3ead0bE8f9F2AAE51c91A907b4;
        uint256 size; assembly { size := extcodesize(WalletLibrary) }
        return size == 0 && WalletLibrary.balance > 0;
    }
}`,
        `// SPDX-License-Identifier: WTFPL
pragma solidity ^0.4.26;

import "../interface/BugCat.sol";

contract MisspelledCat is BugCat {
    address public owner;

    function MisspeledCat(address o) {
        owner = o;
    }

    function caress() public {
        if (msg.sender == owner) {
            emit Meow(msg.sender, "misspelled");
        }
    }

    function remember() external view returns (bool) {
        address Rubixi = 0xe82719202e5965Cf5D9B6673B7503a3b92DE20be;
        uint256 size; assembly { size := extcodesize(Rubixi) }
        return size > 0;
    }
}`
    ];

    // 0〜4のBUGCATについて、light/dark、compiled有無の組み合わせを生成
    for (let tokenId = 0; tokenId < 5; tokenId++) {
        console.log(`\nGenerating SVGs and HTMLs for token ${tokenId}...`);
        
        try {
            // レジストリからBUGCATアドレスを取得
            const bugcatAddress = await registry.bugs(tokenId);
            console.log(`  BUGCAT ${tokenId} address: ${bugcatAddress}`);
            
            // BUGCATコントラクトのバイトコードを取得
            const bytecode = await ethers.provider.getCode(bugcatAddress);
            console.log(`  BUGCAT ${tokenId} bytecode length: ${bytecode.length}`);
            
            // ソースコードを取得
            const sourceCode = sourceCodes[tokenId];
            console.log(`  BUGCAT ${tokenId} source code length: ${sourceCode.length}`);
            
            // 各組み合わせを生成
            const combinations = [
                { light: true, compiled: false, suffix: "light-source", code: sourceCode },
                { light: true, compiled: true, suffix: "light-compiled", code: bytecode },
                { light: false, compiled: false, suffix: "dark-source", code: sourceCode },
                { light: false, compiled: true, suffix: "dark-compiled", code: bytecode }
            ];

            for (const combo of combinations) {
                try {
                    // レンダラーのrenderImage関数を直接呼び出し（SVG用）
                    const dataUri = await renderer.renderImage(
                        tokenId,
                        owner.address, // caretaker
                        tokenId, // bugcatIndex
                        combo.code, // code
                        combo.light, // light theme
                        combo.compiled // compiled
                    );
                    
                    // Base64デコードしてSVGを取得
                    const svgBase64 = dataUri.split(",")[1];
                    const svgString = Buffer.from(svgBase64, "base64").toString();
                    
                    // SVGファイル名を生成
                    const svgFilename = `token-${tokenId}-${combo.suffix}.svg`;
                    const svgFilepath = path.join(outputDir, svgFilename);
                    
                    // SVGファイルを保存
                    fs.writeFileSync(svgFilepath, svgString);
                    console.log(`  ✓ ${svgFilename}`);
                    
                    // animation_url用のHTMLを生成
                    try {
                        // 所有しているBUGCATインデックスを生成（現在のトークンを含む）
                        const preservedBugcatIndexes = [0, 3, 4];
                        // const preservedBugcatIndexes = [0, 1, 2, 3, 4];
                        
                        const animationDataUri = await renderer.renderAnimationUrl(
                            tokenId,
                            owner.address, // caretaker
                            tokenId, // bugcatIndex
                            combo.code, // code
                            combo.light, // light theme
                            combo.compiled, // compiled
                            preservedBugcatIndexes // specialCode
                        );
                        
                        // Base64デコードしてHTMLを取得
                        const htmlBase64 = animationDataUri.split(",")[1];
                        const htmlString = Buffer.from(htmlBase64, "base64").toString();
                        
                        // HTMLファイル名を生成
                        const htmlFilename = `token-${tokenId}-${combo.suffix}.html`;
                        const htmlFilepath = path.join(outputDir, htmlFilename);
                        
                        // HTMLファイルを保存
                        fs.writeFileSync(htmlFilepath, htmlString);
                        console.log(`  ✓ ${htmlFilename}`);
                        
                    } catch (htmlError) {
                        console.error(`  ✗ Error generating HTML for ${combo.suffix} token ${tokenId}:`, htmlError.message);
                    }
                    
                } catch (error) {
                    console.error(`  ✗ Error generating ${combo.suffix} for token ${tokenId}:`, error.message);
                }
            }
            
        } catch (error) {
            console.error(`  ✗ Error getting BUGCAT ${tokenId}:`, error.message);
        }
    }

    console.log(`\nAll SVGs and HTMLs generated in: ${outputDir}`);
    console.log("Total files expected: 40 (5 tokens × 4 combinations × 2 file types)");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
