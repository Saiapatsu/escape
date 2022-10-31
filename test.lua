--[[
Lua escape function tester.
Requires Luvit.
Pipe tests.txt to this script:
test.lua < tests.txt
]]

local escape = require "escape"
local line = io.lines()
local methods = {
	{"unparse", escape.unparse},
}

-- luvit print can only print to tty
local print, print2
function print(...)
	if select("#", ...) ~= 0 then
		return print2(...)
	else
		io.write("\n")
	end
end
function print2(str, ...)
	io.write(tostring((str)))
	if select("#", ...) ~= 0 then -- "if ..." would eat nils
		io.write("\t")
		return print2(...)
	else
		io.write("\n")
	end
end

local count = 0
local failures = 0

-- true: print test cases
-- false: test
local create = true

while true do
	local test = line()
	if test == nil or test == "" then break end
	if create then
		print(test)
		for _,v in ipairs(methods) do
			local name, method = unpack(v)
			print(method(test))
		end
		print()
	else
		for _,v in ipairs(methods) do
			count = count + 1
			local name, method = unpack(v)
			local expected = line()
			local result = method(test)
			if result ~= expected then
				print("Failed " .. name)
				print("Test:     " .. test)
				print("Expected: " .. expected)
				print("Result:   " .. result)
				print()
				failures = failures + 1
			end
		end
	end
	-- skip cruft
	repeat
		test = line()
	until test == nil or test == ""
end

if not create then
	print(count .. " tests, " .. failures .. " failed")
end
