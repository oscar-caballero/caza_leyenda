--!strict
--[[
	QuestRules — Lógica pura de misiones (cliente y servidor; se prueba en Lune).

	Un paso se cumple con eventos del SERVIDOR (D-009), nunca con algo que diga el cliente:
	  { kind = "reach",     target = NetId }                  llegar cerca de un lugar
	  { kind = "activate",  target = NetId, boosted = bool? } activar un objeto con su herramienta
	                         (target "plaza_farol" acepta "plaza_farol_1", "plaza_farol_2"...;
	                          con count > 1 cada objeto cuenta una sola vez)
	  { kind = "dissipate", creature = CreatureId }           ayudar a disipar una criatura
	  { kind = "puzzle",    puzzle = NetId }                  resolver un acertijo
]]

export type Step = {
	kind: string,
	target: string?,
	creature: string?,
	puzzle: string?,
	boosted: boolean?,
	count: number?,
	radius: number?,
	hint: string,
	spawn: any?,
}

export type Event = {
	kind: string,
	target: string?,
	creature: string?,
	puzzle: string?,
	boosted: boolean?,
}

export type Progress = { quest: string, step: number, count: number, seen: { [string]: boolean } }

local QuestRules = {}

-- Primera misión del orden que no esté completada
function QuestRules.nextQuest(order: { string }, completed: { [string]: any }): string?
	for _, id in order do
		if not completed[id] then
			return id
		end
	end
	return nil
end

local function targetMatches(want: string?, got: string?): boolean
	if want == nil or got == nil then
		return false
	end
	return got == want or string.sub(got, 1, #want + 1) == want .. "_"
end

function QuestRules.matches(step: Step, ev: Event): boolean
	if step.kind ~= ev.kind then
		return false
	end
	if step.kind == "reach" or step.kind == "activate" then
		if not targetMatches(step.target, ev.target) then
			return false
		end
		if step.boosted and not ev.boosted then
			return false
		end
		return true
	elseif step.kind == "dissipate" then
		return step.creature == ev.creature
	elseif step.kind == "puzzle" then
		return step.puzzle == ev.puzzle
	end
	return false
end

--[[
	Aplica un evento. Devuelve:
	  "none"       no aplica
	  "count"      avanzó el contador del paso
	  "step"       pasó al siguiente paso
	  "completed"  terminó la misión
]]
function QuestRules.apply(steps: { Step }, p: Progress, ev: Event): string
	local step = steps[p.step]
	if step == nil or not QuestRules.matches(step, ev) then
		return "none"
	end
	if (step.count or 1) > 1 and ev.target then
		if p.seen[ev.target] then
			return "none" -- el mismo farol no cuenta dos veces
		end
		p.seen[ev.target] = true
	end
	p.count += 1
	if p.count < (step.count or 1) then
		return "count"
	end
	p.count = 0
	table.clear(p.seen)
	p.step += 1
	if p.step > #steps then
		return "completed"
	end
	return "step"
end

return table.freeze(QuestRules)
