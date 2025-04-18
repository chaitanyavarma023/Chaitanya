local acn_status = require "luci.acn.status"
local fw_ver = acn_status.version()
local uci = require "luci.model.uci".cursor()
local max_count = 10

local m, s
m = Map("firewall", translate("DHCP Snooping"))

local s_enable = m:section(TypedSection, "dai", "")
s_enable.anonymous = true

dhcpsnooping_enable = s_enable:option(Flag, "dhcpsnooping_enable", translate("Enable DHCP Snooping"))
dhcpsnooping_enable.rmempty = false

s = m:section(TypedSection, "trustdhcpserver", "")
s.addremove = true
s.anonymous = true

-- Use javascript/dynamic add remove template
s.template          = "cbi/tblsection_js"
s.add_btn_small     = true
s.add_btn_location  = "top"
s.max_count  = max_count

s.table_name = "table_dhcp_snooping"
s.no_stripe  = true
s.table_hide = "style='display:none'"

s.add_onclick = "addDHCPServerRow();"
s.del_onclick = "removeDHCPServerRow(this.id);"


local dhcp_server_mac = s:option(Value, "mac", translate("Trust DHCP Server MAC"))
--dhcp_server_mac.datatype = "macaddr"
--dhcp_server_mac:depends(enable, '1')

local dhcp_server_ip = s:option(Value, "ip", translate("Trust DHCP Server IP"))
--dhcp_server_ip.datatype = "ip4addr"

local remark = s:option(Value, "remark", translate("Remark"))

-- JS file for this page
luci.dispatcher.context.page_js = '<script src="/javascript/dhcp_snooping.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script src="/javascript/common.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script type="text/javascript"> \n'
.. '    var max_count = ' .. max_count .. ';\n'
.. '</script>\n'
.. '<style>\n'
.. '#btn_save  { margin-left: 10px; }\n'
.. 'input { width:100px; }\n'
.. '</style>'

--TODO: to avoid running s.parse twince. but it should have better solution.
local runned_s_parse = false

s.parse = function(self, nvld)
    if not runned_s_parse then
        runned_s_parse = true
        -- Have to do this first
        TypedSection.parse(self, nvld)

        local add_prefix = "acn.new" 
        local del_prefix = "acn.del" 

        -- This gets a list of all form values that begin with the prefix

        local new_rules = self.map:formvaluetable(add_prefix) or ""
        -- want these sorted
        local keys = {}
        for k in pairs(new_rules) do keys[#keys+1] = k end
        table.sort(keys, function(a,b) return new_rules[a] < new_rules[b]  end)

        -- Need to use map.uci here so that the settings are saved
        for i,k in ipairs(keys) do

            local v = new_rules[k]
            -- value is our client-side generated section name (like 45f30e)

            if v then
                -- v = cfg used for the temporary row
                local deleted = self.map:formvalue('acn.del.trustdhcpserver.cfg' .. v)
                if deleted == "0" then
                    local mac = self.map:formvalue('cbid.trustdhcpserver.cfg' .. v .. '.mac')
                    local ip = self.map:formvalue('cbid.trustdhcpserver.cfg' .. v .. '.ip')
                    local remark = self.map:formvalue('cbid.trustdhcpserver.cfg' .. v .. '.remark')

                    -- Create our anon section
                    local section = self:create()
                    if section then
                        self.map.uci:set("firewall", section, "mac", mac)
                        self.map.uci:set("firewall", section, "ip", ip)
                        self.map.uci:set("firewall", section, "remark", remark)
                        -- If we don't do the save/load below, something messes up the internal counter
                        -- and uci sections start overwriting each other (see #497)
                        self.map.uci:save("firewall")
                        self.map.uci:load("firewall")
                    end
                end
            end
        end

        table = self.map:formvaluetable(del_prefix .. ".trustdhcpserver")
        -- Need to use map.uci here so that the settings are saved correctly
        for k, v in pairs(table) do
            if v and (v == "1" or v == 1) then 
                self.map.uci:delete("firewall", k)
            end 
        end
    end
end

return m
