// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface TheDAO {
    function proposals(uint256) external view returns (
        address recipient,
        uint256 amount,
        string memory description,
        uint256 votingDeadline,
        bool open,
        bool proposalPassed,
        bytes32 proposalHash,
        uint256 proposalDeposit,
        bool newCurator,
        uint256 yea,
        uint256 nay,
        address creator
    );
}

contract Render {
    TheDAO public dao;
    
    string constant THEdao_BYTECODE_FRAGMENT = "0x606060405236156100a75760e060020a60003504632e45c7af811461014457806343d7263f1461020c57806345323081146102a05780635c19a95c14610484578063625c17dd146104a45780636fcfff45146104aa578063758e57d0146104dd578063891bbf9f14610558578063a1d373d1146102a0578063be2290fe146105c7578063c91d951f14610152578063d71f2b411461078b578063e55cea0114610816578063ebef7432146108b9575b6101425b600160a060020a03331660009081526003602090815260408220548154600083815260202090815260408220600181015492909204851694909404915033600160a060020a031607";
    
    string constant VULNERABLE_CODE = "function withdrawRewardFor(address _account) returns(bool) {\n    /* ... */\n    // Here the vulnerability begins\n    withdrawalAccount.call.value(withdraw)(payOut);\n    // State update happens too late\n    totalRewardsPaid += withdraw;\n    return true;\n}";
    
    string constant SECURE_CODE = "function secureWithdrawRewardFor(address _account) returns(bool) {\n    /* ... */\n    // First record the change\n    uint amount = withdraw;\n    totalRewardsPaid += amount;\n    // Then release the funds\n    withdrawalAccount.call.value(amount)(payOut);\n    return true;\n}";

    constructor(address _dao) {
        dao = TheDAO(_dao);
    }

    function tokenURI(uint256 id, string memory wound) external view returns (string memory) {
        string memory scar = "proposal #59: ";
        try dao.proposals(59) returns (
            address, uint256, string memory desc, uint256, bool, bool, bytes32, uint256, bool, uint256, uint256, address
        ) {
            scar = string.concat(scar, desc);
        } catch {
            scar = string.concat(scar, "error: not found");
        }
        string memory svg = generateSVG(wound, scar);
        
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"ReentrancyCat #',
                Strings.toString(id),
                '","description":"A cat that calls again - tracing TheDAO reentrancy attack.",',
                '"image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '","animation_url":"data:text/html;base64,',
                Base64.encode(bytes(generateHTMLAnimation(wound, scar))),
                '"}'
            )))
        ));
    }

    function generateSVG(string memory wound, string memory scar) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' width='100%' height='100%' viewBox='0 0 300 300'>",
            "<style>@keyframes spin{from{transform:rotate(0)}to{transform:rotate(-360deg)}}",
            ".circle-text{font:12px monospace;fill:white}",
            ".center{font:16px monospace;fill:white;dominant-baseline:middle;text-anchor:middle}",
            ".spinning{animation:spin 10s linear infinite;transform-origin:center}</style>",
            "<rect width='100%' height='100%' fill='black'/>",
            "<circle cx='150' cy='150' r='100' fill='none' stroke='white' stroke-width='1'/>",
            "<defs><path id='circlePath' d='M150,150m0,-103a103,103 0 1,1 0,206a103,103 0 1,1 0,-206'/></defs>",
            "<text class='center' x='150' y='150'>", wound, "</text>",
            "<g class='spinning'><text class='circle-text'><textPath href='#circlePath'>", scar, "</textPath></text></g>",
            "</svg>"
        ));
    }
    
    function generateHTMLAnimation(string memory wound, string memory scar) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>ReentrancyCat</title>",
            "<style>",
            "body { margin: 0; padding: 0; background: #000; overflow: hidden; font-family: monospace; }",
            ".container { position: relative; width: 100vw; height: 100vh; }",
            ".bytecode-container { position: absolute; top: 0; left: 0; width: 100%; height: 80%; overflow: hidden; }",
            ".byte { position: absolute; color: #ff3333; font-size: 12px; transition: color 0.5s; }",
            ".byte.traced { color: #33ff33; }",
            ".cat { position: absolute; z-index: 10; font-size: 14px; }",
            ".code-panel { position: absolute; bottom: 20px; width: 80%; max-width: 600px; ",
            "left: 50%; transform: translateX(-50%); background: rgba(0,0,0,0.8); ",
            "padding: 15px; border-radius: 8px; color: #ff3333; transition: transform 0.6s; ",
            "transform-style: preserve-3d; cursor: pointer; }",
            ".code-panel.flipped { transform: translateX(-50%) rotateY(180deg); }",
            ".panel-front, .panel-back { backface-visibility: hidden; width: 100%; }",
            ".panel-back { position: absolute; top: 0; left: 0; transform: rotateY(180deg); ",
            "background: rgba(0,0,0,0.8); color: #33ff33; padding: 15px; border-radius: 8px; }",
            "pre { margin: 0; white-space: pre-wrap; }",
            ".wound { position: absolute; top: 20px; left: 50%; transform: translateX(-50%); ",
            "color: white; font-size: 18px; text-align: center; z-index: 20; }",
            "</style>",
            "</head><body>",
            "<div class='container' id='container'>",
            "<div class='bytecode-container' id='bytecode-container'></div>",
            "<div class='wound' id='wound'>", wound, "</div>",
            "<div class='code-panel' id='code-panel'>",
            "<div class='panel-front'><pre>", VULNERABLE_CODE, "</pre></div>",
            "<div class='panel-back'><pre>", SECURE_CODE, "</pre></div>",
            "</div>",
            "</div>",
            
            "<script>",
            "const bytecodeContainer = document.getElementById('bytecode-container');",
            "const codePanel = document.getElementById('code-panel');",
            "const bytecodeFragment = '", THEdao_BYTECODE_FRAGMENT, "';",
            "let byteElements = [];",
            "let catElement;",
            
            "function placeBytes() {",
            "  const containerWidth = bytecodeContainer.clientWidth;",
            "  const containerHeight = bytecodeContainer.clientHeight;",
            "  const charWidth = 15;", // 文字の幅
            "  const charHeight = 15;", // 文字の高さ
            "  const cols = Math.floor(containerWidth / charWidth);",
            "  const rows = Math.floor(containerHeight / charHeight);",
            "  const totalCells = cols * rows;",
            "  const padding = 2;",
            
            "  for (let i = 2; i < bytecodeFragment.length; i += 2) {", // 0xをスキップ
            "    if ((i-2)/2 < totalCells) {", // 画面内に収まる分だけ表示
            "      const row = Math.floor(((i-2)/2) / cols);",
            "      const col = ((i-2)/2) % cols;",
            "      const byte = document.createElement('div');",
            "      byte.className = 'byte';",
            "      byte.textContent = bytecodeFragment.substr(i, 2);",
            "      byte.style.left = (col * charWidth + padding) + 'px';",
            "      byte.style.top = (row * charHeight + padding) + 'px';",
            "      byte.id = 'byte-' + (i-2);",
            "      bytecodeContainer.appendChild(byte);",
            "      byteElements.push({",
            "        element: byte,",
            "        row: row,",
            "        col: col",
            "      });",
            "    }",
            "  }",
            "  return {cols: cols, rows: rows, charWidth: charWidth, charHeight: charHeight};",
            "}",
            
            "function createCat() {",
            "  catElement = document.createElement('div');",
            "  catElement.className = 'cat';",
            "  catElement.textContent = '", unicode"🐾", "';",
            "  catElement.style.left = '5px';",
            "  catElement.style.top = '5px';",
            "  container.appendChild(catElement);",
            "  return catElement;",
            "}",
            
            "function animateCat() {",
            "  if (!catElement) catElement = createCat();",
            "  const gridInfo = placeBytes();",
            "  const cols = gridInfo.cols;",
            "  const rows = gridInfo.rows;",
            "  const charWidth = gridInfo.charWidth;",
            "  const charHeight = gridInfo.charHeight;",
            
            "  let x = 0;",
            "  let y = 0;",
            "  let direction = 'right';", // 初期方向
            "  let attackCounter = 0;", // 再入攻撃のカウンター
            
            "  const moveInterval = setInterval(() => {",
            "    catElement.style.left = (x * charWidth) + 'px';",
            "    catElement.style.top = (y * charHeight) + 'px';",
            
            "    const byteIndex = y * cols + x;",
            "    if (byteIndex < byteElements.length) {",
            "      byteElements[byteIndex].element.classList.add('traced');",
            "    }",
            
            "    attackCounter++;",
            
            "    if (attackCounter % 15 === 0 && attackCounter > 20) {", // 定期的に再入攻撃パターン
            "      const stepsBack = Math.min(10, x);", // 最大10ステップ戻る、ただし画面左端を超えない
            "      x = Math.max(0, x - stepsBack);", // 左に戻る
            "    } else {",
            "      if (direction === 'right') {",
            "        x++;",
            "        if (x >= cols - 1) {", // 右端に到達
            "          direction = 'down';",
            "        }",
            "      } else if (direction === 'down') {",
            "        y++;",
            "        if (y >= rows - 1) {", // 下端に到達
            "          direction = 'left';",
            "        }",
            "      } else if (direction === 'left') {",
            "        x--;",
            "        if (x <= 0) {", // 左端に到達
            "          direction = 'up';",
            "        }",
            "      } else if (direction === 'up') {",
            "        y--;",
            "        if (y <= 0) {", // 上端に到達
            "          direction = 'right';",
            "        }",
            "      }",
            "    }",
            
            "    const allTraced = byteElements.every(item => item.element.classList.contains('traced'));",
            "    if (allTraced || attackCounter > 500) {", // 全部トレースされたか、最大ステップ数に達した場合
            "      clearInterval(moveInterval);",
            "      setTimeout(() => {",
            "        byteElements.forEach(item => item.element.classList.remove('traced'));",
            "        x = 0;",
            "        y = 0;",
            "        direction = 'right';",
            "        attackCounter = 0;",
            "        animateCat();",
            "      }, 2000);",
            "    }",
            "  }, 50);", // 移動速度を調整
            "}",
            
            "codePanel.addEventListener('click', () => {",
            "  codePanel.classList.toggle('flipped');",
            "});",
            
            "createCat();",
            "animateCat();",
            "</script>",
            "</body></html>"
        ));
    }
}
