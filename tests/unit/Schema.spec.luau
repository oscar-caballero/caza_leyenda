--!strict
local H = require("../lib/harness")
local Schema = require("../../src/ReplicatedStorage/Shared/Net/Schema")
local roblox = require("@lune/roblox")
local V3 = roblox.Vector3.new

local describe, it, eq = H.describe, H.it, H.eq

-- Réplica de los campos de ToolUse / PuzzleSubmit (Contracts no carga en Lune por `script`)
local TOOL_USE: Schema.Shape = {
	tool = { kind = "enum", values = { "Honda", "Yoyo", "Matraca" } },
	aim = { kind = "unitVector3" },
	clientTime = { kind = "number", min = 0, max = 1e10 },
	hitHint = { kind = "optional", of = { kind = "string", maxLen = 64, pattern = "^[%w_%.%-]+$" } },
}
local PUZZLE: Schema.Shape = {
	puzzle = { kind = "string", maxLen = 64, pattern = "^[%w_%.%-]+$" },
	step = { kind = "int", min = 1, max = 16 },
	answer = { kind = "array", of = { kind = "int", min = 1, max = 12 }, maxLen = 8 },
}

local function ok(shape, payload)
	local r, err = Schema.validate(shape, payload)
	eq(r, true, `debió aceptarse ({err})`)
end
local function bad(shape, payload, expectedErr: string)
	local r, err = Schema.validate(shape, payload)
	eq(r, false, "debió rechazarse")
	H.truthy(err and string.find(err, expectedErr, 1, true), `error '{err}' no contiene '{expectedErr}'`)
end

describe("payload", function()
	it("acepta un ToolUse válido", function()
		ok(TOOL_USE, { tool = "Honda", aim = V3(0, 0, 1), clientTime = 12.5 })
	end)
	it("acepta el campo opcional presente", function()
		ok(TOOL_USE, { tool = "Yoyo", aim = V3(1, 0, 0), clientTime = 1, hitHint = "polilla_01" })
	end)
	it("rechaza algo que no es tabla", function()
		bad(TOOL_USE, "Honda", "payload.type")
		bad(TOOL_USE, nil, "payload.type")
	end)
	it("rechaza tablas con metatabla", function()
		bad(TOOL_USE, setmetatable({}, {}), "payload.type")
	end)
	it("rechaza campos desconocidos (p. ej. daño inventado)", function()
		bad(TOOL_USE, { tool = "Honda", aim = V3(0, 0, 1), clientTime = 1, damage = 9999 }, "unknownField:damage")
	end)
	it("rechaza claves no string", function()
		bad(TOOL_USE, { [1] = "x" }, "payload.keyType")
	end)
	it("rechaza campos obligatorios faltantes", function()
		bad(TOOL_USE, { tool = "Honda", aim = V3(0, 0, 1) }, "clientTime.missing")
	end)
end)

describe("enum", function()
	it("rechaza herramientas que no existen", function()
		bad(TOOL_USE, { tool = "Bazuca", aim = V3(0, 0, 1), clientTime = 1 }, "tool.enum.value")
	end)
	it("rechaza tipos que no son string", function()
		bad(TOOL_USE, { tool = 1, aim = V3(0, 0, 1), clientTime = 1 }, "tool.enum.type")
	end)
end)

describe("number / int", function()
	it("rechaza NaN e infinito", function()
		bad(TOOL_USE, { tool = "Honda", aim = V3(0, 0, 1), clientTime = 0 / 0 }, "number.notFinite")
		bad(TOOL_USE, { tool = "Honda", aim = V3(0, 0, 1), clientTime = math.huge }, "number.notFinite")
	end)
	it("rechaza fuera de rango", function()
		bad(TOOL_USE, { tool = "Honda", aim = V3(0, 0, 1), clientTime = -1 }, "number.range")
	end)
	it("rechaza enteros con decimales y fuera de rango", function()
		bad(PUZZLE, { puzzle = "rio_1", step = 1.5, answer = {} }, "step.int.notInteger")
		bad(PUZZLE, { puzzle = "rio_1", step = 17, answer = {} }, "step.int.range")
	end)
end)

describe("unitVector3", function()
	it("rechaza vectores no unitarios (apuntado amplificado)", function()
		bad(TOOL_USE, { tool = "Honda", aim = V3(0, 0, 50), clientTime = 1 }, "vector.notUnit")
	end)
	it("rechaza vectores con NaN", function()
		bad(TOOL_USE, { tool = "Honda", aim = V3(0 / 0, 0, 0), clientTime = 1 }, "vector.notFinite")
	end)
	it("rechaza tablas que imitan un Vector3", function()
		bad(TOOL_USE, { tool = "Honda", aim = { X = 0, Y = 0, Z = 1 }, clientTime = 1 }, "vector.type")
	end)
end)

describe("string", function()
	it("rechaza strings largos y con caracteres fuera del patrón", function()
		bad(
			TOOL_USE,
			{ tool = "Honda", aim = V3(0, 0, 1), clientTime = 1, hitHint = string.rep("a", 65) },
			"string.tooLong"
		)
		bad(TOOL_USE, { tool = "Honda", aim = V3(0, 0, 1), clientTime = 1, hitHint = "a b" }, "string.pattern")
	end)
	it("rechaza UTF-8 inválido", function()
		bad(PUZZLE, { puzzle = "\255\254", step = 1, answer = {} }, "string.utf8")
	end)
end)

describe("array", function()
	it("acepta una respuesta válida", function()
		ok(PUZZLE, { puzzle = "rio_1", step = 2, answer = { 3, 1, 4 } })
	end)
	it("rechaza arreglos demasiado largos", function()
		bad(PUZZLE, { puzzle = "rio_1", step = 1, answer = { 1, 1, 1, 1, 1, 1, 1, 1, 1 } }, "array.tooLong")
	end)
	it("rechaza huecos y claves raras", function()
		bad(PUZZLE, { puzzle = "rio_1", step = 1, answer = { [1] = 1, [3] = 2 } }, "array.hole")
		bad(PUZZLE, { puzzle = "rio_1", step = 1, answer = { 1, x = 2 } }, "array.key")
		bad(PUZZLE, { puzzle = "rio_1", step = 1, answer = { [0] = 1 } }, "array.key")
	end)
	it("valida cada elemento", function()
		bad(PUZZLE, { puzzle = "rio_1", step = 1, answer = { 1, 99 } }, "[2].int.range")
	end)
end)

describe("opaque", function()
	local S2C: Schema.Shape = { view = { kind = "opaque", note = "x" } }
	it("se rechaza por defecto (cliente→servidor)", function()
		bad(S2C, { view = {} }, "opaque.notAllowed")
	end)
	it("se permite al comprobar envíos del servidor", function()
		eq((Schema.validate(S2C, { view = {} }, true)), true)
	end)
end)

H.finish("Schema")
