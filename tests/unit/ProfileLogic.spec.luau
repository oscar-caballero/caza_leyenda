--!strict
local H = require("../lib/harness")
local Types = require("../../src/ReplicatedStorage/Shared/Types")
local ProfileLogic = require("../../src/ServerScriptService/Services/ProfileLogic")

local Logic = ProfileLogic.new(Types)
local describe, it, eq, truthy = H.describe, H.it, H.eq, H.truthy

local function fresh(): { [string]: any }
	local p = Types.newProfile() :: any
	Logic.sanitize(p)
	return p
end

describe("migrate", function()
	it("v1 actual queda igual", function()
		local p = fresh()
		eq(Logic.migrate(p), "ok")
		eq(p.SchemaVersion, 1)
	end)
	it("sin SchemaVersion (plantilla nueva) se marca con la actual", function()
		local p = {} :: any
		eq(Logic.migrate(p), "ok")
		eq(p.SchemaVersion, Types.SCHEMA_VERSION)
	end)
	it("un perfil del futuro no se toca", function()
		local p = { SchemaVersion = 99, Seeds = 123 } :: any
		eq(Logic.migrate(p), "future")
		eq(p.SchemaVersion, 99)
		eq(p.Seeds, 123)
	end)
	it("versiones basura son inválidas", function()
		eq(Logic.migrate({ SchemaVersion = "1" } :: any), "invalid")
		eq(Logic.migrate({ SchemaVersion = 0 } :: any), "invalid")
		eq(Logic.migrate({ SchemaVersion = 1.5 } :: any), "invalid")
		eq(Logic.migrate({ SchemaVersion = 0 / 0 } :: any), "invalid")
	end)
end)

describe("sanitize", function()
	it("aplica topes de Semillas, nivel y herramientas", function()
		local p = fresh()
		p.Seeds = 10 ^ 9
		p.Level = 50
		p.ToolTiers.Honda = 7
		p.ToolTiers.Bazuca = 3
		Logic.sanitize(p)
		eq(p.Seeds, Types.Limits.MAX_SEEDS)
		eq(p.Level, Types.Limits.MAX_LEVEL)
		eq(p.ToolTiers.Honda, Types.Limits.MAX_TOOL_TIER)
		eq(p.ToolTiers.Bazuca, nil)
	end)
	it("NaN, negativos y decimales no sobreviven", function()
		local p = fresh()
		p.Seeds = 0 / 0
		p.Experience = -50
		p.Level = 2.7
		Logic.sanitize(p)
		eq(p.Seeds, 0)
		eq(p.Experience, 0)
		eq(p.Level, 2)
	end)
	it("ranuras inválidas o repetidas se corrigen", function()
		local p = fresh()
		p.Equipped = { Slot1 = "Honda", Slot2 = "Honda" }
		Logic.sanitize(p)
		truthy(p.Equipped.Slot1 ~= p.Equipped.Slot2, "ranuras distintas")
		p.Equipped = { Slot1 = "Bazuca", Slot2 = 5 }
		Logic.sanitize(p)
		eq(p.Equipped.Slot1, "Honda")
		eq(p.Equipped.Slot2, "Yoyo")
	end)
	it("bestiario solo con criaturas y capas conocidas", function()
		local p = fresh()
		p.Bestiary = {
			Llorona = { Layers = { Tradicion = true, Inventada = true } },
			Godzilla = { Layers = { Tradicion = true } },
			Chaneque = { Layers = {} },
		}
		Logic.sanitize(p)
		eq(p.Bestiary.Llorona.Layers.Tradicion, true)
		eq(p.Bestiary.Llorona.Layers.Inventada, nil)
		eq(p.Bestiary.Godzilla, nil)
		eq(p.Bestiary.Chaneque, nil, "entrada vacía se elimina")
	end)
	it("inventario: cantidades válidas y tope de stacks", function()
		local p = fresh()
		for i = 1, 150 do
			p.Inventory[string.format("item_%03d", i)] = 5
		end
		p.Inventory.item_001 = 1000
		p.Inventory.malo = -3
		Logic.sanitize(p)
		local n = 0
		for _ in p.Inventory do
			n += 1
		end
		eq(n, Types.Limits.MAX_INVENTORY_STACKS)
		eq(p.Inventory.item_001, Types.Limits.MAX_STACK)
		eq(p.Inventory.malo, nil)
	end)
	it("una misión completada deja de estar abierta", function()
		local p = fresh()
		p.CompletedQuests.llorona_01 = true
		p.QuestProgress.llorona_01 = 3
		p.QuestProgress.charro_01 = 2
		Logic.sanitize(p)
		eq(p.QuestProgress.llorona_01, nil)
		eq(p.QuestProgress.charro_01, 2)
	end)
	it("borra campos que no están en el esquema", function()
		local p = fresh()
		p.Admin = true
		Logic.sanitize(p)
		eq(p.Admin, nil)
	end)
end)

describe("mutate", function()
	it("si fn falla, el perfil queda intacto", function()
		local p = fresh()
		p.Seeds = 10
		local ok = Logic.mutate(p, function(d)
			d.Seeds = 999
			error("boom")
		end)
		eq(ok, false)
		eq(p.Seeds, 10)
	end)
	it("si fn devuelve false, no se aplica", function()
		local p = fresh()
		local ok, err = Logic.mutate(p, function(d)
			d.Level = 5
			return false
		end)
		eq(ok, false)
		eq(err, "mutate.aborted")
		eq(p.Level, 1)
	end)
	it("el resultado se sanitiza y es el mismo objeto", function()
		local p = fresh()
		local ref = p
		Logic.mutate(p, function(d)
			d.Seeds = 10 ^ 9
		end)
		eq(p, ref)
		eq(p.Seeds, Types.Limits.MAX_SEEDS)
	end)
end)

describe("grantReward", function()
	it("entrega una sola vez", function()
		local p = fresh()
		local function give(d)
			d.Seeds += 25
		end
		eq((Logic.grantReward(p, "quest:llorona_01", give)), true)
		local ok, err = Logic.grantReward(p, "quest:llorona_01", give)
		eq(ok, false)
		eq(err, "reward.alreadyClaimed")
		eq(p.Seeds, 25)
		eq(p.ClaimedRewards["quest:llorona_01"], true)
	end)
	it("si la entrega falla, no queda marcada", function()
		local p = fresh()
		Logic.grantReward(p, "quest:x", function()
			error("falló")
		end)
		eq(p.ClaimedRewards["quest:x"], nil)
		eq((Logic.grantReward(p, "quest:x", function(d)
			d.Seeds += 1
		end)), true)
	end)
	it("rechaza ids inválidos", function()
		eq((Logic.grantReward(fresh(), "", function() end)), false)
		eq((Logic.grantReward(fresh(), string.rep("a", 97), function() end)), false)
	end)
end)

describe("spendSeeds", function()
	it("cobra y aplica en un paso (mejora de honda a 50)", function()
		local p = fresh()
		p.Seeds = 60
		local ok = Logic.spendSeeds(p, 50, function(d)
			d.ToolTiers.Honda += 1
		end)
		eq(ok, true)
		eq(p.Seeds, 10)
		eq(p.ToolTiers.Honda, 1)
	end)
	it("sin Semillas suficientes no hace nada", function()
		local p = fresh()
		p.Seeds = 40
		local ok, err = Logic.spendSeeds(p, 50, function(d)
			d.ToolTiers.Honda += 1
		end)
		eq(ok, false)
		eq(err, "seeds.insufficient")
		eq(p.Seeds, 40)
		eq(p.ToolTiers.Honda, 0)
	end)
	it("si el efecto falla, no se cobra", function()
		local p = fresh()
		p.Seeds = 100
		Logic.spendSeeds(p, 50, function()
			error("falló")
		end)
		eq(p.Seeds, 100)
	end)
	it("rechaza montos raros", function()
		local p = fresh()
		p.Seeds = 100
		for _, bad in { 0, -5, 1.5, 0 / 0, math.huge } do
			eq((Logic.spendSeeds(p, bad, function() end)), false, `monto {bad}`)
		end
		eq(p.Seeds, 100)
	end)
end)

describe("toView", function()
	it("no expone ClaimedRewards ni metadatos y es una copia", function()
		local p = fresh()
		p.ClaimedRewards["quest:a"] = true
		local v = Logic.toView(p)
		eq(v.ClaimedRewards, nil)
		eq(v.SchemaVersion, nil)
		eq(v.LastSavedAt, nil)
		v.Seeds = 999
		eq(p.Seeds, 0)
	end)
end)

H.finish("ProfileLogic")
