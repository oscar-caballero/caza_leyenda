--!strict
--[[
	Config/Marana — Números de la Maraña (D-019). Internamente 0..100; el atributo
	OlvidoMeter del Character lleva meter/100 y el HUD lo muestra en 3 segmentos.
]]

export type Contact = {
	radius: number, -- studs entre la criatura y el jugador
	amount: number, -- Maraña que suma cada contacto
	cooldown: number, -- s entre contactos de LA MISMA criatura al mismo jugador
}

local Marana = {
	MAX = 100,
	-- Tope de llenado (suma de todas las criaturas) como token bucket:
	-- ráfaga de 20 (una embestida completa del Rumor) y recarga de 16/s,
	-- así el mínimo real para llenar es (100 - 20) / 16 = 5.0 s (D-019)
	FILL_BURST = 20,
	FILL_CAP_PER_SECOND = 16,
	DRAIN_DELAY = 3, -- s sin contacto antes de empezar a vaciarse
	DRAIN_PER_SECOND = 10,
	SAFE_DRAIN_PER_SECOND = 25, -- junto a un farol encendido
	RESOLVED_BONUS = 15, -- se resta al disipar una criatura en la que ayudaste
	TUTORIAL_CAP = 66,

	TANGLED_SECONDS = 5,
	IMMUNE_AFTER = 2, -- s sin ganar Maraña tras salir de Enredado
	AFTER_TANGLE = 40, -- valor al salir
	TANGLED_WALKSPEED = 8,

	RESCUE_RADIUS = 6, -- studs
	RESCUE_SECONDS = 2, -- quieto a su lado y sin disparar

	SEGMENTS = 3, -- el HUD muestra 3 segmentos

	Contacts = {
		PolillaPapel = { radius = 4, amount = 8, cooldown = 1.2 },
		Rumor = { radius = 10, amount = 20, cooldown = 2.5 }, -- "embestida"
	} :: { [string]: Contact },
}

return table.freeze(Marana)
