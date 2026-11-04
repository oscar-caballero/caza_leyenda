--!nonstrict
--[[
	Config/Quests — Tutorial y misiones de la vertical slice (D-019).

	Las pistas (`hint`) son texto fijo del juego: máx. 8 palabras (D-006).
	Recompensas APROBADAS en D-019. RewardId = "quest:<id>" (idempotente).

	Nota: M2 usaba Activable + Sonoro, pero lo Sonoro lo activa la matraca, que llega en las
	semanas 7–10. Mientras tanto M2 usa Activable (honda) y la pista se lee por forma.
]]

-- La capa "Tradición" del Chaneque solo se publica con fuente verificada (D-019)
local CHANEQUE_SOURCE_VERIFIED = false

local Quests = {
	Order = { "tutorial", "m1", "m2", "m3" },

	Defs = {
		tutorial = {
			title = "Los faroles de la plaza",
			maranaCap = 66, -- en el tutorial la Maraña nunca se llena
			setsTutorialDone = true,
			steps = {
				{ kind = "reach", target = "farol_t1", radius = 8, hint = "Camina hasta el farol" },
				{ kind = "activate", target = "plaza_farol", count = 3, hint = "Enciende tres faroles con la honda" },
				{ kind = "activate", target = "pagina_pregon", hint = "Recupera la página con el yo-yo" },
				{
					kind = "dissipate",
					creature = "PolillaPapel",
					count = 3,
					hint = "Disipa las polillas de papel",
					spawn = { creature = "PolillaPapel", count = 3, at = "tutorial_polillas" },
				},
				{
					kind = "activate",
					target = "farol_kiosco",
					boosted = true,
					hint = "Toma la resortera y enciende el kiosco",
				},
			},
			rewards = nil,
		},

		m1 = {
			title = "Colores robados",
			steps = {
				{
					kind = "dissipate",
					creature = "PolillaPapel",
					count = 9,
					hint = "Disipa los enjambres de la plaza",
					spawn = {
						creature = "PolillaPapel",
						count = 3,
						at = { "m1_enjambre_1", "m1_enjambre_2", "m1_enjambre_3" },
					},
				},
				{ kind = "puzzle", puzzle = "m1_manivelas", hint = "Gira las manivelas en orden" },
			},
			rewards = {
				xp = 60,
				seeds = 30,
				fragments = { "polilla.recuperada.1" },
				bestiary = { PolillaPapel = { "RumorOlvido", "Recuperada" } },
			},
		},

		m2 = {
			title = "Señales del camino",
			steps = {
				{ kind = "reach", target = "camino_inicio", radius = 10, hint = "Sigue el camino al bosque" },
				{ kind = "puzzle", puzzle = "m2_senales", hint = "Activa las señales en orden" },
				{ kind = "reach", target = "chaneque", radius = 8, hint = "Saluda al Chaneque" },
			},
			rewards = {
				xp = 80,
				seeds = 50,
				fragments = { "chaneque.encuentro.1" },
				bestiary = { Chaneque = if CHANEQUE_SOURCE_VERIFIED then { "Tradicion" } else {} },
			},
		},

		m3 = {
			title = "Lo que todos repiten",
			steps = {
				{ kind = "reach", target = "rio_orilla", radius = 12, hint = "Baja a la orilla del río" },
				{
					kind = "dissipate",
					creature = "Rumor",
					hint = "Disipa al Rumor entre todos",
					spawn = { creature = "Rumor", count = 1, at = "rio_rumor", shared = true },
				},
				{ kind = "puzzle", puzzle = "m3_compuertas", hint = "Abre las dos compuertas a la vez" },
			},
			rewards = {
				xp = 100,
				seeds = 0,
				fragments = { "rumor.recuperada.1" },
				bestiary = { Rumor = { "RumorOlvido", "Recuperada" } },
			},
		},
	} :: { [string]: any }, -- pasos heterogéneos: la forma la valida tests/unit/Quests.spec
}

return Quests
