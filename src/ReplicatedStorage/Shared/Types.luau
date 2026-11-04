--!strict
--[[
	Shared/Types — Contrato de tipos del juego (APROBADO v1.1, 2026-11-03 — D-016, enmienda D-019)

	ESTADO: APROBADO y CONGELADO (D-016). Queda
	CONGELADO: cualquier cambio requiere una decisión nueva en docs/decisiones.md
	y, si toca el perfil, subir SCHEMA_VERSION y escribir su migración.

	Fuentes: docs/biblia-del-olvido.md v1.0 y docs/decisiones.md (D-004, D-007, D-009, D-013, D-014).
]]

local Types = {}

------------------------------------------------------------------------
-- Identificadores cerrados (el servidor rechaza cualquier otro valor)
------------------------------------------------------------------------

export type ToolId = "Honda" | "Yoyo" | "Matraca"
export type PowerUpId = "Resortera" -- power-up momentáneo de la honda; no ocupa ranura
export type CreatureId = "Chaneque" | "Llorona" | "CharroNegro" | "PolillaPapel" | "Rumor"

-- Nivel cultural (biblia §5): 1 creencia viva, 2 leyenda pública, 3 criatura del Olvido
export type CreatureLevel = number -- 1 | 2 | 3

-- Etiqueta de fuente visible en el bestiario (D-003)
export type SourceTag = "Pergamino" | "Mapa" | "Lapiz"

-- Tres capas de cada leyenda (D-014)
export type LoreLayer = "Tradicion" | "RumorOlvido" | "Recuperada"

-- Ranuras equipadas (D-004: 2 ranuras; cambio gratis solo en el pueblo)
export type ToolSlot = number -- 1 | 2

-- Ids abiertos: se validan contra Shared/Config, no contra el tipo
export type QuestId = string -- p. ej. "llorona_01"
export type FragmentId = string -- página del bestiario, p. ej. "llorona.recuperada.1"
export type RewardId = string -- "<fuente>:<id>", p. ej. "quest:llorona_01"
export type ItemId = string
export type PuzzleId = string
export type NetId = string -- atributo "NetId" de una instancia del mundo registrada por el servidor
export type QuickChatId = number -- 1..6 (D-004: 6 frases fijas, sin texto libre)

-- Anotación en el local (no cast): Luau valida cada literal contra la unión
local TOOL_IDS: { ToolId } = { "Honda", "Yoyo", "Matraca" }
local CREATURE_IDS: { CreatureId } = { "Chaneque", "Llorona", "CharroNegro", "PolillaPapel", "Rumor" }
local LORE_LAYERS: { LoreLayer } = { "Tradicion", "RumorOlvido", "Recuperada" }
local SOURCE_TAGS: { SourceTag } = { "Pergamino", "Mapa", "Lapiz" }

Types.ToolIds = table.freeze(TOOL_IDS)
Types.CreatureIds = table.freeze(CREATURE_IDS)
Types.LoreLayers = table.freeze(LORE_LAYERS)
Types.SourceTags = table.freeze(SOURCE_TAGS)

------------------------------------------------------------------------
-- Perfil persistente (ProfileStore, D-009)
-- Se guarda: progreso, inventario, colecciones y equipamiento.
-- NO se guarda: posición, estado de encuentros, power-ups activos.
------------------------------------------------------------------------

Types.SCHEMA_VERSION = 1

Types.Limits = table.freeze({
	MAX_LEVEL = 6, -- D-007
	MAX_SEEDS = 99_999,
	MAX_TOOL_TIER = 3, -- D-007: 3 mejoras (50 / 150 / 400 Semillas)
	MAX_INVENTORY_STACKS = 100,
	MAX_STACK = 99,
})

-- Claves de texto (no 1/2) para que DataStore nunca lo serialice como arreglo con huecos
export type EquippedSlots = {
	Slot1: ToolId,
	Slot2: ToolId,
}

export type ClothingSlots = {
	Appearance: ItemId?, -- solo visual (transfiguración, D-007)
	Effect: ItemId?, -- efecto por entorno, tope ±15 %
}

export type BestiaryEntry = {
	Layers: { [LoreLayer]: boolean }, -- capas desbloqueadas
}

export type Profile = {
	SchemaVersion: number,

	-- Progresión
	Level: number, -- 1..MAX_LEVEL
	Experience: number, -- curva 100·n^1.5 en Config
	TutorialDone: boolean,

	-- Economía (D-007): una sola moneda; los fragmentos no se intercambian
	Seeds: number, -- 0..MAX_SEEDS
	Fragments: { [FragmentId]: true },

	-- Herramientas
	ToolTiers: { [ToolId]: number }, -- 0..MAX_TOOL_TIER
	Equipped: EquippedSlots,

	-- Colecciones y misiones
	Bestiary: { [CreatureId]: BestiaryEntry },
	QuestProgress: { [QuestId]: number }, -- paso actual de misiones abiertas
	CompletedQuests: { [QuestId]: true },

	-- Idempotencia de recompensas (D-009): una RewardId se entrega una sola vez
	ClaimedRewards: { [RewardId]: true },

	-- Inventario con tope
	Inventory: { [ItemId]: number },
	Clothing: ClothingSlots,

	LastSavedAt: number, -- os.time() del servidor
}

-- Lo que el cliente ve de su propio perfil (ProfileSync). Sin ClaimedRewards.
export type ProfileView = {
	Level: number,
	Experience: number,
	TutorialDone: boolean,
	Seeds: number,
	Fragments: { [FragmentId]: true },
	ToolTiers: { [ToolId]: number },
	Equipped: EquippedSlots,
	Bestiary: { [CreatureId]: BestiaryEntry },
	QuestProgress: { [QuestId]: number },
	CompletedQuests: { [QuestId]: true },
	Inventory: { [ItemId]: number },
	Clothing: ClothingSlots,
}

function Types.newProfile(): Profile
	return {
		SchemaVersion = Types.SCHEMA_VERSION,
		Level = 1,
		Experience = 0,
		TutorialDone = false,
		Seeds = 0,
		Fragments = {},
		ToolTiers = { Honda = 0, Yoyo = 0, Matraca = 0 },
		Equipped = { Slot1 = "Honda", Slot2 = "Yoyo" }, -- la matraca se desbloquea en semanas 7–10
		Bestiary = {},
		QuestProgress = {},
		CompletedQuests = {},
		ClaimedRewards = {},
		Inventory = {},
		Clothing = {},
		LastSavedAt = 0,
	}
end

------------------------------------------------------------------------
-- Estado de mundo replicado por ATRIBUTOS (no por Remotes)
-- El servidor escribe; el cliente solo lee y pinta.
------------------------------------------------------------------------

Types.Attributes = table.freeze({
	NetId = "NetId", -- string: id estable de la instancia
	CreatureId = "CreatureId", -- string: CreatureId
	-- number 0..1. En criaturas: medidor de Olvido (no barra de vida, D-004).
	-- En el Character del jugador: la Maraña (D-019); 1 = Enredado.
	OlvidoMeter = "OlvidoMeter",
	EncounterState = "EncounterState", -- "Idle" | "Active" | "Resolved"
})

Types.Tags = table.freeze({ -- CollectionService (D-005)
	Activable = "Activable",
	Sonoro = "Sonoro",
	Giratorio = "Giratorio",
	PowerUpResortera = "PowerUpResortera",
	ZonaPueblo = "ZonaPueblo", -- única zona donde se puede cambiar de herramienta
})

------------------------------------------------------------------------
-- Avisos al cliente: siempre por CLAVE de texto, nunca texto libre (D-009)
------------------------------------------------------------------------

export type NoticeKey =
	"Reward.Seeds"
	| "Reward.Fragment"
	| "Quest.Step"
	| "Quest.Completed"
	| "Puzzle.Failed" -- las polillas se comen una pista (biblia §5)
	| "Puzzle.Solved"
	| "Tool.Upgraded"
	| "Tool.NotEnoughSeeds"
	| "Tool.EquipOnlyInTown"
	| "Level.Up"
	| "Player.Tangled" -- D-019: la Maraña se llenó
	| "Player.Freed" -- D-019: args.reason = "time" | "rescue"

export type PuzzleResult = "Solved" | "Failed" | "Rejected"

return table.freeze(Types)
