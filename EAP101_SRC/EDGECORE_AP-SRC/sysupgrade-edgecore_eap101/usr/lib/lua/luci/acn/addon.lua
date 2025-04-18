-- read /etc/config/addon file
local uci_cursor = require "luci.model.uci".cursor()

local function get_wianchor()
  _val = (uci_cursor:get("addon", "wianchor", "enabled") == "1")
	return _val
end

local module = {
	is_wianchor = get_wianchor
}
return module
