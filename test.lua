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

local count = 0
local failures = 0

while true do
	local test = line()
	if test == nil or test == "" then break end
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
	-- skip cruft
	repeat
		test = line()
	until test == nil or test == ""
end

print(count .. " tests, " .. failures .. " failed")
