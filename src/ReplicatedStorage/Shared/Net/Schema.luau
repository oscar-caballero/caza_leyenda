--!strict
--[[
	Net/Schema — Validador de payloads contra los descriptores de Net/Contracts.

	Módulo PURO: no usa servicios de Roblox (se prueba en Lune).
	Falla cerrado: cualquier cosa que no esté descrita se rechaza.
	Devuelve (true, nil) o (false, códigoDeError) — el código es para el log del servidor,
	nunca se devuelve al cliente.
]]

export type FieldSchema =
	{ kind: "enum", values: { string } }
	| { kind: "int", min: number, max: number }
	| { kind: "number", min: number, max: number } -- rechaza NaN e inf
	| { kind: "string", maxLen: number, pattern: string? }
	| { kind: "unitVector3" } -- magnitud 1 ± 0.01
	| { kind: "array", of: FieldSchema, maxLen: number }
	| { kind: "optional", of: FieldSchema }
	| { kind: "opaque", note: string } -- solo servidor→cliente

export type Shape = { [string]: FieldSchema }

local Schema = {}

local UNIT_TOLERANCE = 0.01

local function isFinite(n: number): boolean
	return n == n and n ~= math.huge and n ~= -math.huge
end

-- Tabla "plana": sin metatabla (un exploiter no puede colar __index/__len)
local function isPlainTable(v: unknown): boolean
	return type(v) == "table" and getmetatable(v :: any) == nil
end

local validateField: (f: FieldSchema, v: unknown, allowOpaque: boolean) -> (boolean, string?)

function validateField(f: FieldSchema, v: unknown, allowOpaque: boolean): (boolean, string?)
	if f.kind == "optional" then
		if v == nil then
			return true, nil
		end
		return validateField(f.of, v, allowOpaque)
	end

	if v == nil then
		return false, "missing"
	end

	if f.kind == "enum" then
		if type(v) ~= "string" then
			return false, "enum.type"
		end
		if table.find(f.values, v :: string) == nil then
			return false, "enum.value"
		end
		return true, nil
	elseif f.kind == "int" then
		if type(v) ~= "number" then
			return false, "int.type"
		end
		local n = v :: number
		if not isFinite(n) or math.floor(n) ~= n then
			return false, "int.notInteger"
		end
		if n < f.min or n > f.max then
			return false, "int.range"
		end
		return true, nil
	elseif f.kind == "number" then
		if type(v) ~= "number" then
			return false, "number.type"
		end
		local n = v :: number
		if not isFinite(n) then
			return false, "number.notFinite"
		end
		if n < f.min or n > f.max then
			return false, "number.range"
		end
		return true, nil
	elseif f.kind == "string" then
		if type(v) ~= "string" then
			return false, "string.type"
		end
		local s = v :: string
		if #s > f.maxLen then
			return false, "string.tooLong"
		end
		if utf8.len(s) == nil then
			return false, "string.utf8"
		end
		if f.pattern and string.match(s, f.pattern) == nil then
			return false, "string.pattern"
		end
		return true, nil
	elseif f.kind == "unitVector3" then
		if typeof(v) ~= "Vector3" then
			return false, "vector.type"
		end
		local vec = v :: any
		local x, y, z = vec.X, vec.Y, vec.Z
		if not (isFinite(x) and isFinite(y) and isFinite(z)) then
			return false, "vector.notFinite"
		end
		local mag = math.sqrt(x * x + y * y + z * z)
		if math.abs(mag - 1) > UNIT_TOLERANCE then
			return false, "vector.notUnit"
		end
		return true, nil
	elseif f.kind == "array" then
		if not isPlainTable(v) then
			return false, "array.type"
		end
		local t = v :: { [any]: unknown }
		-- Contar claves reales: no confiar en # (los huecos lo vuelven ambiguo)
		local count = 0
		for k in t do
			count += 1
			if count > f.maxLen then
				return false, "array.tooLong"
			end
			if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
				return false, "array.key"
			end
		end
		for i = 1, count do
			local item = t[i]
			if item == nil then
				return false, "array.hole"
			end
			local ok, err = validateField(f.of, item, allowOpaque)
			if not ok then
				return false, `[{i}].{err}`
			end
		end
		return true, nil
	elseif f.kind == "opaque" then
		if allowOpaque then
			return true, nil
		end
		return false, "opaque.notAllowed"
	end

	return false, "schema.unknownKind"
end

--[[
	Valida un payload completo: debe ser tabla plana, con exactamente los campos
	del esquema (los opcionales pueden faltar) y ninguno más.
	`allowOpaque` solo se usa para comprobar en Studio lo que el servidor envía.
]]
function Schema.validate(shape: Shape, payload: unknown, allowOpaque: boolean?): (boolean, string?)
	if not isPlainTable(payload) then
		return false, "payload.type"
	end
	local t = payload :: { [any]: unknown }

	for k in t do
		if type(k) ~= "string" then
			return false, "payload.keyType"
		end
		if shape[k :: string] == nil then
			return false, `payload.unknownField:{string.sub(k :: string, 1, 32)}`
		end
	end

	for field, f in shape do
		local ok, err = validateField(f, t[field], allowOpaque == true)
		if not ok then
			return false, `{field}.{err}`
		end
	end

	return true, nil
end

return table.freeze(Schema)
