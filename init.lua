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

local escape = {}

--[[
Informed by these articles as of 2021-09-15:

https://docs.microsoft.com/en-us/archive/blogs/twistylittlepassagesallalike/everyone-quotes-command-line-arguments-the-wrong-way
http://www.windowsinspired.com/understanding-the-command-line-string-and-arguments-received-by-a-windows-program/
http://www.windowsinspired.com/how-a-windows-programs-splits-its-command-line-into-individual-arguments/

The latter two focus on the two functions that split a command line into argv.
The website is down as of 2022-07-18, but the info there is not important.
They had a lot of good visuals.

]]

-- Fortify str against CommandLineToArgv or parse_cmdline.
-- Only use this if the application splits its command line into argv using
-- these functions. Notoriously, echo does not do that.
function escape.argv(str)
	-- \t\r\n pass through StartProcess as-is, but escape.cmd mangles them
	if str:find("[ \t\r\n]") then
		-- Escape internal quotes, ensure trailing quote does not get escaped
		-- and surround in quotes
		return '"' .. str:gsub('(\\*)"', '%1%1\\"'):gsub('\\*$', '%1%1"')
	else
		-- Escape internal quotes
		return str:gsub('(\\*)"', '%1%1\\"')
	end
end

function escape.dumbargv(str)
	return '"' .. str:gsub('(\\*)"', '%1%1\\"'):gsub('\\*$', '%1%1"')
end

local function escapecmd(str)
	return str:gsub("[()<>&|^!%%\"]", "^%0")
end
-- Fortify string against cmd.exe.
-- Only use this if the command line passes through the shell (cmd.exe, system(), popen() of any kind etc.)
-- Does not do what escape.argv does.
function escape.cmd(str)
	-- (): used in if, not always necessary to escape these
	-- <>: pipe from/to file
	-- &: end command
	-- |: pipe to another command
	-- ^: escape
	-- !: env substitution in delayed expansion mode
	-- %: env substitution
	-- ": generally a nuisance
	-- newlines cannot be passed through shell execute
	-- tabs CAN be passed through shell execute as-is,
	-- but cause trouble when pasted into cmd.exe
	-- in addition, per https://superuser.com/q/150116
	-- you can put line feeds into cmd.exe with alt+10
	-- and they work fine with echo, but show up as ?
	-- (3f, question mark) in DumpArgs...
	str = str:gsub("[\t\r\n]+", " ")
	-- Lua patterns do not have lookahead or lookbehind, so the first segment
	-- needs special care
	local a, b = str:match('([^"]*)(.*)')
	-- whether shell is looking at special characters
	local quoted = false
	
	return escapecmd(a) .. b:gsub('(%^*")([^"]*)()', function(quote, unquote, last)
		if #quote % 2 == 1 then -- if the quote remains unescaped
			quoted = not quoted
		end
		
		if not quoted then
			return quote .. escapecmd(unquote)
			
		elseif unquote:find("[!%%]") or last > #b then
			-- we're in quoted mode, but there is a dangerous character
			-- (!% work even in quotes) or we're about to finish while
			-- in quoted mode, so we must re-enable special characters
			-- (specifically ^) and escape them for good
			quoted = not quoted
			return "^" .. quote .. escapecmd(unquote)
			
		else
			-- we're in quoted mode and there are no dangerous characters
			return quote .. unquote
		end
	end)
end

function escape.dumbcmd(str)
	return str:gsub("[\t\r\n]+", " "):gsub("[()<>&|^!%%\"]", "^%0")
end

-- Fortify str against Windows cmd followed by CommandLineToArgvW.
function escape.unparse(str)
	return escape.cmd(escape.argv(str))
end

--[[

function escapeArgv(str) {
	return / \t\r\n/.test(str)
		? '"' + str.replace(/(\\*)"/g, '$1$1\\"').replace(/\\*$/, '$&$&"')
		: str.replace(/(\\*)"/g, '$1$1\\"');
}

function escapeArgvDumb(str) {
	return '"' + str.replace(/(\\*)"/g, '$1$1\\"').replace(/\\*$/, '$&$&"');
}

function escapeCmd(str) {
	function cmdescape(str) {
		return str.replace(/[()<>&|^!%"]/g, "^$&");
	}
	str = str.replace(/[\t\r\n]+/g, " ");
	let quoted = false;
	let last = 0;
	return str.replace(/(\^*"|^)([^"]*)/g, (match, quote, unquote) => {
		last += match.length; // silly workaround for the lack of lua's () in regex
		if (quote.length & 1) {
			quoted = !quoted;
		}
		if (!quoted) {
			return quote + cmdescape(unquote);
		} else if (/[!%]/.test(unquote) || last == str.length) {
			quoted = !quoted;
			return "^" + quote + cmdescape(unquote);
		} else {
			return quote + unquote;
		}
	});
}

function escapeCmdDumb(str) {
	return str.replace(/[\t\r\n]+/g, " ").replace(/[()<>&|^!%"]/g, "^$&");
}

function unparse(str) {
	return escapeCmd(escapeArgv(str));
}

]]

-- Escape filenames on NTFS in a manner that somewhat resembles the original.
-- Not bijective.
-- Does not prevent the filename from being too long to be a path name.
do
	local escmatch = [=[[%z\1-\31<>:"/\|?*]]=]
	local escmap = {
		["<"] = "{",
		[">"] = "}",
		[":"] = ";",
		['"'] = "'",
		["/"] = "⧸", -- big solidus
		["\\"]= "⧹", -- big reverse solidus. reverse solidus: ⧵
		["|"] = "ǀ", -- IPA dental click
		["?"] = "~",
		["*"] = "_",
	}
	for i =  0, 15 do escmap[string.char(i)] = "#" .. string.byte(i + 64) end
	for i = 16, 31 do escmap[string.char(i)] = "#" .. string.byte(i + 96) end
	-- 22 such devices
	local devices = {CON=true,PRN=true,AUX=true,NUL=true,COM1=true,COM2=true,COM3=true,COM4=true,COM5=true,COM6=true,COM7=true,COM8=true,COM9=true,LPT1=true,LPT2=true,LPT3=true,LPT4=true,LPT5=true,LPT6=true,LPT7=true,LPT8=true,LPT9=true}
	
	function escape.filename(str)
		-- Cannot be a reserved name (a legacy device).
		-- The name is anything before the first dot.
		-- To prove this, rename something to NUL.foo.bar
		str = string.gsub(str, "^[^.]*", function(name)
			if devices[string.upper(name)] then
				return name .. "#"
			end
		end)
		-- Cannot contain <>:"/\|?* or any character from 0 to 31.
		-- Can contain DEL, however (which is matched by %c)
		str = str:gsub(escmatch, escmap)
		-- Cannot end with a space or period.
		if str:find("[ .]$") then
			str = str .. "#"
		end
		return str
	end
end
return escape
