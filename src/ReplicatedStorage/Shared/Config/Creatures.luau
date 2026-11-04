--!strict
--[[
	Config/Creatures — Datos de criaturas (biblia §5 y §6).

	Regla de coherencia: SOLO las de nivel 3 (criaturas del Olvido) reciben daño.
	Las de nivel 1 y 2 se resuelven con acertijos; las herramientas no les hacen nada.
]]

export type CreatureDef = {
	level: number, -- 1 creencia viva · 2 leyenda pública · 3 criatura del Olvido
	maxOlvido: number?, -- solo nivel 3: puntos de Olvido que hay que disipar
	preferred: string?, -- herramienta preferida (+25 %)
	alternative: string?, -- alternativa viable
}

local Creatures: { [string]: CreatureDef } = {
	Chaneque = { level = 1 },
	Llorona = { level = 2 },
	CharroNegro = { level = 2 },
	PolillaPapel = { level = 3, maxOlvido = 30, preferred = "Matraca", alternative = "Honda" },
	Rumor = { level = 3, maxOlvido = 400, preferred = "Honda", alternative = "Yoyo" },
}

return table.freeze(Creatures)
