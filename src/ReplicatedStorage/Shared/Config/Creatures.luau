--!strict
--[[
	Config/Creatures — Datos de criaturas (biblia §5 y §6).

	Regla de coherencia: SOLO las de nivel 3 (criaturas del Olvido) reciben daño.
	Las de nivel 1 y 2 se resuelven con acertijos; las herramientas no les hacen nada.

	`rewards` es ECONOMÍA: requiere aprobación humana (D-010). Valores PROPUESTOS:
	  xp          se da cada vez a quien ayudó (≥10 % del daño)
	  firstSeeds  solo la primera vez que el jugador disipa ESA criatura (RewardId "defeat:<NetId>")
]]

export type Rewards = { xp: number, firstSeeds: number }

export type CreatureDef = {
	level: number, -- 1 creencia viva · 2 leyenda pública · 3 criatura del Olvido
	-- Solo nivel 3:
	maxOlvido: number?, -- puntos de Olvido a disipar con 1 jugador
	preferred: string?, -- herramienta preferida (+25 %)
	alternative: string?, -- alternativa viable
	hitRadius: number?, -- studs: esfera de impacto para el rebobinado
	speed: number?, -- studs/s
	fleeSpeed: number?, -- studs/s al huir tras un golpe
	fleeSeconds: number?, -- 0 = no huye
	aggroRadius: number?, -- distancia a la que se activa el encuentro
	leashRadius: number?, -- no se aleja más que esto de su punto de origen
	keepDistance: number?, -- distancia a la que se queda del jugador
	respawn: number?, -- s tras disiparse
	rewards: Rewards?,
}

local Creatures: { [string]: CreatureDef } = {
	Chaneque = { level = 1 },
	Llorona = { level = 2 },
	CharroNegro = { level = 2 },

	-- Enemigo común: revolotea cerca, huye al recibir un golpe (el yo-yo la frena)
	PolillaPapel = {
		level = 3,
		maxOlvido = 30,
		preferred = "Matraca",
		alternative = "Honda",
		hitRadius = 2,
		speed = 9,
		fleeSpeed = 16,
		fleeSeconds = 1.5,
		aggroRadius = 30,
		leashRadius = 25,
		keepDistance = 6,
		respawn = 8,
		rewards = { xp = 5, firstSeeds = 0 },
	},

	-- Enemigo fuerte de la región: lento, se acerca y no huye
	Rumor = {
		level = 3,
		maxOlvido = 400,
		preferred = "Honda",
		alternative = "Yoyo",
		hitRadius = 5,
		speed = 4,
		fleeSpeed = 4,
		fleeSeconds = 0,
		aggroRadius = 40,
		leashRadius = 30,
		keepDistance = 9,
		respawn = 30,
		rewards = { xp = 60, firstSeeds = 40 },
	},
}

return table.freeze(Creatures)
