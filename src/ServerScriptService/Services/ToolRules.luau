--!strict
--[[
	ToolRules — Reglas puras de herramientas (sin servicios de Roblox; se prueba en Lune).
	Recibe la configuración como argumento.
]]

local ToolRules = {}

export type Equipped = { Slot1: string, Slot2: string }

function ToolRules.isEquipped(equipped: Equipped, tool: string): boolean
	return equipped.Slot1 == tool or equipped.Slot2 == tool
end

-- Pone `tool` en `slot`; si ya estaba en la otra ranura, las intercambia.
function ToolRules.equip(equipped: Equipped, slot: number, tool: string): Equipped
	local s1, s2 = equipped.Slot1, equipped.Slot2
	if slot == 1 then
		if s2 == tool then
			s2 = s1
		end
		s1 = tool
	else
		if s1 == tool then
			s1 = s2
		end
		s2 = tool
	end
	return { Slot1 = s1, Slot2 = s2 }
end

function ToolRules.cooldown(def: { cooldown: number }, boosted: boolean, resortera: { cooldownMult: number }): number
	return if boosted then def.cooldown * resortera.cooldownMult else def.cooldown
end

-- Solo nivel 3 recibe daño (biblia §5)
function ToolRules.canDamage(creature: { level: number }?): boolean
	return creature ~= nil and creature.level == 3
end

function ToolRules.damage(
	config: any,
	tool: string,
	tier: number,
	boosted: boolean,
	creature: { preferred: string? }?
): number
	local def = config.Defs[tool]
	local dmg = def.damage * (1 + config.TierDamageBonus * tier)
	if boosted then
		dmg *= config.Resortera.damageMult
	end
	if creature and creature.preferred == tool then
		dmg *= 1 + config.PreferredBonus
	end
	return dmg
end

-- Costo para subir desde `tier`; nil si ya está al máximo
function ToolRules.upgradeCost(costs: { number }, tier: number): number?
	return costs[tier + 1]
end

return table.freeze(ToolRules)
