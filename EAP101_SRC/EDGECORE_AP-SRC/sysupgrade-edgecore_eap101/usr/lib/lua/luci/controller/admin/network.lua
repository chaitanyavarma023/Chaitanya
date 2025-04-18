-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Copyright 2011-2018 Jo-Philipp Wich <jo@mein.io>
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.admin.network", package.seeall)

function index()
  local page

--  if page.inreq then
    page = entry({"admin", "network", "switch"}, view("network/switch"), _("Switch"), 20)
    page.uci_depends = { network = { ["@switch[0]"] = "switch" } }

    page = entry({"admin", "network", "wireless"}, view("network/wireless"), _('Wireless'), 15)
    page.uci_depends = { wireless = { ["@wifi-device[0]"] = "wifi-device" } }
    page.leaf = true

    page = entry({"admin", "network", "network"}, view("network/interfaces"), _("Interfaces"), 10)
    page.leaf   = true
    page.subindex = true

    page = entry({"admin", "network", "internet"}, cbi("internet"), _("Internet"), 10)
    page.leaf = true

    page = entry({"admin", "network", "ethernet"}, cbi("ethernet"), _("Ethernet"), 10)
    page.leaf = true

    page = entry({"admin", "network", "lan"}, cbi("lan"), _("LAN"), 10)
    page.leaf = true

    page = entry({"admin", "network", "firewall_rule"}, cbi("firewall"), _("Firewall Rules"), 10)
    page.leaf = true

    page = entry({"admin", "network", "firewall_portfw"}, cbi("firewall_portfw"), _("Firewall Rules"), 10)
    page.leaf = true

    page = entry({"admin", "network", "hotspot"}, cbi("hotspot"), _("Hotspot Settings"), 10)
    page.leaf = true
    entry({"admin", "network", "hotspot_upload_logo"}, call("hotspot_upload_logo"), _("Hotspot Actions"), 70)
    entry({"admin", "network", "hotspot_remove_logo"}, call("hotspot_remove_logo"), _("Hotspot Actions"), 70)

    page = entry({"admin", "network", "openroaming"}, template("admin_network/openroaming"), _("OpenRoaming"), 10)
    page.leaf = true

    page = entry({"admin", "network", "dhcp_snooping"}, cbi("dhcp_snooping"), _("DHCP Snooping"), 10)
    page.leaf = true
    page = entry({"admin", "network", "arp_inspection"}, cbi("arp_inspection"), _("ARP Inspection"), 10)
    page.leaf = true

    page = entry({"admin", "network", "dhcp_relay"}, cbi("dhcp_relay"), _("DHCP Relay"), 10)
    page.leaf = true

    page = node("admin", "network", "dhcp")
    page.uci_depends = { dhcp = true }
    page.target = view("network/dhcp")
    page.title  = _("DHCP and DNS")
    page.order  = 30

    page = node("admin", "network", "hosts")
    page.uci_depends = { dhcp = true }
    page.target = view("network/hosts")
    page.title  = _("Hostnames")
    page.order  = 40

    page  = node("admin", "network", "routes")
    page.target = view("network/routes")
    page.title  = _("Static Routes")
    page.order  = 50

    page = node("admin", "network", "diagnostics")
    page.target = template("admin_network/diagnostics")
    page.title  = _("Diagnostics")
    page.order  = 60
--  end

    page = entry({"admin", "network", "diag_ping"}, call("diag_ping"), nil)
    page.leaf = true

    page = entry({"admin", "network", "diag_nslookup"}, call("diag_nslookup"), nil)
    page.leaf = true

    page = entry({"admin", "network", "diag_traceroute"}, call("diag_traceroute"), nil)
    page.leaf = true

    page = entry({"admin", "network", "diag_netperf_server"}, call("diag_speedtest_netperf"), nil)
    page.leaf = true

    page = entry({"admin", "network", "diag_speedtest_server"}, call("diag_speedtest"), nil)
    page.leaf = true

end

local logo_real_dir = "/etc/chilli/www"

function hotspot_upload_logo()
    local sys = require "luci.sys"
    local fs  = require "nixio.fs"
    local uci = require("luci.model.uci").cursor()

    local logo_tmp_file = "hotspot_logo_custom"
    local logo_tmp = "/tmp/" .. logo_tmp_file
    
    local img_size = 0
    local img_size_limit = 500000 --500K

    local function post_logo_cmd()
        return ( 0 == os.execute(
            "upload_logo.sh %q %q"
            %{ logo_tmp, logo_real_dir }
        ) )
    end

    local fp
    luci.http.setfilehandler(
        function(meta, chunk, eof)
            if not fp then
                fp = io.open(logo_tmp, "w")
            end
            if chunk then
                img_size = img_size + #chunk
                if img_size <= img_size_limit then
                    fp:write(chunk)
                end
            end
            if eof then
                fp:close()
            end
        end
    )

    local upload = luci.http.formvalue("logo_file")
    if upload and #upload > 0 then

        local logo_ext = luci.http.formvalue("logo_ext") or ""
        if logo_ext and #logo_ext > 0 then
            luci.sys.call("mv -f ".. logo_tmp .. " " .. logo_tmp .. "." .. logo_ext)
            logo_tmp = logo_tmp .. "." .. logo_ext
        end
        if post_logo_cmd() then
            uci:set("hotspot", "hotspot", "hs_portal_logo", "1" )
            uci:set("hotspot", "hotspot", "hs_portal_custom_logo", logo_tmp_file .. "." .. logo_ext)

            -- Remove the md5 value so that mgmtd knows the file is removed/different
            uci:set("files", "hotspot_logo", "md5", "")
            luci.http.redirect(luci.dispatcher.build_url("admin/network/hotspot"))
        end
    end
end

function hotspot_remove_logo()
    local uci = require("luci.model.uci").cursor()
    hs_portal_custom_logo = uci:get("hotspot", "hotspot", "hs_portal_custom_logo") or ""
    if hs_portal_custom_logo ~= "" then
        uci:set("hotspot", "hotspot", "hs_portal_logo", "0" )
        uci:delete("hotspot", "hotspot", "hs_portal_logo")

        -- Remove the hotspot_logo config section when file is removed
        uci:delete("files", "hotspot_logo")
        luci.sys.call("rm -f " .. logo_real_dir .. "/" .. hs_portal_custom_logo .. " 2>/dev/null")
        luci.http.write("Removed successfully")
    else
        luci.http.write("Failed to remove")
    end
end

function diag_command(cmd)
    local path = luci.dispatcher.context.requestpath
    local addr = path[#path]
    local util = ""

    if cmd == "speedtest-cli" then
      luci.http.prepare_content("text/plain")

      if addr and addr:match("^[0-9]+$") then
        util = io.popen(cmd .. " --server=" .. addr .. " 2>&1")
      else
        util = io.popen(cmd .. " 2>&1")
      end

      if util then
        while true do
          local ln = util:read("*l")
          if not ln then 
            break
          end
          luci.http.write(ln)
          luci.http.write("\n")
        end

        util:close()
      end

      return
    else
      if addr and addr:match("^[a-zA-Z0-9%-%.:_]+$") then
          luci.http.prepare_content("text/plain")

          local util = io.popen(cmd % addr)
          if util then
              while true do
                  local ln = util:read("*l")
                  if not ln then break end
                  luci.http.write(ln)
                  luci.http.write("\n")
              end

              util:close()
          end

          return
      end
    end

    luci.http.status(500, "Bad address")
end

function diag_ping()
    diag_command("ping -c 5 -W 1 %q 2>&1")
end

function diag_traceroute()
    diag_command("traceroute -q 1 -w 1 -n %q 2>&1")
end

function diag_nslookup()
    diag_command("nslookup %q 2>&1")
end

function diag_speedtest_netperf()
    diag_command("speedtest-netperf.sh -H %q -t 20 -c 2>&1")
end

function diag_speedtest()
    diag_command("speedtest-cli")
end
