--!strict
--[[
	Config/Tools — Números de las herramientas (cliente y servidor lo leen; solo el servidor decide).

	Costos de mejora: D-007 (aprobados). Daño/cooldown: valores INICIALES que cumplen
	las reglas de D-007 (DPS de herramientas dentro de ±10 %, +25 % con la preferida);
	se ajustan con telemetría. La resortera (D-013) da disparo rápido con DPS ×1.1.

	DPS base:  Honda 10 / 0.60 = 16.7   ·   Yoyo 14 / 0.85 = 16.5
]]

export type ToolDef = {
	enabled: boolean, -- la matraca llega en las semanas 7–10
	damage: number, -- puntos de Olvido que disipa por golpe
	cooldown: number, -- s
	range: number, -- studs
	radius: number, -- radio del spherecast (apuntado amable para niños en celular)
	activatesTag: string, -- tag de CollectionService que esta herramienta activa
	color: { number }, -- RGB 0..255 (sin Color3 para cargar en Lune). D-004: cada efecto se distingue por color y forma
}

local Tools = {
	UpgradeCosts = { 50, 150, 400 }, -- D-007: costo para pasar del nivel i-1 al i
	TierDamageBonus = 0.15, -- +15 % de daño por nivel de mejora
	PreferredBonus = 0.25, -- D-007: +25 % con la herramienta preferida de la criatura

	Resortera = {
		duration = 8, -- s
		cooldownMult = 0.5, -- dispara el doble de rápido...
		damageMult = 0.55, -- ...con menos daño por golpe (DPS ×1.1)
		respawn = 30, -- s hasta que reaparece el power-up
	},

	Defs = {
		Honda = {
			enabled = true,
			damage = 10,
			cooldown = 0.6,
			range = 90,
			radius = 1.5,
			activatesTag = "Activable",
			color = { 255, 140, 40 },
		},
		Yoyo = {
			enabled = true,
			damage = 14,
			cooldown = 0.85,
			range = 20,
			radius = 2,
			activatesTag = "Giratorio",
			color = { 40, 200, 230 },
		},
		Matraca = {
			enabled = false,
			damage = 0,
			cooldown = 1.5,
			range = 12,
			radius = 12,
			activatesTag = "Sonoro",
			color = { 200, 90, 220 },
		},
	} :: { [string]: ToolDef },
}

return table.freeze(Tools)
