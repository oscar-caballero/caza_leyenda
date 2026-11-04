--!strict
local H = require("../lib/harness")
local ToolRules = require("../../src/ServerScriptService/Services/ToolRules")
local Tools = require("../../src/ReplicatedStorage/Shared/Config/Tools")
local Creatures = require("../../src/ReplicatedStorage/Shared/Config/Creatures")

local describe, it, eq, truthy = H.describe, H.it, H.eq, H.truthy

describe("equip", function()
	it("intercambia si la herramienta ya está en la otra ranura", function()
		local e = ToolRules.equip({ Slot1 = "Honda", Slot2 = "Yoyo" }, 1, "Yoyo")
		eq(e.Slot1, "Yoyo")
		eq(e.Slot2, "Honda")
	end)
	it("reemplaza si no estaba equipada", function()
		local e = ToolRules.equip({ Slot1 = "Honda", Slot2 = "Yoyo" }, 2, "Matraca")
		eq(e.Slot1, "Honda")
		eq(e.Slot2, "Matraca")
	end)
	it("equipar la misma en su ranura no cambia nada", function()
		local e = ToolRules.equip({ Slot1 = "Honda", Slot2 = "Yoyo" }, 1, "Honda")
		eq(e.Slot1, "Honda")
		eq(e.Slot2, "Yoyo")
	end)
	it("nunca deja dos ranuras iguales", function()
		for _, slot in { 1, 2 } do
			for _, tool in { "Honda", "Yoyo", "Matraca" } do
				local e = ToolRules.equip({ Slot1 = "Honda", Slot2 = "Yoyo" }, slot, tool)
				truthy(e.Slot1 ~= e.Slot2, `slot {slot} tool {tool}`)
			end
		end
	end)
end)

describe("daño y nivel cultural", function()
	it("solo las criaturas de nivel 3 reciben daño", function()
		eq(ToolRules.canDamage(Creatures.Chaneque), false)
		eq(ToolRules.canDamage(Creatures.Llorona), false)
		eq(ToolRules.canDamage(Creatures.CharroNegro), false)
		eq(ToolRules.canDamage(Creatures.PolillaPapel), true)
		eq(ToolRules.canDamage(Creatures.Rumor), true)
		eq(ToolRules.canDamage(nil), false)
	end)
	it("toda criatura de nivel 3 tiene maxOlvido, preferida y alternativa válidas (D-007)", function()
		for id, c in Creatures do
			if c.level == 3 then
				truthy(c.maxOlvido and c.maxOlvido > 0, `{id} maxOlvido`)
				truthy(c.preferred and Tools.Defs[c.preferred :: string], `{id} preferida`)
				truthy(c.alternative and Tools.Defs[c.alternative :: string], `{id} alternativa`)
				truthy(c.preferred ~= c.alternative, `{id} preferida ≠ alternativa`)
			end
		end
	end)
	it("+25 % con la herramienta preferida", function()
		local base = ToolRules.damage(Tools, "Honda", 0, false, nil)
		local pref = ToolRules.damage(Tools, "Honda", 0, false, Creatures.Rumor)
		eq(math.abs(pref / base - 1.25) < 1e-9, true)
	end)
	it("cada nivel de mejora suma +15 %", function()
		local t0 = ToolRules.damage(Tools, "Yoyo", 0, false, nil)
		local t3 = ToolRules.damage(Tools, "Yoyo", 3, false, nil)
		eq(math.abs(t3 / t0 - 1.45) < 1e-9, true)
	end)
end)

describe("balance D-007", function()
	local function dps(tool: string, boosted: boolean): number
		local def = Tools.Defs[tool]
		return ToolRules.damage(Tools, tool, 0, boosted, nil) / ToolRules.cooldown(def, boosted, Tools.Resortera)
	end
	it("DPS de las herramientas activas dentro de ±10 %", function()
		local values = {}
		for id, def in Tools.Defs do
			if def.enabled then
				table.insert(values, dps(id, false))
			end
		end
		local lo, hi = math.min(table.unpack(values)), math.max(table.unpack(values))
		truthy(hi / lo <= 1.10, `rango de DPS {lo}–{hi}`)
	end)
	it("la resortera dispara más rápido sin pasar de +10 % de DPS", function()
		local normal, boosted = dps("Honda", false), dps("Honda", true)
		truthy(boosted > normal, "debe ser una mejora")
		truthy(boosted / normal <= 1.10 + 1e-9, `resortera ×{boosted / normal}`)
	end)
	it("costos de mejora 50 / 150 / 400 y nada después del 3", function()
		eq(ToolRules.upgradeCost(Tools.UpgradeCosts, 0), 50)
		eq(ToolRules.upgradeCost(Tools.UpgradeCosts, 1), 150)
		eq(ToolRules.upgradeCost(Tools.UpgradeCosts, 2), 400)
		eq(ToolRules.upgradeCost(Tools.UpgradeCosts, 3), nil)
	end)
end)

H.finish("ToolRules")
