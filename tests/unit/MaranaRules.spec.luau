--!strict
local H = require("../lib/harness")
local R = require("../../src/ServerScriptService/Services/MaranaRules")
local cfg = require("../../src/ReplicatedStorage/Shared/Config/Marana")

local describe, it, eq, truthy = H.describe, H.it, H.eq, H.truthy
local POLILLA = cfg.Contacts.PolillaPapel
local RUMOR = cfg.Contacts.Rumor
local DT = 0.1

-- Simula `seconds` con contactos de `n` polillas en cada tick; devuelve el primer instante en que se Enreda
local function swarm(s, n: number, seconds: number, t0: number): (number?, number)
	local t = t0
	local tangledAt = nil
	while t < t0 + seconds do
		for i = 1, n do
			R.contact(cfg, s, `polilla{i}`, POLILLA, t)
		end
		local ev = R.tick(cfg, s, DT, t, false, {})
		if ev == "tangled" and tangledAt == nil then
			tangledAt = t
		end
		t += DT
	end
	return tangledAt, t
end

describe("llenado (D-019)", function()
	it("un toque de polilla suma 8 y respeta el cooldown de 1.2 s por criatura", function()
		local s = R.new(cfg, 0)
		eq(R.contact(cfg, s, "p1", POLILLA, 0), 8)
		eq(R.contact(cfg, s, "p1", POLILLA, 1.0), 0, "misma criatura antes de 1.2 s")
		eq(R.contact(cfg, s, "p2", POLILLA, 1.0), 8, "otra criatura sí suma")
		eq(R.contact(cfg, s, "p1", POLILLA, 1.25), 8)
		eq(s.meter, 24)
	end)
	it("ni un enjambre de 10 polillas lo llena en menos de 5 s (tope 20/s)", function()
		local s = R.new(cfg, 0)
		local tangledAt = swarm(s, 10, 10, 0)
		truthy(tangledAt ~= nil, "debió enredarse")
		truthy((tangledAt :: number) >= 5 - 1e-6, `se enredó a los {tangledAt} s`)
	end)
	it("una sola polilla tarda bastante más (~15 s)", function()
		local s = R.new(cfg, 0)
		local tangledAt = swarm(s, 1, 30, 0)
		truthy(tangledAt and tangledAt >= 14, `se enredó a los {tangledAt} s`)
	end)
	it("la embestida del Rumor suma 20", function()
		local s = R.new(cfg, 0)
		eq(R.contact(cfg, s, "rumor", RUMOR, 0), 20)
	end)
	it("en el tutorial nunca pasa de 66 ni se enreda", function()
		local s = R.new(cfg, 0)
		s.cap = cfg.TUTORIAL_CAP
		local tangledAt = swarm(s, 10, 20, 0)
		eq(tangledAt, nil)
		truthy(s.meter <= 66 + 1e-9, `meter {s.meter}`)
	end)
end)

describe("vaciado", function()
	it("no baja antes de 3 s sin contacto; luego −10/s y de 100 a 0 en ≤10 s", function()
		local s = R.new(cfg, 0)
		s.meter = 50
		s.lastContact = 0
		R.tick(cfg, s, 2.9, 2.9, false, {})
		eq(s.meter, 50)
		R.tick(cfg, s, 1, 3.9, false, {})
		eq(s.meter, 40)
		local full = R.new(cfg, 0)
		full.meter = 99.9
		full.lastContact = -10
		R.tick(cfg, full, 10, 10, false, {})
		eq(full.meter, 0)
	end)
	it("junto a un farol baja 25/s aunque haya contacto reciente", function()
		local s = R.new(cfg, 0)
		s.meter = 60
		s.lastContact = 0
		R.tick(cfg, s, 1, 0.5, true, {})
		eq(s.meter, 35)
	end)
	it("ayudar a disipar una criatura resta 15", function()
		local s = R.new(cfg, 0)
		s.meter = 50
		R.resolved(cfg, s, 0)
		eq(s.meter, 35)
	end)
end)

describe("Enredado", function()
	local function tangle(): R.State
		local s = R.new(cfg, 0)
		s.meter = cfg.MAX
		eq(R.tick(cfg, s, DT, 0, false, {}), "tangled")
		return s
	end
	it("dura 5 s, no gana Maraña y sale solo a 40", function()
		local s = tangle()
		truthy(R.isTangled(s, 4.9))
		eq(R.contact(cfg, s, "p1", POLILLA, 2), 0, "no gana mientras está Enredado")
		eq(R.tick(cfg, s, DT, 4.9, false, {}), nil)
		eq(R.tick(cfg, s, DT, 5.0, false, {}), "freedByTime")
		eq(s.meter, cfg.AFTER_TANGLE)
		eq(R.isTangled(s, 5.0), false)
	end)
	it("2 s de inmunidad al salir", function()
		local s = tangle()
		R.tick(cfg, s, DT, 5.0, false, {})
		eq(R.contact(cfg, s, "p1", POLILLA, 6.0), 0)
		eq(R.contact(cfg, s, "p1", POLILLA, 7.1), 8)
	end)
	it("rescate: 2 s cerca sin disparar lo libera", function()
		local s = tangle()
		local r = { ana = { near = true, firedAt = -100 } }
		eq(R.tick(cfg, s, DT, 1.0, false, r), nil)
		eq(R.tick(cfg, s, DT, 2.0, false, r), nil)
		eq(R.tick(cfg, s, DT, 3.0, false, r), "freedByRescue")
		eq(s.meter, cfg.AFTER_TANGLE)
	end)
	it("si el rescatador dispara, el contador se reinicia", function()
		local s = tangle()
		local r = { ana = { near = true, firedAt = -100 } }
		R.tick(cfg, s, DT, 1.0, false, r)
		r.ana.firedAt = 2.0 -- disparó a mitad del rescate
		eq(R.tick(cfg, s, DT, 2.5, false, r), nil, "se reinició")
		eq(R.tick(cfg, s, DT, 3.2, false, r), nil, "empieza a contar de nuevo")
		eq(R.tick(cfg, s, DT, 4.9, false, r), nil, "1.7 s: todavía no")
		eq(R.tick(cfg, s, DT, 5.0, false, r), "freedByTime", "el tiempo de Enredado se acabó antes")
	end)
	it("alejarse reinicia el rescate y pasar de largo no cuenta", function()
		local s = tangle()
		eq(R.tick(cfg, s, DT, 0.5, false, { ana = { near = true, firedAt = -100 } }), nil)
		eq(R.tick(cfg, s, DT, 1.0, false, { ana = { near = false, firedAt = -100 } }), nil)
		eq(R.tick(cfg, s, DT, 1.5, false, { ana = { near = true, firedAt = -100 } }), nil)
		eq(R.tick(cfg, s, DT, 2.6, false, { ana = { near = true, firedAt = -100 } }), nil, "solo 1.1 s seguidos")
	end)
	it("dos rescatadores a la vez: se libera una sola vez", function()
		local s = tangle()
		local r = { ana = { near = true, firedAt = -100 }, beto = { near = true, firedAt = -100 } }
		R.tick(cfg, s, DT, 1.0, false, r)
		eq(R.tick(cfg, s, DT, 3.0, false, r), "freedByRescue")
		eq(R.tick(cfg, s, DT, 3.1, false, r), nil)
	end)
end)

describe("HUD", function()
	it("3 segmentos: 0, 33, 66 y 100 %", function()
		eq(R.segments(cfg, 0), 0)
		eq(R.segments(cfg, 0.32), 0)
		eq(R.segments(cfg, 0.34), 1)
		eq(R.segments(cfg, 0.66), 1)
		eq(R.segments(cfg, 0.67), 2)
		eq(R.segments(cfg, 1), 3)
	end)
end)

H.finish("MaranaRules")
