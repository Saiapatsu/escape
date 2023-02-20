local escape = {}

-- Fortify a string argument against Windows shell followed by CommandLineToArgv.
function escape.unparse(str)
	return escape.cmd(escape.argv(str))
end

function escape.unparseDumb(str)
	return '^"' .. str:gsub('(\\*)"', '%1%1\\"'):gsub('\\*$', '%1%1"', 1)
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
		and '"' .. str:gsub('(\\*)"', '%1%1\\"'):gsub('\\*$', '%1%1"', 1)
		or (str:gsub('(\\*)"', '%1%1\\"'))
end

function escape.argvDumb(str)
	return '"' .. str:gsub('(\\*)"', '%1%1\\"'):gsub('\\*$', '%1%1"', 1)
end

--[[
Fortify a string argument against cmd.exe.

(): split across multiple lines
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
echo, but show up as ? (3f, question mark) in DumpArgs, which might
be just an encoding issue.
]]
function escape.cmd(str)
	-- Utility function to escape all cmd special characters.
	local function escapecmd(str)
		return (str:gsub('[()<>&|^%%!]', "^%0"))
	end
	-- Get rid of characters that cause trouble when pasted into cmd.
	str = str:gsub("[\t\r\n]+", " ")
	-- Quote state of `section` in that gsub below.
	-- Starts out the opposite of what you'd expect because of `a`.
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
		elseif last > len or section:find("[!%%]") then -- and quoted == true
			-- Do not finish in an unquoted state or leave ! or % unescaped.
			return '^"' .. escapecmd(section)
		else
			-- The quotes suffice to escape the string.
			-- TODO: investigate perf of returning the match like the js port.
			quoted = not quoted
			return '"' .. section
		end
	end)
end

function escape.cmdDumb(str)
	return (str:gsub("[\t\r\n]+", " "):gsub('[()<>&|^"%%!]', "^%0"))
end

--[[
Fortify a filename against shell redirection.
Assumes str is a valid filename and thus contains no tabs, carriage
returns, line feeds, shell symbols or quotes that could 0wn the shell.
]]
function escape.redirect(str)
	return ('"' .. str:gsub("%%", "%%%%") .. '"')
	-- If there is more than one special character, surround in quotes,
	-- otherwise escape just that one character
	-- return str:find("[ &^][^ &^]*[ &^]")
		-- and '"' .. str:gsub("%%", "%%%%") .. '"'
		-- or (str:gsub('[ &^]', "^%0"):gsub("%%", "%%%%"))
end

-- function escape.redirectDumb(str)
	-- -- Probably not a complete list - needs testing
	-- return (str:gsub('[ &^]', "^%0"):gsub("%%", "%%%%"))
-- end

--[[
Fortify exclamation marks in a string against delayed expansion.
]]
function escape.delayed(str)
	return (str:gsub("!", "^!"))
end

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
