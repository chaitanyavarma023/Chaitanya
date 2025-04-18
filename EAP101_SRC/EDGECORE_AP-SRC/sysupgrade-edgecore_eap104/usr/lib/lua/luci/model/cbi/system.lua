
require("luci.sys")
require("luci.util")

local brand = require("luci.acn.brand")
local acn_status = require "luci.acn.status"
local product = require("luci.acn.product")
local uci = require "luci.model.uci".cursor()
--local acn_util = require("luci.acn.util")
--local acn_uci = acn_util.cursor()
local is_OAP103 = product.is_OAP103()

local m, s, s_mgmt, s_mgmt2, mgmt_mode, s_reg, s_capwap
local max_count = 5

-- JS file for this page
local fw_ver = acn_status.version()
luci.dispatcher.context.page_js = '<script src="' .. luci.config.main.resourcebase .. '/common.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script src="' .. luci.config.main.mediaurlbase .. '/js/mgmt.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script type="text/javascript"> \n'
.. '    var max_count = ' .. max_count .. ';\n'
.. '</script>'

m = Map("acn", "")

local has_mgmtd = nixio.fs.access("/usr/sbin/mgmtd")

if has_mgmtd then
    local mgmt, url, link, s_capwap_ac
    local capwap_st, check_cert, dns_srv, srv_suffix, dhcp_opt, broadcast, multicast, unicast

    s_mgmt = m:section(NamedSection, "mgmt", "acn", translate("Management Settings"))

    mgmt_mode = s_mgmt:option(ListValue, "management", translate("Management"))

    mgmt_mode.override_values   = true
    mgmt_mode:value("0", translate("Disable"))
    if not is_OAP103 then
        mgmt_mode:value("1", translate("ecCLOUD"))
    end
    mgmt_mode:value("2", translate("EWS-Series Controller"))

    link = s_mgmt:option(DummyValue, "_nothing", translate("Controller URL"))
    link:depends("management", "1", "mgmt")
    link.template  = "cbi/mgmt_link"

    mgmt = s_mgmt:option(Flag, "enabled", translate("Enable agent"))
    mgmt:depends("management", "1", "mgmt")
    mgmt.rmempty = true
    mgmt.help_tip = translate("Allow this device to be managed by the ") .. translate(product.company_name())
                    .. translate(" Cloud Controller.")
                    .. translate("<br/><br/>")
                    .. translate("You must create an account on the controller before you can use this option.")

    s_reg = m:section(NamedSection, "register", "acn", "")

    url = s_reg:option(Value, "url", translate("Registration URL"))
    -- url:depends("enabled", "1", "mgmt")
    url.header_style = "display:none"
    url.default =  brand.register_url
    url.custom_attr = " style='width:250px' readonly='readonly' "
    url.cond_optional = true
    url.rmempty = true
    --url.datatype = "limited_len_str(1, 200)"
    --url.help_tip =  "<span style='font-weight:bold'>Warning!</span> Do not change this value unless you are an advanced user!"

    url.write = function(self, section, value)
        local oldValue = m.uci:get("acn", "register", "url") or ""
        if value ~= oldValue then
            m.uci:set("acn", "register", "state", "0")
            m.uci:save("acn")
        end
        Value.write(self, section, value)
    end
    url.remove = function ( ) end

    s_mgmt2 = m:section(NamedSection, "mgmt", "acn")

    mgmt_loglevel = s_mgmt2:option(ListValue, "loglevel", translate("Log Level"))
    mgmt_loglevel:depends("management", "1", "mgmt")
    mgmt_loglevel:value("error", translate("Error"))
    mgmt_loglevel:value("warn", translate("Warn"))
    mgmt_loglevel:value("info", translate("Info"))
    mgmt_loglevel:value("debug", translate("Debug"))
    mgmt_loglevel:value("trace", translate("Trace"))
    mgmt_loglevel.rmempty = true

    mgmt_loglevel.help_tip = translate("Add the option to adjust the system log level for ecCLOUD deamon (mgmtd). Info is the default value.")
    .. ("<br/><br/>")
    .. translate("The standard ranking of log level is as follows: Trace < Debug < Info < Warn < Error.")

    syslog_level = s_mgmt2:option(ListValue, "syslog_level", translate("Syslog Level"))
    syslog_level.rmempty = false
    syslog_level.default = "7"
    syslog_level:value("1", translate("Emergency"))
    syslog_level:value("2", translate("Alert"))
    syslog_level:value("3", translate("Critical"))
    syslog_level:value("4", translate("Error"))
    syslog_level:value("5", translate("Warning"))
    syslog_level:value("6", translate("Notice"))
    syslog_level:value("7", translate("Info"))
    syslog_level:value("8", translate("Debug"))

    syslog_level.help_tip = translate("Add the option to adjust the system log level. Info is the default value.")
    .. ("<br/><br/>")
    .. translate("The standard ranking of log level is as follows: Debug < Info < Notice < Warning < Error < Critical < Alert < Emergency.")
--==============================================================================
-- Capwap
--==============================================================================
    s_capwap = m:section(NamedSection, "capwap", "capwap", "")
    s_capwap.anonymous = true
    s_capwap.addremove = false

    capwap_st = s_capwap:option(Flag, "state", translate("CAPWAP"))
    capwap_st.header_style = "display:none"
    capwap_st.rmempty = false

    --[[capwap_st.cfgvalue = function (self, section)
        return m.uci:get("acn", section, "capwap_st") or "0"
    end]]
    -- capwap_st.write = function (self, section, value)
    --     return self.map:set(section, "state", value)
    -- end
    --capwap_st.remove = function ( ) end

    -- check_cert = s_capwap:option(Flag, "check_cert", translate("Certificate Date Check"))
    -- --srv_suffix:depends("state", "1", "capwap")
    -- check_cert.header_style = "display:none"
    -- check_cert.rmempty = false
    -- --[[check_cert.cfgvalue = function (self, section)
    --     return m.uci:get("acn", section, "check_cert") or "0"
    -- end]]
    -- check_cert.write = function (self, section, value)
    --     return self.map:set(section, "check_cert", value)
    -- end
    --check_cert.remove = function ( ) end

    dns_srv = s_capwap:option(Flag, "dns_srv", translate("DNS SRV Discovery"))
    --dns_srv:depends("management", "2", "mgmt")
    dns_srv.header_style = "display:none"
    dns_srv.rmempty = false
    --[[dns_srv.cfgvalue = function (self, section)
        return m.uci:get("acn", section, "dns_srv") or "0"
    end]]
    dns_srv.write = function (self, section, value)
        return self.map:set(section, "dns_srv", value)
    end
    --dns_srv.remove = function ( ) end

    srv_suffix = s_capwap:option(Value, "srv_suffix", translate("Domain Name Suffix"))
    --srv_suffix:depends("dns_srv", "1", "capwap")
    srv_suffix.header_style = "display:none"
    --[[srv_suffix.cfgvalue = function (self, section)
        return m.uci:get("acn", section, "srv_suffix") or " "
    end]]
    srv_suffix.write = function (self, section, value)
        return self.map:set(section, "srv_suffix", value)
    end
    --srv_suffix.remove = function ( ) end

    dhcp_opt = s_capwap:option(Flag, "dhcp_opt", translate("DHCP Option Discovery"))
    --dhcp_opt:depends("state", "1", "capwap")
    dhcp_opt.header_style = "display:none"
    dhcp_opt.rmempty = false
    --[[dhcp_opt.cfgvalue = function (self, section)
        return m.uci:get("acn", section, "dhcp_opt") or "0"
    end]]
    dhcp_opt.write = function (self, section, value)
        return self.map:set(section, "dhcp_opt", value)
    end
    --dhcp_opt.remove = function ( ) end

    broadcast = s_capwap:option(Flag, "broadcast", translate("Broadcast Discovery"))
    --broadcast:depends("state", "1", "capwap")
    broadcast.header_style = "display:none"
    broadcast.rmempty = false
    broadcast.cfgvalue = function (self, section)
        local broadcast_val = m.uci:get("acn", section, "broadcast") or "0"

        if broadcast_val ~= "0" then
            return "1"
        else
            return "0"
        end
    end
    broadcast.write = function (self, section, value)
        if value == "1" then
            value = "255.255.255.255"
        end

        return self.map:set(section, "broadcast", value)
    end
    --broadcast.remove = function ( ) end

    multicast = s_capwap:option(Flag, "multicast", translate("Multicast Discovery"))
    --multicast:depends("state", "1", "capwap")
    multicast.header_style = "display:none"
    multicast.rmempty = false
    multicast.cfgvalue = function (self, section)
        local multicast_val = m.uci:get("acn", section, "multicast") or "0"

        if multicast_val ~= "0" then
            return "1"
        else
            return "0"
        end
    end
    multicast.write = function (self, section, value)
        if value == "1" then
            value = "224.0.1.140"
        end

        return self.map:set(section, "multicast", value)
    end

    unicast = s_capwap:option(Flag, "unicast", translate("Static Discovery"))
    --unicast:depends("state", "1", "capwap")
    unicast.header_style = "display:none"
    unicast.rmempty = false
    --[[unicast.cfgvalue = function (self, section)
        return m.uci:get("acn", section, "unicast") or "0"
    end]]
    unicast.write = function (self, section, value)
        return self.map:set(section, "unicast", value)
    end
    --unicast.remove = function ( ) end

    s_capwap_ac = m:section(TypedSection, "capwap_ac", "")

    s_capwap_ac.addremove     = true
    s_capwap_ac.anonymous     = true

    -- Use javascript/dynamic add remove template
    s_capwap_ac.template          = "cbi/tblsection_js"
    s_capwap_ac.add_btn_small     = true
    s_capwap_ac.add_btn_location  = "top"
    s_capwap_ac.max_count  = max_count

    s_capwap_ac.table_name = "table_capwap_ac"
    s_capwap_ac.no_stripe  = true
    s_capwap_ac.table_hide = "style='display:none'"

    s_capwap_ac.add_onclick = "addCAPWAPRow();"
    s_capwap_ac.del_onclick = "removeCAPWAPRow(this.id);"

    addr = s_capwap_ac:option(Value, "ip", translate("AC Address"))
    addr.force_required = true

    remark = s_capwap_ac:option(Value, "remark", translate("Remark"))
    remark.force_required = true

    --TODO: to avoid running s.parse twince. but it should have better solution.
    local runned_s_parse = false

    s_capwap_ac.parse = function(self, nvld)

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

            table.sort(keys, function(a,b) return new_rules[a] < new_rules[b] end)

            -- Need to use map.uci here so that the settings are saved
            for i,k in ipairs(keys) do

                local v = new_rules[k]
                -- value is our client-side generated section name (like 45f30e)

                if v then
                    -- v = cfg used for the temporary row
                    local deleted = self.map:formvalue('acn.del.acn.cfg' .. v)
                    if deleted == "0" then
                        local ip = self.map:formvalue('cbid.acn.cfg' .. v .. '.ip')
                        local remark = self.map:formvalue('cbid.acn.cfg' .. v .. '.remark')

                        -- Create our anon section
                        local section = self:create()
                        if section then
                            self.map.uci:set("acn", section, "ip", ip)
                            self.map.uci:set("acn", section, "remark", remark)
                            -- If we don't do the save/load below, something messes up the internal counter
                            -- and uci sections start overwriting each other (see #497)
                            self.map.uci:save("acn")
                            self.map.uci:load("acn")
                        end
                    end
                end
            end

            table = self.map:formvaluetable(del_prefix .. ".acn")
            -- Need to use map.uci here so that the settings are saved correctly
            for k, v in pairs(table) do
                if v and (v == "1" or v == 1) then
                    self.map.uci:delete("acn", k)
                end
            end
        end
    end
end

local is_host_postback = luci.http.formvalue("cbid.acn.settings.name")

s = m:section(NamedSection, "settings", "acn", translate("System Settings"))

s.addremove = false
s.anonymous = true

hostname = s:option(Value, "name",translate("Hostname"))

-- Limit size of device name
hostname.datatype = "hostname_str(1, 63)"

-- if we're  NOT cloud managed, show hostname read-only, or show editable hostname.
hostname:depends("enabled", "", "mgmt")
hostname:depends("enabled", "0", "mgmt")

hostname_dummy = s:option(DummyValue, "hostname_dummy", translate("Hostname"))
hostname_dummy.template = "cbi/hostname_dummy"
hostname_dummy:depends("enabled", "1", "mgmt")
local hostname_value = m.uci:get("acn", "settings", "name")
hostname_dummy.hostname_value = is_host_postback or hostname_value

-- Don't delete device name, just hide it.
-- Oh how I wish I had this good of a grasp of shitty CBI a year ago...
function hostname.remove(self, section, value)
    local dummy = "none"
end

function hostname.cfgvalue(self, section, value)
    local cur_hostanme = ""
    m.uci:foreach("system", "system",
        function(s)
            cur_hostanme = m.uci:get("system", s['.name'], "hostname")
            return
        end)
    return cur_hostanme or ""
end

function hostname.write(self, section, value)
    -- hostname
    m.uci:foreach("system", "system",
        function(s)
            m.uci:set("system", s['.name'], "hostname", value)
            m.uci:save("system")
            return
        end)

    local manual_dhcp_hostname =  m.uci:get("network", "wan", "manual_hostname")

    if manual_dhcp_hostname == "0" then
        if value == "" then
            value = product.company_name()
        end

        m.uci:set("network", "wan", "hostname", value)
        m.uci:save("network")
    end

    m.uci:save("system")
    Value.write(self, section, value)
end

function mgmt_mode.cfgvalue(self, section, value)
    local mode = m.uci:get("acn", "mgmt", "management") or "0"
    return mode
end

reset_enable = s:option(Flag, "reset_btn_enable", translate("Enable reset button"))-- ,translate("Reset button enabled."))
reset_enable.rmempty = false

clock = s:option( DummyValue, "_systime", translate("Local Time"))
clock.template = "cbi/clock_time"
clock.show_time_cfg_link = true

bootmaxcnt = s:option(Value, "bootmaxcnt", translate("Number of boot retries"))
bootmaxcnt.default = "3"
-- bootmaxcnt.help_tip = "Number of boot retries before switching to next boot bank"
bootmaxcnt.datatype = "range(1, 254)"

local user_name = luci.http.getcookie("user_name")
local root_user = luci.util.root_user(user_name)

msp_mode = s:option(Flag, "msp_enable", translate("MSP mode"))
msp_mode.rmempty = false
msp_mode.default = false

if root_user then
    msp_mode.is_disabled = false
else
    msp_mode.is_disabled = true
end

m_led = Map("system", "", "")
s_led = m_led:section(TypedSection, "system", "")
s_led.anonymous = true
s_led.addremove = false

led_enable = s_led:option(Flag, "led_enable", translate("Led Enable"))
led_enable.rmempty = false

m_luci = Map("luci", "", "")
s_luci = m_luci:section(TypedSection, "core", "")
s_luci.anonymous = true
s_luci.addremove = false

lang_select = s_luci:option(ListValue, "lang", translate("Language"))
lang_select.rmempty = false
lang_select:value("en", translate("English"))
lang_select:value("ja", translate("Japanese"))

return m, m_led, m_luci
-- return m
