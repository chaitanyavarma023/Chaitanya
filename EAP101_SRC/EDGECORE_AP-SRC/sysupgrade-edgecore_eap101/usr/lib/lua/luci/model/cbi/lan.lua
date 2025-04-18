local fs = require "nixio.fs"
local nw = require "luci.model.network"
local fw = require "luci.model.firewall"
local acn_util = require "luci.acn.util"
local acn_status = require "luci.acn.status"
local json = require "cjson.safe"
local ipvalidation = require "luci.acn.ipvalidation"
local product = require("luci.acn.product")
local supports_l2tp = product.supports_l2tp()
local has_firewall = fs.access("/etc/config/firewall")
local has_upnp     = fs.access("/etc/config/upnpd")
local MAX_CUSTOM_LANS = 10

arg[1] = arg[1] or ""

m = Map("network", "Local Networks")
m:chain("wireless")

if has_firewall then
    m:chain("firewall")
end

if has_upnp then
    m:chain("upnpd")
end

local ipdata = ipvalidation.getipdata()
local json_ipdata = json.encode(ipdata)
local enable_dhcprelay = m.uci:get("dhcp", "dhcprelay", "enabled") or "0"

local include_ipaliases = false --m.uci:get("acn", "mgmt", "enabled") ~= "1"

-- JS file for this page
luci.dispatcher.context.page_js = '<script src="' .. luci.config.main.mediaurlbase .. '/js/lan.js?ver=' .. acn_status.version() .. '"></script>\n'
.. '<script src="' .. luci.config.main.resourcebase .. '/ip_alias.js?ver=' .. acn_status.version() .. '"></script>\n'
.. '<script src="' .. luci.config.main.mediaurlbase .. '/js/lan_validation.js?ver=' .. acn_status.version() .. '"></script>\n'
.. "<script type='text/javascript'>\n"
..    "var ipdata = " .. json_ipdata ..";\n"
..    "var wan_fallback_ip = '" .. ipdata["wan_fallback"]["ip"] .. "';\n"
..    "var wan_fallback_nm = '" .. ipdata["wan_fallback"]["nm"] .. "';\n"
..    "var wan_static_ip = '"   .. ipdata["wan"]["ip"] .. "';\n"
..    "var wan_static_nm = '"   .. ipdata["wan"]["nm"] .. "';\n"
..    "var hotspot_ip = '"      .. ipdata["hotspot"]["ip"] .. "';\n"
..    "var hotspot_netmask = '" .. ipdata["hotspot"]["nm"] .. "';\n"
..    "var enable_dhcprelay = " .. enable_dhcprelay ..";\n"
.. "</script>\n"
.. '<style>\n'
.. '.ip_aliases_warning  { color: red!important; }\n'
.. '</style>'

-- Modals for this page
luci.dispatcher.context.modal_template = luci.dispatcher.context.modal_template or {}

-- Add blank template used to create custom LANs
luci.dispatcher.context.modal_template[#luci.dispatcher.context.modal_template + 1] = "admin_network/lan_custom_template"

local is_postback = luci.http.formvalue("cbid.network.lan.dhcp_max")

nw.init(m.uci)

s = m:section(TypedSection, "interface", translate("LAN"))
s.addremove = true
s.anonymous = false

members = s:option(DummyValue, "members", translate("Members"))
ipaddr = s:option(Value, "ipaddr", translate("IP Address"))
static_mask = s:option(Value, "netmask", translate("Subnet Mask"))
static_mask.datatype = "ipmask4"
mtu = s:option(Value, "mtu", translate("MTU Size"))
mtu.datatype = "range(1400,1500)"
mtu.default = "1500"

-- These will really come from dhcp, not network config in the template
dhcp = s:option(Flag, "dhcp", translate("DHCP Server"))
dhcp.default = "none"
dhcp_start = s:option(Value, "dhcp_start", translate("DHCP Start"))
--dhcp_start:depends("dhcp", "1")

dhcp_max = s:option(Value, "dhcp_max", translate("DHCP Limit"))
--dhcp_max:depends("dhcp", "1")

dhcp_leasetime = s:option(ListValue, "dhcp_leasetime", translate("DHCP Lease Time"))
dhcp_leasetime:value("5m", translate("5min"))
dhcp_leasetime:value("30m", translate("30min"))
dhcp_leasetime:value("1h", translate("1hr"))
dhcp_leasetime:value("3h", translate("3hr"))
dhcp_leasetime:value("6h", translate("6hr"))
dhcp_leasetime:value("8h", translate("8hr"))
dhcp_leasetime:value("12h", translate("12hr"))
dhcp_leasetime:value("24h", translate("1 day"))
dhcp_leasetime:value("72h", translate("3 days"))
dhcp_leasetime:value("168h", translate("1 week"))

dhcp_dns = s:option(Value, "dhcp_dns", translate("Custom DHCP DNS Servers"))

circuit_id_data = s:option( Value, "circuit_id_data", translate("DHCP Relay Id"))
circuit_id_data.datatype = "limited_len_str(1, 32)"

stp = s:option(Flag, "stp", translate("STP"))
stp.rmempty = false

upnp = s:option(Flag, "upnp", translate("UPnP"))
upnp.rmempty = false

smart_isolation = s:option(ListValue, "smart_isolation", translate("Smart Isolation"))
smart_isolation:value("0", translate("Disable (full access)"))
smart_isolation:value("1", translate("Internet access only"))
smart_isolation:value("2", translate("LAN access only"))
smart_isolation:value("3", translate("Internet access strict"))
smart_isolation.default = "0"

auto = s:option(Flag, "auto", translate("Status"))
auto.default = "1"

local FW_WEBUI_NAME = 'DROP-WEBUI-GUEST'
local perm_fw_rules = {}

m.uci:foreach("firewall", "rule",
    function(fw)
        if fw.name then
            perm_fw_rules[fw.name] = fw
        end
    end
)

function circuit_id_data.write(self, section, value)
    if enable_dhcprelay == "1" then
        m.uci:set("network", section, "circuit_id", "manual")
        Value.write(self, section, value)
    end
end

function smart_isolation.write(self, section, value)
    local _zone, zone_name = nil, nil
    self.map.uci:foreach("firewall", "zone",
        function(zone)
            local net = zone.network
            if type(net) == "table" then
                for i, n in ipairs(net) do
                    if n == section then
                        _zone = zone[".name"]
                        zone_name = zone["name"]
                    end
                end
            else
                if net == section then
                    _zone = zone[".name"]
                    zone_name = zone["name"]
                end
            end
        end
    )

    if not _zone then
        _zone = self.map.uci:add("firewall", "zone")
        self.map.uci:set("firewall", _zone, "name", section);
        self.map.uci:set("firewall", _zone, "network", {section});
    elseif not zone_name then
        zone_name = section
        self.map.uci:set("firewall", _zone, "name", zone_name);
    end

    -- full access
    if value == "0" then
        self.map.uci:set("firewall", _zone, "input", "ACCEPT")
        self.map.uci:set("firewall", _zone, "output", "ACCEPT")
        self.map.uci:set("firewall", _zone, "forward", "ACCEPT")

    -- internet only
    elseif value == "1" then
        self.map.uci:set("firewall", _zone, "input", "REJECT")
        self.map.uci:set("firewall", _zone, "output", "ACCEPT")
        self.map.uci:set("firewall", _zone, "forward", "REJECT")

    -- local network (zone) only
    elseif value == "2" then
        self.map.uci:set("firewall", _zone, "input", "ACCEPT")
        self.map.uci:set("firewall", _zone, "output", "ACCEPT")
        self.map.uci:set("firewall", _zone, "forward", "REJECT")
    end

    ListValue.write(self, section, value)
end

function ipaddr.write(self, section, value)
    if section == "lan" then
        local rule = perm_fw_rules[FW_WEBUI_NAME]
        local rule_name = ""

        if type(rule) == "string" then
            rule_name = rule
        elseif type(rule) == "table" then
            rule_name  = rule[".name"]
        end
        self.map.uci:set("firewall", rule_name, "dest_ip", value)
    end
    Value.write(self, section, value)
end

function dhcp_start.write(self, section, value)
    self.map.uci:set("dhcp", section, "start", value)
    self.map.uci:save("dhcp")
end
function dhcp_max.write(self, section, value)
    self.map.uci:set("dhcp", section, "limit", value)
    self.map.uci:save("dhcp")
end

function dhcp_leasetime.write(self, section, value)
    self.map.uci:set("dhcp", section, "leasetime", value)
    self.map.uci:save("dhcp")
end

function dhcp_dns.write(self, section, value)
    if not value:match('(%S)') then
        self.map.uci:delete("dhcp", section, "dhcp_option")
    else
        value=value:gsub('%s+',",")
        self.map.uci:set("dhcp", section, "dhcp_option", {'6,'..value})
    end
    self.map.uci:save("dhcp")
end

function auto.write(self, section, value)
    self.map.uci:set("network", section, "auto", value)
    self.map.uci:save("network")
end

function dhcp.write(self, section, value)
    local dmax = luci.http.formvalue("cbid.network."..section..".dhcp_max")
    local dstart = luci.http.formvalue("cbid.network."..section..".dhcp_start")
    local dlease = luci.http.formvalue("cbid.network."..section..".dhcp_leasetime")
    local dhcp_dns_val = luci.http.formvalue("cbid.network."..section..".dhcp_dns")
    local circuit_id = "manual"
    local circuit_id_data = luci.http.formvalue("cbid.network."..section..".circuit_id_data")

    local ignore = "1"

    if value == "1" then 
      ignore = "0"
    end

    local exists = m.uci:get("dhcp", section, "interface")

    if not exists then
        m.uci:section("dhcp", "dhcp", section, {
        ignore = ignore,
        interface = section,
        start = dstart,
        limit = dmax,
        leasetime = dlease,
        dhcp_option = {
          dhcp_dns_val
        },
        circuit_id = circuit_id,
        circuit_id_data = circuit_id_data
    })
    else
        m.uci:set("dhcp",  section, "ignore", ignore)
    end

    m.uci:save("dhcp")
    -- Don't commit, only save!
end

local intiface = ""
local en_val = "0"
function upnp.write(self, section, value)

    if value == "1" then
        if intiface ~= "" then
            intiface = intiface .. " "
        end

        intiface = intiface .. section
        en_val = "1"
    end

    -- if there is one upnp enabled, let's set enabled be 1
    self.map.uci:set("upnpd", "config", "enabled", en_val)
    self.map.uci:set("upnpd", "config", "internal_iface", intiface)
    self.map.uci:save("upnpd")
end


-- We don't want to write sections for skipped networks

local old_cfgsections = s.cfgsections

-- Override this so networks that are skipped aren't messed with
-- How the hell did I figure this one out the first time??
function s.cfgsections(self)

    local sections = {}
    self.map.uci:foreach(self.map.config, self.sectiontype,
        function (section)
            if not acn_util.hide_from_lan_page(section[".name"], section["vlan_net"]) then
                if self:checkscope(section[".name"]) then
                    table.insert(sections, section[".name"])
                end
            end
        end)
    return sections
end

s.template = "admin_network/lan"
s.include_ipaliases = include_ipaliases

-- Only show ip aliaies if mgmtd is NOT enabled (we're NOT cloud managed)

if include_ipaliases then
    for i, k in ipairs(s:cfgsections()) do
        -- Hidden ones already removed in cfgsections()
        acn_util.add_ip_alias_div(k, m)
    end
end

-- Sometimes we want to delete a LAN for CBI purposes (it's been renamed)
-- for other cases, we want to obliterate the lan and all associated objects,
-- like firewall rules, etc...
function delete_lan(map, name)

    -- Don't allow to delete lans that are from the site level (only disable them)
    -- Remove firewall zone
    -- Remove IP aliases if supported
    -- Move interfaces in this network to default LAN
    -- Remove DHCP section

    local ifnames, wifi_ifnames

    local exists = map.uci:get("network", name)

    if exists then
        -- First get "normal" bridged members
        ifnames = map.uci:get("network", name, "ifname")  or ""

        if ifnames then
            local ifname_table = luci.util.split(ifnames, " ")
            -- Move to lan network
            for _, v in ipairs(ifname_table) do
                if #v > 0 then
                    acn_util.add_iface_to_network("lan", acn_util.inet_src_to_logical(v), map.uci)
                end
            end
        end

        -- Now get wifi-iface members that are in this lan and move them out
        map.uci:foreach("wireless", "wifi-iface",
            function(iface)
                if iface.network == name then
                    acn_util.add_iface_to_network("lan", iface[".name"], map.uci)
                end
            end
        )

    end

    local zone_name
    local aliases ={}

    map.uci:foreach("firewall", "zone",
        function(zone)
            if zone.name and zone.name == name then
                zone_name = zone[".name"]
            end
        end
    )

    if zone_name then
        map.uci:delete("firewall", zone_name)
    end

    map.uci:delete("dhcp", name)

    -- Remove ip aliases
    map.uci:foreach("network", "alias",
        function(alias)
            if alias.interface == name then
                aliases[#aliases +1] = alias[".name"]
            end
        end
    )

    for _, alias in ipairs(aliases) do
        map.uci:delete("network", alias)
    end

    -- Remove LAN itself and DHCP section
    map.uci:delete("network", name)

    map.uci:save("dhcp")
    map.uci:save("wireless")
    map.uci:save("network")
    map.uci:save("firewall")

end

function rename_lan(map, old_name, new_name)

    map.uci:rename("network", old_name, new_name)
    map.uci:rename("dhcp", old_name, new_name)
    map.uci:set("dhcp", new_name, "interface", new_name)

    -- Don't need to do anything with ifname interfaces, they stay with LAN section
    -- Now get wifi-iface members that are in this lan and rename their networks

    map.uci:foreach("wireless", "wifi-iface",
        function(iface)
            if iface.network == old_name then
                map.uci:set("wireless", iface[".name"], "network", new_name)
            end
        end
    )

    -- Rename associated fw sections too
    add_lan(map, new_name)

    map.uci:foreach("network", "alias",
        function(alias)
            if alias.interface == old_name then
                map.uci:set("network", alias[".name"], "interface", new_name)
            end
        end
    )

end

-- Add a lan + associated objects (will skip anything that already exists)
function add_lan(map, name)
    local has_zone = false
    local exists = map.uci:get("network", name)

    if not exists then
        -- Add new network section
        m.uci:set("network", name, "interface")

        -- Set proto to static
        m.uci:set("network", name, "proto", "static")
        m.uci:set("network", name, "type", "bridge")
    end

    map.uci:foreach("firewall", "zone",
        function(zone)
            if zone.name and zone.name == name then
                has_zone = true
            end
        end
    )

    -- Add firewall zone if it doesn't already exist
    if not has_zone then

        local smart_iso = luci.http.formvalue("cbid.network."..name..".smart_isolation")
        local input_value = "ACCEPT"
        local zone_name = map.uci:add("firewall", "zone")

        if smart_iso == "1" then
            input_value = "REJECT"
        end

        map.uci:set("firewall", zone_name, "name", name);
        map.uci:set("firewall", zone_name, "network", {name});
        map.uci:set("firewall", zone_name, "input", input_value);
        map.uci:set("firewall", zone_name, "output", "ACCEPT");
        map.uci:set("firewall", zone_name, "forward", "REJECT");

    end

    map.uci:save("firewall")
end

-- Handle new lans
function m.parse(self, ...)
    local total_custom_lans, last_slot_id = 0, -1
    local custom_lan_names = {}

    if is_postback then
        -- Get list of new sections
        for i = 0, (MAX_CUSTOM_LANS - 1) do
            local custom_lan_name = "custom_" .. i
            local on_form = luci.http.formvalue("cbid.network."..custom_lan_name..".ipaddr")

            if on_form and #on_form > 0 then
                last_slot_id = i
                -- This only adds lan if it doesn't already exist
                add_lan(self, custom_lan_name)
                total_custom_lans = total_custom_lans + 1
                custom_lan_names[#custom_lan_names + 1] = custom_lan_name;

                -- Set lan title
                local current_title = self.uci:get("network", custom_lan_name, "title") or ""
                local title = luci.http.formvalue("cbid.network."..custom_lan_name..".title")

                if current_title ~= title then
                    self.uci:set("network", custom_lan_name, "title", title or custom_lan_name)
                end

            else
                -- Lan was deleted, let's kill it
                -- Delete this LAN's objects
                delete_lan(self, custom_lan_name)
            end

        end
        -- Check for a new section
        -- don't use CBI add/remove - it only adds a SINGLE, EMPTY section.
        -- CBI: I HATE YOU. A LOT.
    end

    -- Continue parsing other stuff like normal
    Map.parse(self, ...)
    -- Once everything is saved, let's renumber custom Lans if we need to
    if is_postback then
        local renamed_lans, renamed_lans_inv = {}, {}
        -- Renumber lans if necessary
        if (total_custom_lans - 1) ~= last_slot_id then
            for i=0, #custom_lan_names -1 do

                if custom_lan_names[i+1] ~= ("custom_" .. i) then
                    rename_lan(self, custom_lan_names[i+1], "custom_" .. i)
                end
            end
        end

        for i = total_custom_lans, MAX_CUSTOM_LANS  do
            local name = "custom_" .. i
            delete_lan(self, name)

        end

        self.uci:save("network")
        -- reload page
        --luci.http.redirect(luci.dispatcher.build_url("admin/network/acn_lan"))
    end
end

return m
