--[[
MIT License

Copyright (c) 2022 twiswist

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

--[[
If your string is an argument to a program executed through the
shell, such as with system(), popen(), ShellExecute or similar
and the program splits its command line using CommandLineToArgv
or parse_cmdline, implicitly or explicitly, then use unparse().
This quotes the string and escapes quotes and shell characters.

If your string is an argument to a program executed through
CreateProcess or similar that don't do shelly things and the
program splits its command line using CommandLineToArgv or
parse_cmdline, implicitly or explicitly, then use argv().
This escapes quotes, then surrounds the string in quotes.

If your string is a shell redirection target, then use redirect().
This escapes shell characters and quotes the string.
Also prefer this undocumented cmd syntax which prevents a number
from being placed to the left of a > symbol:
	>"foo bar" echo 123456
This command will echo "123456" to the file "foo bar", whereas:
	echo 123456>"foo bar"
... attempts to redirect the 6th standard stream.
You only need to do this for commands that do not split arguments
or otherwise aren't sensitive to a space before the <, which is
another way to prevent this from happening.

If your string will pass through the shell to a command that does
not split its arguments, such as set, echo etc., then use cmd().
This only escapes shell characters.

If your string will pass through CreateProcess to a command that
doesn't split its arguments, then your string does not need to be
escaped.

"cmd", "cmd.exe" and "shell" are used interchangeably in these docs.

These functions attempt to minimize the amount of characters used
to escape.
For example, argv() will not surround the string in quotes if it
has no spaces. It will still escape quotes.
The Dumb variants will not check the contents of string and just
escape everything, even if redundant.
argvDumb() will always surround in quotes and cmdDumb() will stick
carets on every special character, even though quotes suppress
cmd.exe's behavior to some extent.

The MIT License does not require you to provide public/user-facing
attribution.

Credits:

2021-09-15:
https://docs.microsoft.com/en-us/archive/blogs/twistylittlepassagesallalike/everyone-quotes-command-line-arguments-the-wrong-way
http://www.windowsinspired.com/understanding-the-command-line-string-and-arguments-received-by-a-windows-program/
http://www.windowsinspired.com/how-a-windows-programs-splits-its-command-line-into-individual-arguments/
The latter two articles focus on the two functions that split a command line into argv.
The website is down as of 2022-07-18, but the value in there was mostly in the illustrations.

2022-08-07
https://ss64.com/nt/syntax-redirection.html
]]

local escape = {}

-- Fortify str against Windows shell followed by CommandLineToArgv.
function escape.unparse(str)
	return escape.cmd(escape.argv(str))
end

function escape.unparseDumb(str)
	return '^"' .. str:gsub('(\\*)"', '%1%1\\"'):gsub('\\*$', '%1%1"')
		:gsub("[\t\r\n]+", " "):gsub("[()<>&|^!%%\"]", "^%0")
end

--[[
Fortify a string argument against CommandLineToArgv or parse_cmdline.
TODO: research whether \t\r\n count as command separator characters.
\t\r\n can pass through StartProcess just fine. [citation needed]
]]
function escape.argv(str)
	-- Escape internal quotes. If the string has to be quoted,
	-- then also escape trailing backslashes.
	return str:find("[ \t\r\n]")
		and '"' .. str:gsub('(\\*)"', '%1%1\\"'):gsub('\\*$', '%1%1"')
		or str:gsub('(\\*)"', '%1%1\\"')
end

function escape.argvDumb(str)
	return '"' .. str:gsub('(\\*)"', '%1%1\\"'):gsub('\\*$', '%1%1"')
end

--[[
Fortify a string argument against cmd.exe.

(): used in if, not always necessary to escape these
<>: pipe from/to file
&: end command
|: pipe to another command
^: escape
": toggle interpretation of the above characters (not sure if (), though)
%: env substitution
!: env substitution in delayed expansion mode

Most footgunningly, the backslash has no meaning to cmd.exe and an
argv-escaped quote will toggle parsing of >, |, & etc. even "outside"
of an "argument".
For a demonstration, paste this into cmd.exe:
	echo foo \" bar %userprofile% | asdf
Instead of piping 'foo " bar' into 'asdf.exe', it echoes the whole
thing because the " prevented cmd from interpreting the |. However,
interpolation with %% (and !! in delayed expansion mode) are exempt
from this quoting behavior.

Newlines cannot be passed through the shell. [research needed]
Tabs CAN be passed through shell execute as-is, but cause trouble when
pasted into cmd.exe. In addition, per https://superuser.com/q/150116
you can put line feeds into cmd.exe with alt+10 and they work fine with
echo, but show up as ? (3f, question mark) in DumpArgs...
]]
function escape.cmd(str)
	-- Utility function to escape all cmd special characters.
	local function escapecmd(str)
		return str:gsub('[()<>&|^"%%!]', "^%0")
	end
	str = str:gsub("[\t\r\n]+", " ")
	-- Whether cmd is currently looking for special characters ()<>@|^"
	local quoted = true
	-- Lua patterns do not have alternation with ^$ or lookahead/behind,
	-- so the segment before the first quote needs special care.
	local a, b = str:match('([^"]*)(.*)')
	-- TODO: investigate perf of last += #match like in the js port.
	local len = #b
	return escapecmd(a) .. b:gsub('"([^"]*)()', function(section, last)
		if quoted == false then
			-- Unquoted, escape the string.
			quoted = not quoted
			return '"' .. escapecmd(section)
		elseif last > len or section:find("[!%%]") then
			-- We're in quoted mode, but there is a dangerous character
			-- ([!%] will work in quotes) or we're about to finish while
			-- in quoted mode, so we must escape the quote to be able to
			-- quote the string.
			-- TODO: investigate whether if's () work inside quotes.
			return '^"' .. escapecmd(section)
		else
			-- We're in quoted mode and the quotes suffice to escape the string.
			-- TODO: investigate perf of returning the match like the js port.
			quoted = not quoted
			return '"' .. section
		end
	end)
end

function escape.cmdDumb(str)
	return str:gsub("[\t\r\n]+", " "):gsub('[()<>&|^"%%!]', "^%0")
end

--[[
Fortify a shell redirection target filename.
]]
function escape.redirect(str)
	str = escape.cmd(str)
	return str:find("[ \t\r\n]")
		and '"' .. str .. '"'
		or str
end

function escape.redirectDumb(str)
	return '"' .. str:gsub("[\t\r\n]+", " "):gsub('[()<>&|^"%%!]', "^%0") .. '"'
end

--[[

potential C port?

int
escapecmd(
	char*  instr,  // input: string to escape
	char*  outstr, // input: output buffer
	int    buflen, // input: maximum amount of chars to write to outstr
	char** endstr, // output: the \0 at the end of outstr
	escapecmdstate* state) // optional input/output: state to continue after output buffer turns out to be too small
{
	// ...
}

on success (fit into buffer), return 0
on failure (did not fit into buffer), return !0
on failure, if state is null, you are expected to discard the result or try again with a larger buffer
on failure, if state is not null, you are expected to get another buffer (or expand) and continue by passing in the same state and continuing where you left off (at new buffer or endstr)
regardless of outcome, endstr will be set and will point to \0
unless buflen is 0 or something

do any c string functions return the amount of chars written?

if it's that simple to save/load-state, why not make it an iterator that returns one character at a time?

]]

-- Escape filenames on NTFS in a manner that somewhat resembles the original.
-- Not bijective.
-- Does not prevent the filename from being too long to be a path name.
do
	local escmatch = '[%z\1-\31<>:"/\\|?*]'
	local escmap = {
		["<"] = "{",
		[">"] = "}",
		[":"] = ";",
		['"'] = "'",
		["/"] = "⧸", -- big solidus
		["\\"]= "⧹", -- big reverse solidus. reverse solidus: ⧵
		["|"] = "ǀ", -- IPA dental click
		["?"] = "~",
		["*"] = "_", -- * and _ both are emphasis in Markdown
	}
	for i =  0, 15 do escmap[string.char(i)] = "#" .. string.byte(i + 64) end
	for i = 16, 31 do escmap[string.char(i)] = "#" .. string.byte(i + 96) end
	-- 22 such devices
	local devices = {CON=true,PRN=true,AUX=true,NUL=true,COM1=true,COM2=true,COM3=true,COM4=true,COM5=true,COM6=true,COM7=true,COM8=true,COM9=true,LPT1=true,LPT2=true,LPT3=true,LPT4=true,LPT5=true,LPT6=true,LPT7=true,LPT8=true,LPT9=true}
	
	function escape.filename(str)
		-- Cannot be a reserved name (a legacy device).
		-- The name is anything before the first dot.
		-- Proof: rename a file to NUL.foo.bar
		-- Mitigated by suffixing the name with a #
		str = str:gsub("^[^.]*", function(name)
			if devices[string.upper(name)] then
				return name .. "#"
			end
		end)
		-- Cannot contain <>:"/\|?* or any character from 0 to 31.
		-- Can contain DEL, however (which is matched by %c)
		-- Mitigated by replacing each of these characters with a lookalike.
		str = str:gsub(escmatch, escmap)
		-- Cannot end with a space or period.
		-- Mitigated by suffixing the name with a #
		if str:find("[ .]$") then
			str = str .. "#"
		end
		return str
	end
end

return escape
