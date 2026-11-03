--!strict
local H = require("../lib/harness")
local RateLimiter = require("../../src/ReplicatedStorage/Shared/Net/RateLimiter")

local describe, it, eq = H.describe, H.it, H.eq

local function fakeClock()
	local t = 0
	return function()
		return t
	end, function(dt: number)
		t += dt
	end
end

describe("RateLimiter", function()
	it("permite la ráfaga y luego corta", function()
		local now = fakeClock()
		local rl = RateLimiter.new({ burst = 3, perSecond = 1 }, now)
		eq(rl:take(1), true)
		eq(rl:take(1), true)
		eq(rl:take(1), true)
		eq(rl:take(1), false, "el cuarto en el mismo instante")
	end)

	it("recarga con el tiempo sin pasar del burst", function()
		local now, advance = fakeClock()
		local rl = RateLimiter.new({ burst = 2, perSecond = 1 }, now)
		rl:take(1)
		rl:take(1)
		eq(rl:take(1), false)
		advance(1)
		eq(rl:take(1), true, "un token tras 1 s")
		eq(rl:take(1), false)
		advance(100)
		eq(rl:take(1), true)
		eq(rl:take(1), true)
		eq(rl:take(1), false, "no acumula más que el burst")
	end)

	it("aguanta el spam: 1000 eventos en 1 s con 5/s y burst 8", function()
		local now, advance = fakeClock()
		local rl = RateLimiter.new({ burst = 8, perSecond = 5 }, now)
		local accepted = 0
		for _ = 1, 1000 do
			if rl:take(7) then
				accepted += 1
			end
			advance(0.001)
		end
		H.truthy(accepted <= 8 + 5, `aceptó {accepted}`)
	end)

	it("separa jugadores", function()
		local now = fakeClock()
		local rl = RateLimiter.new({ burst = 1, perSecond = 1 }, now)
		eq(rl:take(1), true)
		eq(rl:take(1), false)
		eq(rl:take(2), true, "otro jugador tiene su propio bucket")
	end)

	it("un reloj que retrocede no regala tokens", function()
		local now, advance = fakeClock()
		local rl = RateLimiter.new({ burst = 1, perSecond = 1 }, now)
		advance(10)
		eq(rl:take(1), true)
		advance(-5)
		eq(rl:take(1), false)
	end)

	it("remove libera la memoria del jugador", function()
		local now = fakeClock()
		local rl = RateLimiter.new({ burst = 1, perSecond = 1 }, now)
		rl:take(1)
		rl:take(2)
		eq(rl:size(), 2)
		rl:remove(1)
		rl:remove(1)
		eq(rl:size(), 1)
	end)
end)

H.finish("RateLimiter")
