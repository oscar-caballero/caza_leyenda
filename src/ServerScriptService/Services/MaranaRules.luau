--!strict
--[[
	MaranaRules — Lógica pura de la Maraña (D-019). Sin servicios de Roblox: se prueba en Lune.

	Un `State` por jugador. El servicio llama, en este orden por tick:
	  contact(...)  por cada criatura que toca al jugador
	  tick(...)     una vez: vaciado, entrada y salida de Enredado, rescate
]]

export type State = {
	meter: number, -- 0..MAX
	budget: number, -- cuánto puede ganar ahora mismo (token bucket del tope de llenado)
	budgetAt: number, -- última recarga del bucket
	lastContact: number,
	lastHitBy: { [any]: number }, -- criatura → último contacto (cooldown por criatura)
	tangledUntil: number, -- > now mientras está Enredado
	immuneUntil: number,
	cap: number, -- MAX, o TUTORIAL_CAP en el tutorial
	rescueSince: { [any]: number }, -- rescatador → desde cuándo está a su lado sin disparar
}

export type Event = "tangled" | "freedByTime" | "freedByRescue" | nil

local MaranaRules = {}

function MaranaRules.new(cfg: any, _now: number): State
	return {
		meter = 0,
		budget = cfg.FILL_BURST,
		budgetAt = _now,
		lastContact = -math.huge,
		lastHitBy = {},
		tangledUntil = 0,
		immuneUntil = 0,
		cap = cfg.MAX,
		rescueSince = {},
	}
end

local function refill(cfg: any, s: State, now: number)
	local elapsed = math.max(0, now - s.budgetAt)
	s.budget = math.min(cfg.FILL_BURST, s.budget + elapsed * cfg.FILL_CAP_PER_SECOND)
	s.budgetAt = now
end

function MaranaRules.isTangled(s: State, now: number): boolean
	return now < s.tangledUntil
end

-- Contacto de una criatura. Devuelve lo que realmente sumó (0 si no aplica).
function MaranaRules.contact(
	cfg: any,
	s: State,
	creature: any,
	contact: { amount: number, cooldown: number },
	now: number
): number
	if now < s.tangledUntil or now < s.immuneUntil then
		return 0
	end
	local last = s.lastHitBy[creature]
	if last and now - last < contact.cooldown then
		return 0
	end
	refill(cfg, s, now)
	local gain = math.min(contact.amount, s.budget, s.cap - s.meter)
	s.lastHitBy[creature] = now
	s.lastContact = now
	if gain <= 0 then
		return 0
	end
	s.budget -= gain
	s.meter += gain
	return gain
end

-- Ayudó a disipar una criatura: resta RESOLVED_BONUS (no saca de Enredado)
function MaranaRules.resolved(cfg: any, s: State, now: number)
	if now < s.tangledUntil then
		return
	end
	s.meter = math.max(0, s.meter - cfg.RESOLVED_BONUS)
end

--[[
	Avanza dt segundos.
	  safe        ¿está junto a un farol encendido?
	  rescuers    { [rescatador]: { near: boolean, firedAt: number } }
	Devuelve el evento que ocurrió en este tick, si alguno.
]]
function MaranaRules.tick(
	cfg: any,
	s: State,
	dt: number,
	now: number,
	safe: boolean,
	rescuers: { [any]: { near: boolean, firedAt: number } }
): Event
	if now < s.tangledUntil then
		-- Rescate: quedarse cerca sin disparar durante RESCUE_SECONDS
		for who, r in rescuers do
			local since = s.rescueSince[who]
			if r.near and r.firedAt < (since or now) then
				if since == nil then
					s.rescueSince[who] = now
				elseif now - since >= cfg.RESCUE_SECONDS then
					MaranaRules.free(cfg, s, now)
					return "freedByRescue"
				end
			else
				s.rescueSince[who] = nil
			end
		end
		return nil
	end

	if s.tangledUntil > 0 and s.meter >= cfg.MAX then
		-- Se acabó el tiempo de Enredado
		MaranaRules.free(cfg, s, now)
		return "freedByTime"
	end

	if s.meter >= cfg.MAX then
		s.meter = cfg.MAX
		s.tangledUntil = now + cfg.TANGLED_SECONDS
		table.clear(s.rescueSince)
		return "tangled"
	end

	local drain = 0
	if safe then
		drain = cfg.SAFE_DRAIN_PER_SECOND
	elseif now - s.lastContact >= cfg.DRAIN_DELAY then
		drain = cfg.DRAIN_PER_SECOND
	end
	s.meter = math.max(0, math.min(s.cap, s.meter - drain * dt))
	return nil
end

function MaranaRules.free(cfg: any, s: State, now: number)
	s.tangledUntil = 0
	s.meter = math.min(cfg.AFTER_TANGLE, s.cap)
	s.immuneUntil = now + cfg.IMMUNE_AFTER
	s.lastContact = now
	table.clear(s.rescueSince)
end

-- Segmentos llenos para el HUD (0..SEGMENTS)
function MaranaRules.segments(cfg: any, meter01: number): number
	return math.clamp(math.floor(meter01 * cfg.SEGMENTS + 1e-9), 0, cfg.SEGMENTS)
end

return table.freeze(MaranaRules)
