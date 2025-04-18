#!/usr/bin/lua

-- XXX(edzius): maybe refactor UCI to JSON converter to be generic?

local _uci = require("uci")
local json = require("cjson.safe")

local uci = _uci.cursor()

local ntm = require "luci.model.network".init()

--for debug
--local sys = require "luci.sys"

local path_json = "/var/etc/dhcphelper.json"

local correction_cmd = "cat " .. path_json .. " | jq . | sed -e s/remote_id/remote-id/ -e s/circuit_id/circuit-id/ -e s/id_type/type/ > " .. path_json .. ".tmp"

local config_json = {}

local function config_json_write()
	local handle = io.open(path_json, "w")
	if not handle then
		error("could not write json config file at " .. path_json)
	end

--	json.encode_pretty_format(true)

	handle:write(json.encode(config_json))
	handle:close()
end

local function config_remote_id_to_json()
	config_json.option82 = {}

	local opt82 = config_json.option82

	opt82.remote_id = {}

	opt82.remote_id.id_type = uci.get("dhcp", "dhcprelay", "remote_id")

	if (opt82.remote_id.id_type == "manual") then
		opt82.remote_id.data = uci.get("dhcp", "dhcprelay", "remote_id_data")
	end
end

local function config_dhcp_server_to_json()
	config_json.server = {}

	for i = 1,2,1
	do
		local srv = {}

		if (i == 1) then
			srv.address = uci.get("dhcp", "dhcprelay", "server_1")
			srv.port = uci.get("dhcp", "dhcprelay", "server_port_1")
		else
			srv.address = uci.get("dhcp", "dhcprelay", "server_2")
			srv.port = uci.get("dhcp", "dhcprelay", "server_port_2")
		end

		if srv.address then
			config_json.server[i] = srv
		end
	end
end

local function config_group_to_json()
	local dhcp_cnt = 0
	local giaddr = nil
	local group = nil
	local index_lan = 1
	local index_vlan = 1
	local mgmt_device = nil
	local mgmt_enabled = uci.get("network", "managementvlan", "enabled")
	local mgmt_fallback_ip = nil
	local mgmt_ip = nil
	local mgmt_ip_get_cmd = nil
	local mgmt_proto = nil
	local vlan_exist = 0

	config_json.group = {}

	if (mgmt_enabled == "1") then
		mgmt_device = uci.get("network", "managementvlan", "device")

		if (mgmt_device == nil) then
			mgmt_device = uci.get("network", "managementvlan", "ifname")
		end

		mgmt_fallback_ip = uci.get("network", "managementvlan", "fallback_ip")
		mgmt_proto = uci.get("network", "managementvlan", "proto")
	else
		mgmt_device = uci.get("network", "wan", "device")

		if (mgmt_device == nil) then
			if (uci.get("network", "wan", "type") ~= "bridge") then
				mgmt_device = uci.get("network", "wan", "inet_src")
			else
				mgmt_device = "br-wan"
			end
		end

		mgmt_fallback_ip = uci.get("network", "wan", "fallback_ip")
		mgmt_proto = uci.get("network", "wan", "proto")
	end

	mgmt_ip_get_cmd = "ifconfig " .. mgmt_device .. " | grep \"inet addr\" | awk '{print $2}' | awk -F: '{print $2}'"

	while (dhcp_cnt < 10) do
		os.execute("sleep 1")

		mgmt_ip = io.popen(mgmt_ip_get_cmd)

		for l in mgmt_ip:lines() do
			if (mgmt_proto == "dhcp") then
				if (l ~= mgmt_fallback_ip) then
					giaddr = l
				end
			else
				giaddr = l
			end
		end

		mgmt_ip:close()

		if (giaddr == nil) then
			dhcp_cnt = dhcp_cnt + 1
		else
			break
		end
	end

	uci.foreach("network", "interface", function(s)
		if (s[".name"] == "bat0" or s[".name"] == "bat0_hardif_mesh0") then
			return
		elseif (s[".name"] == "hotspot" or s[".name"] == "hotspot_tunnel") then
			return
		elseif (s[".name"] == "loopback") then
			return
		elseif (s[".name"] == "managementvlan" or s[".name"] == "managementvlan6") then
			return
		elseif (s[".name"] == "wan" or s[".name"] == "wan6") then
			return
		elseif (s[".name"] == "wanvlan" or s[".name"] == "wanvlan6") then
			return
--[[
		elseif (string.sub(s[".name"],1,4) == "vlan" and vlan_exist == 0) then
			vlan_exist = vlan_exist + 1

			return
--]]
		else
			local iface = {}

			group = {}

			if (s.device == nil) then
				group.ifname = "br-" .. s[".name"]
			else
				group.ifname = s.device
			end

			local giface = ntm:get_interface(group.ifname)

			if giface and giface:is_up() then
				group.giaddr = giaddr
				group.iface = {}

				if (s.device == nil) then
					iface.ifname = "br-" .. s[".name"]
				else
					iface.ifname = s.device
				end

				if (s.circuit_id == "manual") then
					iface.option82 = {}
					iface.option82.circuit_id = s.circuit_id_data
				end

				group.iface[1] = iface

				config_json.group[index_lan] = group

				index_lan = index_lan + 1

				return

			end
		end
	end)

	if (vlan_exist > 0) then
		group = {}

		group.ifname = "br-dhcprelay"
		group.giaddr = giaddr
		group.iface = {}

		uci.foreach("network", "interface", function(s)
			if (string.sub(s[".name"],1,4) == "vlan") then
				local iface = {}

				if (s.device == nil) then
					iface.ifname = "br-" .. s[".name"]
				else
					iface.ifname = s.device
				end

				if (s.circuit_id == "manual") then
					iface.option82 = {}
					iface.option82.circuit_id = s.circuit_id_data
				end

	                        group.iface[index_vlan] = iface

				index_vlan = index_vlan + 1
			end
		end)

		config_json.group[index_lan] = group
	end
end

config_remote_id_to_json()
config_dhcp_server_to_json()
config_group_to_json()
config_json_write()

os.execute(correction_cmd)
os.execute("mv " .. path_json .. ".tmp " .. path_json)
