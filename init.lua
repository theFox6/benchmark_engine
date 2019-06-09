benchmark = {}
local registered_benchmarks = {}
local log = modutil.require("log").make_loggers("action","debug")

function benchmark.count_data(data,counterTable)
	local k = dump(data)
	if (counterTable[k] == nil) then
		counterTable[k] = 1
	else
		counterTable[k] = counterTable[k] + 1
	end
end

local check_prefix = modutil.require("check_prefix")
function benchmark.register(name,definition)
	local id = check_prefix(name)
	local def = definition
	if not def.run then
		error("benchmark definition does not contain runnable")
	end
	if not def.warmup then def.warmup = 200 end
	if not def.loops then def.loops = 100 end
	if not def.before then
		def.before = function() end
	end
	registered_benchmarks[id] = def
end

function benchmark.run(id)
	log.action("starting benchmark ".. id)
	minetest.chat_send_all("starting benchmark ".. id)
	local bench = registered_benchmarks[id]
	local times = {}
	-- do warmup cycles for jitter
	for it=0, bench.warmup do
		local ret = bench.before()
		bench.run(ret)
	end
	-- measure benchmark
	for it=0, bench.loops do
		local ret = bench.before()
		local t = os.clock()
		bench.run(ret)
		table.insert(times, os.clock() - t)
	end
	-- display data
	local total_time = 0
	local min, max
	for _,v in pairs(times) do
		total_time = total_time + v
		if not max or v > max then
			max = v
		end
		if not min or v < min then
			min = v
		end
	end
	local average_time = total_time / #times
	local msg = string.format("benchmark results for %s\n"..
		"run %i/%i times after %i times warmup\n"..
		"min:        %f s\n"..
		"average:    %f s\n"..
		"max:        %f s\n"..
		"total time: %f s",
		id, #times-1, bench.loops, bench.warmup, min, average_time, max, total_time)
	minetest.chat_send_all(msg)
	log.debug(msg)
end

minetest.register_privilege("benchmark", {
	description = "run benchmarks",
	give_to_singleplayer = true
})

minetest.register_chatcommand("benchmark", {
	params = "<benchmark_id>",
	description = "run a benchmark and show results when finished\
		show all registered benchmark when no parameters are given",
	privs = {benchmark = true},
	func = function(name, param)
		if param == nil or param == "" or param == "?" then
			local ids = ""
			for i in pairs(registered_benchmarks) do
				ids = ids .. ", " .. i
			end
			minetest.chat_send_player(name, "avalible benchmarks: "..ids:sub(3))
		else
			if not registered_benchmarks[param] then
				minetest.chat_send_player(name, "This benchmark id is not registered.\n"..
					"To list all benchmarks run the command without parameters.")
			else
				benchmark.run(param)
			end
		end
	end
})
