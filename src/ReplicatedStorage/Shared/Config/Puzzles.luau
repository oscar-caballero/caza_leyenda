--!strict
--[[
	Config/Puzzles — Acertijos físicos: se resuelven ACTIVANDO objetos con las herramientas.

	  sequence   activar `targets` en ese orden. Un objetivo equivocado = fallo:
	             las polillas se comen la pista (biblia §5) y hay que disiparlas para recuperarla
	  together   activar todos los `targets` dentro de `window` segundos
	             (cooperativo, pero resoluble en solitario: D-005)

	La pista (`clue`) muestra el orden con FORMAS (▲ ● ■), no solo colores (D-011).
]]

export type PuzzleDef = {
	kind: string, -- "sequence" | "together"
	anchor: string, -- NetId del centro del acertijo
	clue: string?, -- NetId del letrero con el orden
	targets: { string },
	failSpawn: { creature: string, count: number }?,
	window: number?,
}

local Puzzles: { [string]: PuzzleDef } = {
	m1_manivelas = {
		kind = "sequence",
		anchor = "m1_manivelas",
		clue = "m1_pista",
		targets = { "m1_manivela_circulo", "m1_manivela_triangulo", "m1_manivela_cuadro" },
		failSpawn = { creature = "PolillaPapel", count = 2 },
	},
	m2_senales = {
		kind = "sequence",
		anchor = "m2_senales",
		clue = "m2_pista",
		targets = { "m2_senal_cuadro", "m2_senal_triangulo", "m2_senal_circulo" },
		failSpawn = { creature = "PolillaPapel", count = 2 },
	},
	m3_compuertas = {
		kind = "together",
		anchor = "m3_compuertas",
		targets = { "m3_compuerta_izq", "m3_compuerta_der" },
		window = 4,
	},
}

return Puzzles
