
local util = require("luci.acn.util")

local SYSTEM_JSON = "/var/run/stats/system.json"
local NETWORK_JSON = "/var/run/stats/statistics.json"
local WIRELESS_JSON = "/var/run/stats/wireless.json"
local XINGTERA_JSON = "/var/run/stats/xingtera.json"
local STATE_JSON = "/var/run/config/state.json"

local function get_system()
	local data = util.read_json(SYSTEM_JSON)
	if not data then
		os.execute("stats -s")
		data = util.read_json(SYSTEM_JSON)
	end
	return data
end

local function get_network()
	local data = util.read_json(NETWORK_JSON)
	if not data then
		os.execute("stats -s")
		data = util.read_json(NETWORK_JSON)
	end
	return data
end

local function get_wireless()
	local data = util.read_json(WIRELESS_JSON)
	if not data then
		os.execute("stats -w")
		data = util.read_json(WIRELESS_JSON)
	end
	return data
end

local function get_xingtera()
	return util.read_json(XINGTERA_JSON)
end

local function get_state()
	return util.read_json(STATE_JSON)
end

local module = {
	get_system = get_system,
	get_network = get_network,
	get_wireless = get_wireless,
	get_xingtera = get_xingtera,
	get_state = get_state,
}
return module
