--!strict
-- Harness mínimo para tests de módulos puros en Lune. Sale con código 1 si algo falla.
local process = require("@lune/process")

local H = {}
local failures = 0
local passed = 0
local current = ""

function H.describe(name: string, fn: () -> ())
	current = name
	fn()
end

function H.it(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		failures += 1
		print(`  ✗ {current} › {name}\n      {err}`)
	end
end

function H.eq(actual: any, expected: any, msg: string?)
	if actual ~= expected then
		error(`{msg or "eq"}: esperaba {tostring(expected)}, obtuve {tostring(actual)}`, 2)
	end
end

function H.truthy(v: any, msg: string?)
	if not v then
		error(msg or "esperaba un valor verdadero", 2)
	end
end

function H.finish(suite: string)
	print(`{suite}: {passed} ok, {failures} fallidos`)
	if failures > 0 then
		process.exit(1)
	end
end

return H
