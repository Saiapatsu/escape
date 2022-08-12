echo foo>nospace
echo foo>"has space"
echo foo>fail&ampersand
echo foo>"success&ampersand1"
echo foo>success^&ampersand2
echo foo>"wrong^&ampersand"
echo foo>"expanded%username%user"
echo foo>failing^%username^%user
echo foo>"escaped%%username%%expansion"
echo foo>"characters &^%%!test"

echo foo>"immediate2 ! #$%%&'() +,-. 0123456789 ; =  @ABCDEFGHIJKLMNOPQRSTUVWXYZ[ ]^ `abcdefghijklmnopqrstuvwxyz{ }~"
SETLOCAL EnableDelayedExpansion
echo foo>"delayed1 ! #$%%&'() +,-. 0123456789 ; =  @ABCDEFGHIJKLMNOPQRSTUVWXYZ[ ]^ `abcdefghijklmnopqrstuvwxyz{ }~"
echo foo>"delayed2 ^! #$%%&'() +,-. 0123456789 ; =  @ABCDEFGHIJKLMNOPQRSTUVWXYZ[ ]^ `abcdefghijklmnopqrstuvwxyz{ }~"

goto :eof

(string.rep(".", 128 - 32):gsub("().", function(i) return string.char(i + 31) end):gsub("[<>:\"/\\|%?%*]", " "):gsub("%%", "%%%%"))
for delayed expansion, prepend ! with one ^ as usual
