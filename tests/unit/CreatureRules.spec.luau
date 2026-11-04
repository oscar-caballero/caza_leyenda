--!strict
local H = require("../lib/harness")
local R = require("../../src/ServerScriptService/Services/CreatureRules")
local Creatures = require("../../src/ReplicatedStorage/Shared/Config/Creatures")
local roblox = require("@lune/roblox")
local V3 = roblox.Vector3.new

local describe, it, eq, truthy = H.describe, H.it, H.eq, H.truthy
local function near(a: number, b: number, msg: string?)
	truthy(math.abs(a - b) < 1e-6, `{msg or "near"}: {a} vs {b}`)
end

describe("progresión (D-007)", function()
	it("costo por nivel 100·n^1.5", function()
		eq(R.xpToNext(1), 100)
		eq(R.xpToNext(2), 282)
		eq(R.xpToNext(5), 1118)
	end)
	it("total hasta el nivel 6 ≈ 2,800 XP", function()
		local total = 0
		for n = 1, 5 do
			total += R.xpToNext(n)
		end
		truthy(total >= 2700 and total <= 2900, `total {total}`)
	end)
	it("nivel según XP y tope 6", function()
		eq(R.levelForXp(0, 6), 1)
		eq(R.levelForXp(99, 6), 1)
		eq(R.levelForXp(100, 6), 2)
		eq(R.levelForXp(381, 6), 2)
		eq(R.levelForXp(382, 6), 3)
		eq(R.levelForXp(10 ^ 9, 6), 6)
	end)
end)

describe("cooperativo (D-008)", function()
	it("1→×1, 2→×1.5, 4→×2.5 y tope en 4", function()
		eq(R.coopScale(1), 1)
		eq(R.coopScale(2), 1.5)
		eq(R.coopScale(4), 2.5)
		eq(R.coopScale(8), 2.5)
		eq(R.coopScale(0), 1)
	end)
	it("el daño se reparte sobre maxOlvido escalado", function()
		near(R.applyDamage(1, 10, 30, 1), 2 / 3)
		near(R.applyDamage(1, 10, 30, 2), 1 - 10 / 60)
		eq(R.applyDamage(0.1, 999, 30, 1), 0)
		eq(R.applyDamage(0.5, -5, 30, 1), 0.5, "daño negativo no cura")
	end)
	it("con la honda base, la polilla cae en 3 golpes y el Rumor (preferida) en ~32", function()
		local hits, meter = 0, 1
		while meter > 0 do
			meter = R.applyDamage(meter, 10, Creatures.PolillaPapel.maxOlvido :: number, 1)
			hits += 1
		end
		eq(hits, 3)
		hits, meter = 0, 1
		while meter > 0 do
			meter = R.applyDamage(meter, 12.5, Creatures.Rumor.maxOlvido :: number, 1)
			hits += 1
		end
		eq(hits, 32)
	end)
	it("recompensa solo a quien aportó ≥10 %", function()
		local who = R.eligible({ ana = 50, beto = 45, carla = 4 }, 0.10)
		table.sort(who)
		eq(#who, 2)
		eq(who[1], "ana")
		eq(who[2], "beto")
		eq(#R.eligible({}, 0.10), 0)
	end)
end)

describe("rebobinado (D-009)", function()
	local history = {
		{ t = 10.0, pos = V3(0, 0, 0) },
		{ t = 10.1, pos = V3(10, 0, 0) },
		{ t = 10.2, pos = V3(20, 0, 0) },
	}
	it("interpola entre muestras", function()
		local p = R.positionAt(history, 10.05) :: any
		near(p.X, 5)
		local q = R.positionAt(history, 10.15) :: any
		near(q.X, 15)
	end)
	it("fuera de rango usa el extremo", function()
		eq((R.positionAt(history, 9) :: any).X, 0)
		eq((R.positionAt(history, 11) :: any).X, 20)
		eq(R.positionAt({}, 10), nil)
	end)
	it("el tiempo del cliente se recorta a 250 ms", function()
		eq(R.rewindTime(5, 100, 0.25), 99.75, "un cliente que miente con un tiempo viejo")
		eq(R.rewindTime(200, 100, 0.25), 100, "ni tiempos del futuro")
		eq(R.rewindTime(99.9, 100, 0.25), 99.9)
	end)
	it("recorta el historial dejando una muestra de borde", function()
		local h = {}
		for i = 0, 10 do
			table.insert(h, { t = i * 0.1, pos = V3(i, 0, 0) })
		end
		R.trimHistory(h, 1.0, 0.5)
		truthy(h[1].t < 0.5 + 1e-9, "queda una muestra anterior al borde")
		truthy(h[2].t >= 0.5 - 1e-9, "las demás dentro de la ventana")
		eq(h[#h].t, 1.0)
	end)
	it("rayo-esfera: toca, falla, queda detrás o fuera de alcance", function()
		local o, dir = V3(0, 0, 0), V3(0, 0, -1)
		near(R.raySphere(o, dir, 100, V3(0, 0, -20), 2) :: number, 18)
		eq(R.raySphere(o, dir, 100, V3(5, 0, -20), 2), nil, "pasa de lado")
		eq(R.raySphere(o, dir, 100, V3(0, 0, 20), 2), nil, "está detrás")
		eq(R.raySphere(o, dir, 10, V3(0, 0, -20), 2), nil, "fuera de alcance")
		eq(R.raySphere(o, dir, 100, V3(0, 0, 0), 2), 0, "origen dentro de la esfera")
	end)
end)

H.finish("CreatureRules")
