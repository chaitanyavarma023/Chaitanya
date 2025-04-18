
require("luci.sys")
require("luci.util")

local acn_status = require "luci.acn.status"
local product = require "luci.acn.product"
local brand = require "luci.acn.brand"
local acn = require("luci.acn.util")
local acn_uci = acn.cursor()
local addon = require("luci.acn.addon")
local is_wianchor = addon.is_wianchor()

local json = require "cjson.safe"
local ipvalidation = require "luci.acn.ipvalidation"

title=translate("Hotspot Settings")

m = Map("hotspot", title)

local is_bb_controlled = m.uci:get("hotspot","hotspot","hs_partner")=="blackbx"

local has_custom_logo = m.uci:get("hotspot", "hotspot" , "hs_portal_logo")  or "0"
if has_custom_logo == "1" then
    has_custom_logo = "true"
else
    has_custom_logo = "false"
end

local ipdata = ipvalidation.getipdata()
local json_ipdata = json.encode(ipdata)
local wan_fallback_ip = m.uci:get("network", "wan", "fallback_ip") or ""
local wan_fallback_nm = m.uci:get("network", "wan", "fallback_nm") or ""
local wan_proto = m.uci:get("network", "wan", "proto") or ""
local wan_static_ip = ""
local wan_static_nm = ""
if wan_proto == "static" then
    wan_static_ip = m.uci:get("network", "wan", "ipaddr") or ""
    wan_static_nm = m.uci:get("network", "wan", "netmask") or ""
end

local local_lan_ip = m.uci:get('network', 'lan', 'ipaddr') or ''
local local_lan_netmask = m.uci:get('network', 'lan', 'netmask') or ''
local guest_lan_ip = m.uci:get('network', 'guest', 'ipaddr') or ''
local guest_lan_netmask = m.uci:get('network', 'guest', 'netmask') or ''

local MAX_CUSTOM_LANS = 10
local custom_lan_data = ""

--collect DAE port from SSID settings
local dae_ports = {}

acn_uci:foreach('wireless', 'wifi-iface',
    function(s)
        -- wifi-iface names are like radioX_X
        local logical_vap_id = s['.name']:match("radio(%d+)_(%d+)")

        if logical_vap_id then
            if s['dae_port'] then
                dae_ports[s['.name']] = s['dae_port'] or ""
            end
        end
    end)

for i = 0, (MAX_CUSTOM_LANS - 1) do
    local custom_lan_name = "custom_" .. i
    local custom_lan = m.uci:get('network', custom_lan_name, 'proto')
    if custom_lan then
        local _ip = m.uci:get('network', custom_lan_name, 'ipaddr')
        local _netmask = m.uci:get('network', custom_lan_name, 'netmask')
        if custom_lan_data ~= "" then
            custom_lan_data = custom_lan_data .. ","
        end
        custom_lan_data = custom_lan_data .. "'" .. _ip .. "','" .. _netmask .. "'"
    end
end
custom_lan_data = "[" .. custom_lan_data .. "]";

local mgmt_enabled = (m.uci:get("acn", "mgmt", "enabled") == "1")

-- JS file for this page
luci.dispatcher.context.page_js = '<script src="' .. luci.config.main.mediaurlbase .. '/js/hotspot.js?ver=' .. acn_status.version() .. '"></script>\n'
.. '<script src="' .. luci.config.main.resourcebase .. '/common.js?ver=' .. acn_status.version() .. '"></script>\n'
.. '<script src="' .. luci.config.main.resourcebase .. '/jquery.minicolors.min.js?ver=' .. acn_status.version() .. '"></script>\n'
.. '<link rel="stylesheet" href="' .. luci.config.main.resourcebase .. '/css/jquery.minicolors.css?ver=' .. acn_status.version() .. '" type="text/css" />\n'
.. "<script type='text/javascript'>\n"
.. "    var has_custom_logo = " .. has_custom_logo .. ";\n"
.. "    var ipdata = " .. json_ipdata ..";\n"
.. "    var wan_fallback_ip = '" .. wan_fallback_ip .. "';\n"
.. "    var wan_fallback_nm = '" .. wan_fallback_nm .. "';\n"
.. "    var wan_static_ip = '"   .. wan_static_ip .. "';\n"
.. "    var wan_static_nm = '"   .. wan_static_nm .. "';\n"
.. "    var local_lan_ip = '" .. local_lan_ip .. "';\n"
.. "    var local_lan_netmask = '" .. local_lan_netmask .. "';\n"
.. "    var guest_lan_ip = '" .. guest_lan_ip .. "';\n"
.. "    var guest_lan_netmask = '" .. guest_lan_netmask .. "';\n"
.. "    var custom_lan_data = " .. custom_lan_data .. ";\n"
.. "    var dae_ports = " .. json.encode(dae_ports) .. ";\n"
.. "    var mgmt_enabled = " .. tostring(mgmt_enabled) .. "\n"
.. "</script>"

-- Modals for this page
luci.dispatcher.context.modal_template = luci.dispatcher.context.modal_template or {}
luci.dispatcher.context.modal_template[#luci.dispatcher.context.modal_template + 1] = "admin_network/hotspot_custom_logo"

s = m:section(NamedSection,"hotspot", "hotspot", translate("Network Settings") )

s.sub_title_class = true
s.addremove = false
s.anonymous = true

-- #7932 If no bb plugin controls device, user can control it
if is_bb_controlled then
    local hotspot_bb_alert = s:option(DummyValue, "hotspot_bb_alert","")
    hotspot_bb_alert.template = "admin_network/hotspot_bb_alert"
    hotspot_bb_alert.msg = "Please login to your " .. product.company_name() .. " Cloud account in order to manage this device's hotspot and captive portal settings."

else
    -- #8645: lock down parts of the UI when the device is cloud managed
    if mgmt_enabled then
        local cloud_controller_url = acn_uci:get("acn", "mgmt", "controller_url") or brand.controller_url
        local hotspot_bb_alert = s:option(DummyValue, "hotspot_bb_alert","")
        hotspot_bb_alert.template = "admin_network/hotspot_bb_alert"
        hotspot_bb_alert.msg = "This device is currently being managed by the <a href='" .. cloud_controller_url .. "' target='_blank'>" .. product.company_name() .. " Cloud Controller</a>. Please login to your Cloud account to make any hotspot configuration changes."
    end
    --=======================================================
    local hs_status,hs_status_smart,hs_ipaddr,hs_radius1,hs_radius2,hs_port1,hs_acct_enable,hs_port2,hs_coa_enable,hs_coaport,hs_coaserver,hs_coasecret,hs_shared,hs_portal_url,hs_portal_secret,hs_wall,hs_auth
    local hs_session_timeout,hs_idle_timeout,hs_radsec_enable,hs_macauth,hs_redir_url,hs_swap_octets,hs_dhcpgateway,hs_dhcpgatewayport, hs_simple_pass, hs_smartisolation

    hs_status = s:option(Flag, "hs_status", translate("Enable Hotspot Service"))

    hs_mode = s:option(ListValue, "hs_mode", translate("Mode"))
    hs_mode:value("external_portal", translate("External Captive Portal Service"))
    hs_mode:value("no_auth", translate("No Authentication"))
    hs_mode:value("simple_pass", translate("Simple Password-Only Splash Page"))
    hs_mode:value("local_splash_ext_radius", translate("Local Splash Page with External RADIUS"))

    if is_wianchor then
        -- https://redmine.ignitenet.com/issues/20302
        hs_mode:value("wi_anchor_controlled", "Smart Indoor Location controlled(No Auth)")

        function hs_mode.cfgvalue(self, section)
            local is_wi_anchor_controlled = (acn_uci:get("addon", "wianchor", "hotspotEnabled") == "1")
            local hs_mode_val = ListValue.cfgvalue(self, section)
            if is_wi_anchor_controlled then
              hs_mode_val = "wi_anchor_controlled"
            end
            return hs_mode_val
        end

        function hs_mode.write(self, section, value)
            is_wi_anchor_controlled = "0"
            if value == "wi_anchor_controlled" then
              is_wi_anchor_controlled = "1"
              value = "no_auth"
            end
            acn_uci:set("addon", "wianchor", "hotspotEnabled", is_wi_anchor_controlled)
            acn_uci:save("addon")
            ListValue.write(self, section, value)
        end
    end
    --subnet                = s:option(DummyValue, "_Link", translate("Subnet"))
    --hs_status_smart   = s:option(Flag, "hs_status_smart", translate("Use \"Smart Guest Isolation\""))
    hs_ipaddr           = s:option(Value, "listen", translate("IP Address"))
    hs_mask             = s:option(Value, "dynip_mask", translate("Network Mask"))
    hs_dhcp_sta         = s:option(Value, "dhcpstart", translate("DHCP Start"))
    hs_dhcp_end         = s:option(Value, "dhcpend", translate("DHCP End"))
    hs_dhcp_lease       = s:option(Value, "lease", translate("DHCP Lease Time"))
    hs_dns1             = s:option(Value, "dns1", translate("DNS 1"))
    hs_dns2             = s:option(Value, "dns2", translate("DNS 2"))
    hs_domain           = s:option(Value, "dns_domain", translate("DNS Domain Name"))
    hs_dhcpgateway      = s:option(Value, "dhcpgateway", translate("DHCP Gateway"))
    hs_dhcpgatewayport      = s:option(Value, "dhcpgatewayport", translate("DHCP Gateway Port"))
    --hs_dhcpgateway.help_tip = "Configure the DHCP gateway IP address if you want to use an external DHCP server instead of the internal one."
    --hs_dhcpgatewayport.help_tip = "The listening port used by DHCP gateway."
    hs_dhcpgatewayport.default  = 67

    hs_smartisolation = s:option(ListValue, "smartisolation", translate("Smart Isolation"))
    --hs_smartisolation.help_tip = "Select this if you want to prevent Hotspot users to possibly access WAN resources."
    hs_smartisolation:value("0", translate("Disable (full access)"))
    hs_smartisolation:value("1", translate("Internet access only"))
    hs_smartisolation:value("2", translate("LAN access only"))
    hs_smartisolation:value("3", translate("Internet access strict"))
    hs_smartisolation.default = "0"
    --hs_dns_mapping = s:option(TextValue, "dns_mapping", translate("DNS Mapping"))

    --hs_dns_mapping.width       = "400px"
    --hs_dns_mapping.rows        = 10
    --hs_dns_mapping.help_text   = "Enter a list of space or newline-delimited hostnames and IPs.<br\>"
    --                       .. "Example: 203.211.150.204 www.paypal.com"

    --hs_dns1:depends("hs_mode", "external_portal")
    --hs_dns1:depends("hs_mode", "local_splash_ext_radius")
    --hs_dns1:depends("hs_mode", "simple_pass")
    --hs_dns1:depends("hs_mode", "no_auth")

    --hs_dns2:depends("hs_mode", "external_portal")
    --hs_dns2:depends("hs_mode", "local_splash_ext_radius")

    --hs_domain:depends("hs_mode", "external_portal")
    --hs_domain:depends("hs_mode", "local_splash_ext_radius")

    s2 = m:section(NamedSection,"hotspot", "hotspot", translate("RADIUS Settings") )

    s2.config_id_offset = 1
    s2.sub_title_class = true
    s2.addremove = false
    s2.anonymous = true

    hs_radius_enable    = s2:option(Flag, "hs_radius_enabled", translate("Enable RADIUS Auth"))
    hs_radius1          = s2:option(Value, "hs_radius1", translate("RADIUS Server 1"))
    -- fake_XXX: fix browser autofill issue.
    fake_user1             = s2:option(Value, "fake_user1", translate("fake_user"))
    fake_pass1             = s2:option(Value, "fake_password1", translate("fake_pass"))
    hs_radius2          = s2:option(Value, "hs_radius2", translate("RADIUS Server 2"))
    hs_shared           = s2:option(Value, "hs_shared", translate("RADIUS Shared Secret"))
    hs_port1            = s2:option(Value, "hs_auth_port", translate("RADIUS Auth Port"))
    hs_acct_enable      = s2:option(Flag, "hs_acct_enable", translate("RADIUS Accounting"))
    hs_port2            = s2:option(Value, "hs_acct_port", translate("Acct Port"))
    hs_coa_enable       = s2:option(Flag, "hs_coa_enable", translate("Dynamic Authorization"))
    hs_coaport          = s2:option(Value, "hs_coaport", translate("DAE Port"))
    hs_coaserver        = s2:option(Value, "hs_coaserver", translate("DAE Client"))
    hs_coasecret        = s2:option(Value, "hs_coasecret", translate("DAE Secret"))

    hs_coa_enable.default = "0"
    hs_coa_enable.rmempty = false
    hs_coasecret.password = true

    function hs_coa_enable.write(self, section, value)
        Flag.write(self, section, value)
        if value == "0" then
            m.uci:delete("firewall", "HS_CoA")
        end
    end

    hs_coaport:depends("hs_coa_enable", "1")

    function hs_coaport.write(self, section, value)
        Value.write(self, section, value)
        if value then
            m.uci:set("firewall", "HS_CoA", "rule")
            m.uci:set("firewall", "HS_CoA", "enabled", "1")
            m.uci:set("firewall", "HS_CoA", "name", "CoA-Allowed")
            m.uci:set("firewall", "HS_CoA", "src", "wan")
            m.uci:set("firewall", "HS_CoA", "proto", "udp")
            m.uci:set("firewall", "HS_CoA", "target", "ACCEPT")
            m.uci:set("firewall", "HS_CoA", "family", "ipv4")
            m.uci:set("firewall", "HS_CoA", "dest_port", value)
        end
    end

    hs_coaserver:depends("hs_coa_enable", "1")

    function hs_coaserver.write(self, section, value)
        Value.write(self, section, value)
    end

    hs_coasecret:depends("hs_coa_enable", "1")

    function hs_coasecret.write(self, section, value)
        Value.write(self, section, value)
    end

    hs_radsec_enable    = s2:option(Flag, "hs_radsec_enable", translate("Enable RadSec"))
    hs_macauth          = s2:option(Flag, "hs_macauth", translate("Enable MAC Auth"))

    hs_macauth.enabled = "on"
    hs_macauth.disabled = ""
    hs_macauth.rmempty = false

    function hs_macauth.write(self, section, value)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" then
            Flag.remove(self, section, value)
        else
            Flag.write(self, section, value)
        end
    end

    hs_eaptype          = s2:option(ListValue, "hs_radius_eaptype", translate("RADIUS Auth Method"))
    loc_id              = s2:option(Value, "loc_id", translate("Local ID"))
    loc_name            = s2:option(Value, "loc_name", translate("Local Name"))
    nasid               = s2:option(Value, "nasid", translate("NAS ID"))

    --hs_radius_enable:depends("hs_mode", "external_portal")
    hs_radius_enable.default = "1"
    hs_radius_enable.rmempty    = false

    --hs_radius1:depends("hs_mode", "external_portal")
    --hs_radius1:depends("hs_mode", "local_splash_ext_radius")
    --hs_radius2:depends("hs_mode", "external_portal")
    --hs_radius2:depends("hs_mode", "local_splash_ext_radius")
    --hs_shared:depends("hs_mode", "external_portal")
    --hs_shared:depends("hs_mode", "local_splash_ext_radius")
    --hs_port1:depends("hs_mode", "external_portal")
    --hs_port1:depends("hs_mode", "local_splash_ext_radius")
    --hs_port2:depends("hs_mode", "external_portal")
    --hs_port2:depends("hs_mode", "local_splash_ext_radius")
    --hs_radsec_enable:depends("hs_mode", "external_portal")
    --hs_radsec_enable:depends("hs_mode", "local_splash_ext_radius")
    --hs_eaptype:depends("hs_mode", "external_portal")
    --hs_eaptype:depends("hs_mode", "local_splash_ext_radius")
    --loc_id:depends("hs_mode", "external_portal")
    --loc_id:depends("hs_mode", "local_splash_ext_radius")
    --loc_name:depends("hs_mode", "external_portal")
    --loc_name:depends("hs_mode", "local_splash_ext_radius")
    --nasid:depends("hs_mode", "external_portal")
    --nasid:depends("hs_mode", "local_splash_ext_radius")

    hs_eaptype.default = "chap"

    hs_eaptype:value("chap", "CHAP")
    hs_eaptype:value("pap", "PAP")
    hs_eaptype:value("mschapv2", "MSCHAPv2")

    s3 = m:section(NamedSection,"hotspot", "hotspot", translate("Captive Portal Settings") )

    s3.config_id_offset = 2
    s3.sub_title_class = true
    s3.addremove = false
    s3.anonymous = true

    -- fake_XXX: fix browser autofill issue.
    fake_user2             = s3:option(Value, "fake_user2", translate("fake_user"))
    fake_pass2             = s3:option(Value, "fake_password2", translate("fake_pass"))
    hs_https               = s3:option(Flag, "hs_https", translate("HTTPS"))
    hs_https_domain        = s3:option(Value, "hs_https_domain", translate("HTTPS Domain"))
    hs_https_domain:depends("hs_https", "1")
    hs_portal_url       = s3:option(Value, "hs_portal_url", translate("Captive Portal URL"))
    hs_portal_secret    = s3:option(Value, "hs_portal_secret", translate("Captive Portal Secret"))

    hs_simple_pass      = s3:option(Value, "hs_simple_pass", translate("Splash Page Password"))

    --hs_simple_pass:depends("hs_mode", "simple_pass")

    hs_custom_portal    = s3:option(Flag, "hs_custom_portal", translate("Customize Splash Page"))
    hs_portal_header    = s3:option(Value, "hs_portal_header", translate("Title") )
    hs_portal_bg        = s3:option(Value, "hs_portal_background", translate("Background Color"))
    hs_portal_bg.default= "#1d2024"

    --hs_portal_url:depends("hs_mode", "external_portal")
    --hs_portal_secret:depends("hs_mode", "external_portal")

    --hs_custom_portal:depends("hs_mode", "simple_pass")
    --hs_custom_portal:depends("hs_mode", "no_auth")
    --hs_custom_portal:depends("hs_mode", "local_splash_ext_radius")

    hs_portal_logo_title    = s3:option(DummyValue, "_none", translate("Logo Image"))
    hs_portal_logo_title.render = function(self, s3, scope)   
        luci.template.render("cbi/valueheader", {section = s3, self = self})
        self.template = "cbi/value_inline_right"
    end

    hs_portal_logo_btn           = s3:option( DummyValue, "_display", translate("View"))
    hs_portal_logo_btn.empty_next        = true
    hs_portal_logo_btn.cond_optional     = true  
    hs_portal_logo_btn.optional          = false 
    hs_portal_logo_btn.custom  = "style='width:50px' "
    hs_portal_logo_btn.render =  function(self, s3, scope)
        local logo_filename = self.map.uci:get("hotspot", "hotspot", "hs_portal_custom_logo")

        luci.http.write('<div style="display:inline-block" class="scan-btn" >')
        self.template = "admin_network/hotspot_custom_logo_btn"
        self.has_custom_logo = has_custom_logo
        self.hs_portal_custom_logo = logo_filename
        if mgmt_enabled then
            self.is_disabled = true
        end
        AbstractValue.render(self, s3, nil)
        luci.http.write('</div><br></div>')
    end

    --hs_portal_header:depends("hs_custom_portal", "1")
    --hs_portal_logo_title:depends("hs_custom_portal", "1")
    --hs_portal_logo_btn:depends("hs_custom_portal", "1")
    --hs_portal_bg:depends("hs_custom_portal", "1")
    --hs_portal_header.datatype = "isBeginningWhiteSpace"

    hs_session_timeout  = s3:option(Value, "hs_session_timeout", translate("Session Timeout"))
    hs_idle_timeout     = s3:option(Value, "hs_idle_timeout", translate("Idle Timeout"))
    hs_redir_url        = s3:option(Value, "hs_redir_url", translate("Landing URL"))
    hs_swap_octets  = s3:option(Flag, "hs_swap_octets", translate("Swap Octets"))
    --hs_swap_octets:depends("hs_mode", "external_portal")
    hs_swap_octets.default = 0

    hs_wall             = s3:option(TextValue, "hs_wall", translate("Walled Garden"))
    hs_auth             = s3:option(TextValue, "hs_auth", translate("Auth White List"))

    hs_wall.width       = "400px"
    hs_wall.rows        = 10
    hs_wall.help_text   = translate("Enter a list of space or newline-delimited hostnames and IPs.")
                            .. ("<br/>") .. translate("Example: 203.211.150.204 66.235.128.0/17 www.paypal.com")
    hs_auth.width       = "400px"
    hs_auth.rows        = 10
    hs_auth.help_text   = translate("Enter a list of space or newline-delimited MAC addresses.")
                            ..("<br/>")  .. translate("Example: 00:11:22:33:44:55 55:44:33:22:11:00")

    hs_mask:value("255.255.255.0")
    hs_mask:value("255.255.0.0")
    hs_mask:value("255.0.0.0")
    hs_mask.default = "255.255.255.0"
    hs_mask.optional = false
    hs_mask.force_required = true

    hs_session_timeout.datatype = "range(0,86400)"
    hs_session_timeout.default  = 0
    --hs_session_timeout.help_tip = "Zero means unlimited."
    hs_idle_timeout.datatype    = "range(0,86400)"
    hs_idle_timeout.default     = 0
    --hs_idle_timeout.help_tip    = "Zero means unlimited."

    hs_port1.default        = 1812
    hs_port2.default        = 1813

    hs_acct_enable.default = "1"
    hs_acct_enable.rmempty = false

    function hs_acct_enable.write(self, section, value)
        Flag.write(self, section, value)
    end

    hs_port2:depends("hs_acct_enable", "1")

    hs_status.rmempty       = false
    loc_id.datatype         = "range(0,9999)"
    --loc_name.datatype       = "isBeginningWhiteSpace"
    --nasid.datatype          = "isBeginningWhiteSpace"
    hs_dhcp_lease.datatype  = "range(600,43200)"
    hs_dhcp_lease.default   = "600"

    -- This is handled in js validate, don't set datatype here
    --hs_ipaddr.datatype    = "ip4addr"
    --hs_radius1.datatype           = "hostname"
    --hs_shared.datatype            = "limited_len_str(1,255)"
    --hs_portal_secret.datatype     = "limited_len_str(1,255)"
    --hs_portal_url.datatype        = "limited_len_str(1,255)"
    --hs_dhcp_sta.datatype  = "range(1,254)"
    --hs_dhcp_end.datatype  = "range(1,254)"
    --hs_dhcp_sta.datatype  = "range(1,254)"
    --hs_dhcp_end.datatype  = "range(1,254)"
    hs_https.rmempty       = false
    hs_shared.password = true
    hs_portal_secret.password = true
    fake_user1.header_style = "display:none"
    fake_pass1.password = true
    fake_pass1.header_style = "display:none"
    fake_user2.header_style = "display:none"
    fake_pass2.password = true
    fake_pass2.header_style = "display:none"

    hs_port1.datatype       = "port"
    --hs_mask.datatype        = "netmask"
    --hs_dns1.datatype        = "ip4addr"
    hs_dns2.datatype        = "ip4addr"
    --hs_domain.datatype      = "isDomain"

    hs_radsec_enable.rmempty    = false

    -- #8645: lock down parts of the UI when the device is cloud managed
    if mgmt_enabled then
        hs_status.is_disabled = true
        hs_mode.is_disabled = true
        hs_ipaddr.is_disabled = true
        hs_mask.is_disabled = true
        hs_dhcp_sta.is_disabled = true
        hs_dhcp_end.is_disabled = true
        hs_dhcp_lease.is_disabled = true
        hs_dns1.is_disabled = true
        hs_dns2.is_disabled = true
        hs_domain.is_disabled = true
        hs_dhcpgateway.is_disabled = true
        hs_dhcpgatewayport.is_disabled = true
        hs_smartisolation.is_disabled = true
        hs_domain.is_disabled = true
        hs_radius_enable.is_disabled = true
        hs_radius1.is_disabled = true
        hs_radius2.is_disabled = true
        hs_shared.is_disabled = true
        hs_port1.is_disabled = true
        hs_acct_enable.is_disabled = true
        hs_port2.is_disabled = true
        hs_coa_enable.is_disabled = true
        hs_coaport.is_disabled = true
        hs_coaserver.is_disabled = true
        hs_coasecret.is_disabled = true
        hs_radsec_enable.is_disabled = true
        hs_eaptype.is_disabled = true
        hs_macauth.is_disabled = true
        loc_id.is_disabled = true
        loc_name.is_disabled = true
        nasid.is_disabled = true
        hs_portal_url.is_disabled = true
        hs_portal_secret.is_disabled = true
        hs_simple_pass.is_disabled = true
        hs_custom_portal.is_disabled = true
        hs_portal_header.is_disabled = true
        hs_portal_bg.is_disabled = true
        hs_session_timeout.is_disabled = true
        hs_idle_timeout.is_disabled = true
        hs_redir_url.is_disabled = true
        hs_swap_octets.is_disabled = true
        hs_wall.is_disabled = true
        hs_auth.is_disabled = true
        --hs_dns_mapping.is_disabled = true
        hs_https.is_disabled = true
        hs_https_domain.is_disabled = true
    end

    function hs_auth.cfgvalue(self, section)
        local hs_auth_value   = m.uci:get("hotspot", section, "hs_auth")
        local str_val = ""
        if hs_auth_value then 
            local macs  = luci.util.split(hs_auth_value, " ")
    
            for i, value in ipairs(macs) do
                value = luci.util.trim(value)
                if value and #value >= 12 then
                    local mac = value:gsub("-", ":")
                    str_val = str_val .. mac .. " "
                end
            end
        end
        return str_val
    end

    function hs_auth.write(self, section, value)

        -- replace newlines with spaces
        value = value:gsub("\r\n", " ")
        value = value:gsub("\n", " ")
        value = value:gsub(":", "-")

        Value.write(self, section, value)
    end

    function hs_wall.write(self, section, value)

        -- replace newlines with spaces
        value = value:gsub("\r\n", " ")
        value = value:gsub("\n", " ")

        Value.write(self, section, value)
    end

    function hs_status.write(self, section, value)
        Flag.write(self, section, value)
    end

    function hs_ipaddr.write(self, section, value)
        Value.write(self, section, value)
        m.uci:set("hotspot", "hotspot" , "dynip",value)
        m.uci:set("hotspot", "hotspot" , "network",value)
    end

    function hs_radius1.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local radius_auth = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_radius_enabled")
        local val = self.map:formvalue(self:cbid(section))

        if (mode == "external_portal" and radius_auth == "0") or mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" then
            return "127.0.0.1"
        else
            return val
        end
    end

    function hs_radius2.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" then
            return ""
        else
            return val
        end
    end

    function hs_ipaddr.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if (mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" or mode == "local_splash_ext_radius") and val == "192.168.182.0" then
            return "192.168.182.1"
        else
            return val
        end
    end

    function hs_dns1.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" or mode == "local_splash_ext_radius" then
            local listen = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".listen")

            if listen == "192.168.182.0" then listen = "192.168.182.1" end

            if mode ~= "local_splash_ext_radius" then
                return listen
            elseif val == "" then
                return listen
            else
                return val
            end
        else
            return val
        end
    end

    function hs_dns2.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" then
            return ""
        else
            return val
        end
    end

    function hs_portal_secret.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" or mode == "local_splash_ext_radius" then
            return "mysecret"
        else
            return val
        end
    end

    function hs_portal_url.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" or mode == "local_splash_ext_radius" then
            local listen = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".listen")

            if listen == "192.168.182.0" then listen = "192.168.182.1" end
                local https = acn_uci:get("hotspot", "hotspot", "hs_https")
                if https == "1" then
                    local https_domain = acn_uci:get("hotspot", "hotspot", "hs_https_domain")
                    return "https://" .. https_domain .. ":4990/www/login.chi"
                else
                    return "http://" .. listen .. ":4990/www/login.chi"
                end
            else
                return val
            end
    end

    function hs_port1.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" then
            return "1812"
        else
            return val
        end
    end

    function hs_port2.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" then
            return "1813"
        else
            return val
        end
    end

    function hs_coaport.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" then
            return ""
        else
            return val
        end
    end

    function loc_id.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" then
            return "0"
        else
            return val
        end
    end

    function loc_name.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" then
            return ""
        else
            return val
        end
    end

    function hs_radsec_enable.write(self, section, value)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" then
            Flag.write(self, section, "0")
        else
            Flag.write(self, section, value)
        end
    end

    function hs_eaptype.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" then
            return "chap"
        else
            return val
        end
    end

    function hs_shared.formvalue(self, section)
        local mode = self.map:formvalue("cbid." .. self.map.config .. "." .. section .. ".hs_mode")
        local val = self.map:formvalue(self:cbid(section))

        if mode == "simple_pass" or mode == "no_auth" or mode == "wi_anchor_controlled" then
            return "mysecret"
        else
            return val
        end
    end

    function hs_mask.write(self, section, value)
        Value.write(self, section, value)
        m.uci:set("hotspot", "hotspot" , "netmask",value)
    end

    function hs_smartisolation.write( self, section, value )
        ListValue.write(self, section, value)
        acn_uci:set("network", "hotspot", "smart_isolation", value)
        acn_uci:save("network")
    end

--    function hs_dns_mapping.write(self, section, value)
--        local network_hs_ipaddr = acn_uci:get("hotspot", "hotspot", "listen")
--        acn_uci:set("network", "hotspot", "ipaddr", network_hs_ipaddr)
--        acn_uci:save("network")
--        -- replace newlines with spaces
--        value = value:gsub("\r\n", " ")
--        value = value:gsub("\n", " ")
--        Value.write(self, section, value)
--    end

    function fake_user1.write(self, section)
        return
    end

    function fake_pass1.write(self, section)
        return
    end

    function fake_user2.write(self, section)
        return
    end

    function fake_pass2.write(self, section)
        return
    end
end -- #7932 end

return m
