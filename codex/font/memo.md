https://github.com/zachleat/glyphhanger

npm install -g glyphhanger

glyphhanger --whitelist=ABCD --formats=woff2,woff --subset=*.ttf

--


python3 -m fontTools.subset IosevkaFixed-Regular.ttf --text=" \"#()+,-./0123456789:;=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^abcdefghijklmnopqrstuvwxyz{}" --output-file=IosevkaFixed-Regular-part.woff2

base64 -i IosevkaFixed-Regular-part.woff2 > font.base64

--


python3 -m fontTools.subset FiraCode-Regular.ttf --text=" \"#()+,-./0123456789:;=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^abcdefghijklmnopqrstuvwxyz{}" --output-file=FiraCode-Regular-part.woff2

base64 -i FiraCode-Regular-part.woff2 > font.base64

