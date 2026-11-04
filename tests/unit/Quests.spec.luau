--!strict
local H = require("../lib/harness")
local R = require("../../src/ReplicatedStorage/Shared/QuestRules")
local Quests = require("../../src/ReplicatedStorage/Shared/Config/Quests")
local Puzzles = require("../../src/ReplicatedStorage/Shared/Config/Puzzles")
local Creatures = require("../../src/ReplicatedStorage/Shared/Config/Creatures")

local describe, it, eq, truthy = H.describe, H.it, H.eq, H.truthy

local function progress(quest: string, step: number?): R.Progress
	return { quest = quest, step = step or 1, count = 0, seen = {} }
end

describe("QuestRules", function()
	it("la siguiente misión es la primera no completada", function()
		eq(R.nextQuest(Quests.Order, {}), "tutorial")
		eq(R.nextQuest(Quests.Order, { tutorial = true }), "m1")
		eq(R.nextQuest(Quests.Order, { tutorial = true, m1 = true, m2 = true, m3 = true }), nil)
	end)
	it("tutorial: tres faroles DISTINTOS (prefijo plaza_farol)", function()
		local steps = Quests.Defs.tutorial.steps
		local p = progress("tutorial", 2)
		eq(R.apply(steps, p, { kind = "activate", target = "plaza_farol_1" }), "count")
		eq(
			R.apply(steps, p, { kind = "activate", target = "plaza_farol_1" }),
			"none",
			"el mismo farol no cuenta dos veces"
		)
		eq(R.apply(steps, p, { kind = "activate", target = "farol_kiosco" }), "none", "otro objeto no cuenta")
		eq(R.apply(steps, p, { kind = "activate", target = "plaza_farolX" }), "none", "el prefijo exige _")
		eq(R.apply(steps, p, { kind = "activate", target = "plaza_farol_2" }), "count")
		eq(R.apply(steps, p, { kind = "activate", target = "plaza_farol_3" }), "step")
		eq(p.step, 3)
	end)
	it("el farol del kiosco exige la resortera activa", function()
		local p = progress("tutorial", 5)
		local steps = Quests.Defs.tutorial.steps
		eq(R.apply(steps, p, { kind = "activate", target = "farol_kiosco", boosted = false }), "none")
		eq(R.apply(steps, p, { kind = "activate", target = "farol_kiosco", boosted = true }), "completed")
	end)
	it("M1: 9 polillas y luego el acertijo", function()
		local steps = Quests.Defs.m1.steps
		local p = progress("m1")
		for _ = 1, 8 do
			eq(R.apply(steps, p, { kind = "dissipate", creature = "PolillaPapel" }), "count")
		end
		eq(R.apply(steps, p, { kind = "dissipate", creature = "Rumor" }), "none")
		eq(R.apply(steps, p, { kind = "dissipate", creature = "PolillaPapel" }), "step")
		eq(R.apply(steps, p, { kind = "puzzle", puzzle = "m2_senales" }), "none", "otro acertijo")
		eq(R.apply(steps, p, { kind = "puzzle", puzzle = "m1_manivelas" }), "completed")
	end)
	it("un evento de otro tipo nunca avanza", function()
		local p = progress("m2")
		eq(R.apply(Quests.Defs.m2.steps, p, { kind = "activate", target = "camino_inicio" }), "none")
		eq(R.apply(Quests.Defs.m2.steps, p, { kind = "reach", target = "camino_inicio" }), "step")
	end)
end)

describe("Config de misiones (D-019)", function()
	local function words(s: string): number
		local n = 0
		for _ in string.gmatch(s, "%S+") do
			n += 1
		end
		return n
	end
	it("cada pista tiene máximo 8 palabras (D-006)", function()
		for id, def in Quests.Defs do
			for i, step in def.steps do
				truthy(words(step.hint) <= 8, `{id}[{i}] "{step.hint}" tiene {words(step.hint)} palabras`)
			end
		end
	end)
	it("todas las misiones del orden existen y tienen pasos", function()
		for _, id in Quests.Order do
			truthy(Quests.Defs[id] and #Quests.Defs[id].steps > 0, id)
		end
	end)
	it("los acertijos y criaturas referidos existen", function()
		for id, def in Quests.Defs do
			for i, step in def.steps do
				if step.kind == "puzzle" then
					truthy(Puzzles[step.puzzle], `{id}[{i}] acertijo {step.puzzle}`)
				elseif step.kind == "dissipate" then
					local c = Creatures[step.creature]
					truthy(c and c.level == 3, `{id}[{i}] solo se disipan criaturas de nivel 3`)
				end
			end
		end
	end)
	it("ninguna misión pide combatir al Chaneque, la Llorona o el Charro", function()
		for id, def in Quests.Defs do
			for _, step in def.steps do
				truthy(not (step.kind == "dissipate" and Creatures[step.creature].level < 3), id)
			end
		end
	end)
	it("recompensas aprobadas en D-019", function()
		eq(Quests.Defs.m1.rewards.xp, 60)
		eq(Quests.Defs.m1.rewards.seeds, 30)
		eq(Quests.Defs.m2.rewards.xp, 80)
		eq(Quests.Defs.m2.rewards.seeds, 50)
		eq(Quests.Defs.m3.rewards.xp, 100)
		eq(Quests.Defs.tutorial.rewards, nil)
		eq(Quests.Defs.tutorial.maranaCap, 66)
	end)
	it("la capa Tradición del Chaneque no se publica sin fuente verificada", function()
		local layers = Quests.Defs.m2.rewards.bestiary.Chaneque
		eq(#layers, 0)
	end)
	it("acertijos: secuencias con castigo de polillas y 'together' con ventana", function()
		for id, pz in Puzzles do
			truthy(#pz.targets >= 2, id)
			if pz.kind == "sequence" then
				truthy(pz.clue and pz.failSpawn, `{id} necesita pista y castigo`)
			else
				truthy(pz.window and pz.window > 0, `{id} ventana`)
			end
		end
	end)
end)

H.finish("Quests")
