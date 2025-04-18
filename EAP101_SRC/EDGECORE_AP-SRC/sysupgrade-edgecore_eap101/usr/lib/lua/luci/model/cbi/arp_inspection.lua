local acn_status = require "luci.acn.status"
local fw_ver = acn_status.version()
local uci = require "luci.model.uci".cursor()
local m, s
local max_count = 20

m = Map("firewall", translate("ARP Inspection"))

s = m:section(TypedSection, "dai", "")
s.anonymous = true

local arpinspection_enable = s:option(Flag, "arpinspection_enable", translate("ARP Inspection"))
arpinspection_enable.rmempty = false

local forcedhcp_enable = s:option(Flag, "forcedhcp_enable", translate("Force DHCP"))
forcedhcp_enable.rmempty = false

local trustlistbroadcast_enable = s:option(Flag, "trustlistbroadcast_enable", translate("Trust List Broadcast"))
trustlistbroadcast_enable.rmempty = false

local statictrust_enable = s:option(Flag, "statictrust_enable", translate("Static Trust List"))
statictrust_enable.rmempty = false

local statictrust = m:section(TypedSection, "statictrust", "")
statictrust.addremove = true
statictrust.anonymous = true

-- Use javascript/dynamic add remove template
statictrust.template          = "cbi/tblsection_js"
statictrust.add_btn_small     = true
statictrust.add_btn_location  = "top"
statictrust.max_count  = max_count

statictrust.table_name = "table_arp_statictrust"
statictrust.no_stripe  = true
statictrust.table_hide = "style='display:none'"

statictrust.add_onclick = "addStatictrustRow();"
statictrust.del_onclick = "removeStatictrustRow(this.id);"

-- option: MAC, IP, State:Flag
local statictrust_mac = statictrust:option(Value, "mac", translate("MAC"))
local statictrust_ip = statictrust:option(Value, "ip", translate("IP"))
local statictrust_state = statictrust:option(Flag, "state", translate("State"))

-- JS file for this page
luci.dispatcher.context.page_js = '<script src="/javascript/arp_inspection.js?ver=' .. fw_ver .. '"></script>\n'
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

statictrust.parse = function(self, nvld)
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
                local deleted = self.map:formvalue('acn.del.statictrust.cfg' .. v)
                if deleted == "0" then
                    local mac = self.map:formvalue('cbid.statictrust.cfg' .. v .. '.mac')
                    local ip = self.map:formvalue('cbid.statictrust.cfg' .. v .. '.ip')
                    local state = self.map:formvalue('cbid.statictrust.cfg' .. v .. '.state')
    
                    -- Create our anon section
                    local section = self:create()
                    if section then
                        self.map.uci:set("firewall", section, "mac", mac)
                        self.map.uci:set("firewall", section, "ip", ip)
                        self.map.uci:set("firewall", section, "state", state)
                        -- If we don't do the save/load below, something messes up the internal counter
                        -- and uci sections start overwriting each other (see #497)
                        self.map.uci:save("firewall")
                        self.map.uci:load("firewall")
                    end
                end
            end
        end
    
        table = self.map:formvaluetable(del_prefix .. ".statictrust")
        -- Need to use map.uci here so that the settings are saved correctly
        for k, v in pairs(table) do
            if v and (v == "1" or v == 1) then 
                self.map.uci:delete("firewall", k)
            end 
        end
    end
end

return m
