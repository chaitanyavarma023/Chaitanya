-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Licensed to the public under the Apache License 2.0.

local io     = require "io"
local os     = require "os"
local table  = require "table"
local nixio  = require "nixio"
local fs     = require "nixio.fs"
local uci    = require "luci.model.uci"

local luci  = {}
luci.util   = require "luci.util"
luci.ip     = require "luci.acn.ip"

local tonumber, ipairs, pairs, pcall, type, next, setmetatable, require, select, unpack =
	tonumber, ipairs, pairs, pcall, type, next, setmetatable, require, select, unpack


module "luci.sys"

function call(...)
	return os.execute(...) / 256
end

exec = luci.util.exec

-- containing the whole environment is returned otherwise this function returns
-- the corresponding string value for the given name or nil if no such variable
-- exists.
getenv = nixio.getenv

function hostname(newname)
	if type(newname) == "string" and #newname > 0 then
		fs.writefile( "/proc/sys/kernel/hostname", newname )
		return newname
	else
		return nixio.uname().nodename
	end
end

function productname()
	local prod_info = fs.readfile("/etc/ec_device_info")
	local prod_name = prod_info:match("DEVICE_PRODUCT='([^']+)")
	return prod_name
end

function httpget(url, stream, target)
	if not target then
		local source = stream and io.popen or luci.util.exec
		return source("wget -qO- %s" % luci.util.shellquote(url))
	else
		return os.execute("wget -qO %s %s" %
			{luci.util.shellquote(target), luci.util.shellquote(url)})
	end
end

--- Returns the system load average values.
-- @return	String containing the average load value 1 minute ago
-- @return	String containing the average load value 5 minutes ago
-- @return	String containing the average load value 15 minutes ago
function loadavg()
	local info = nixio.sysinfo()
	return info.loads[1], info.loads[2], info.loads[3]
end

--- Returns the system memory usage percent value.
-- @return  Number containing the used memory percent
function memused()
    local info = nixio.sysinfo()
    return (info.totalram - info.freeram) / info.totalram * 100
end

function reboot()
	return os.execute("reboot >/dev/null 2>&1")
end

function syslog()
	return luci.util.exec("logread")
end

function dmesg()
	return luci.util.exec("dmesg")
end

function uniqueid(bytes)
	local rand = fs.readfile("/dev/urandom", bytes)
	return rand and nixio.bin.hexlify(rand)
end

function uptime()
	return nixio.sysinfo().uptime
end


net = {}


--			The following fields are defined for arp entry objects:
--			{ "IP address", "HW address", "HW type", "Flags", "Mask", "Device" }
function net.arptable(callback)
	local arp = (not callback) and {} or nil
	local e, r, v
	if fs.access("/proc/net/arp") then
		for e in io.lines("/proc/net/arp") do
			local r = { }, v
			for v in e:gmatch("%S+") do
				r[#r+1] = v
			end

			if r[1] ~= "IP" then
				local x = {
					["IP address"] = r[1],
					["HW type"]    = r[2],
					["Flags"]      = r[3],
					["HW address"] = r[4],
					["Mask"]       = r[5],
					["Device"]     = r[6]
				}

				if callback then
					callback(x)
				else
					arp = arp or { }
					arp[#arp+1] = x
				end
			end
		end
	end
	return arp
end

local function _nethints(what, callback)
	local _, k, e, mac, ip, name, duid, iaid
	local cur = uci.cursor()
	local ifn = { }
	local hosts = { }
	local lookup = { }

	local function _add(i, ...)
		local k = select(i, ...)
		if k then
			if not hosts[k] then hosts[k] = { } end
			hosts[k][1] = select(1, ...) or hosts[k][1]
			hosts[k][2] = select(2, ...) or hosts[k][2]
			hosts[k][3] = select(3, ...) or hosts[k][3]
			hosts[k][4] = select(4, ...) or hosts[k][4]
		end
	end

	luci.ip.neighbors(nil, function(neigh)
		if neigh.mac and neigh.family == 4 then
			_add(what, neigh.mac:string(), neigh.dest:string(), nil, nil)
		elseif neigh.mac and neigh.family == 6 then
			_add(what, neigh.mac:string(), nil, neigh.dest:string(), nil)
		end
	end)

	if fs.access("/etc/ethers") then
		for e in io.lines("/etc/ethers") do
			mac, name = e:match("^([a-fA-F0-9:-]+)%s+(%S+)")
			mac = luci.ip.checkmac(mac)
			if mac and name then
				if luci.ip.checkip4(name) then
					_add(what, mac, name, nil, nil)
				else
					_add(what, mac, nil, nil, name)
				end
			end
		end
	end

	cur:foreach("dhcp", "dnsmasq",
		function(s)
			if s.leasefile and fs.access(s.leasefile) then
				for e in io.lines(s.leasefile) do
					mac, ip, name = e:match("^%d+ (%S+) (%S+) (%S+)")
					mac = luci.ip.checkmac(mac)
					if mac and ip then
						_add(what, mac, ip, nil, name ~= "*" and name)
					end
				end
			end
		end
	)

	cur:foreach("dhcp", "odhcpd",
		function(s)
			if type(s.leasefile) == "string" and fs.access(s.leasefile) then
				for e in io.lines(s.leasefile) do
					duid, iaid, name, _, ip = e:match("^# %S+ (%S+) (%S+) (%S+) (-?%d+) %S+ %S+ ([0-9a-f:.]+)/[0-9]+")
					mac = net.duid_to_mac(duid)
					if mac then
						if ip and iaid == "ipv4" then
							_add(what, mac, ip, nil, name ~= "*" and name)
						elseif ip then
							_add(what, mac, nil, ip, name ~= "*" and name)
						end
					end
				end
			end
		end
	)

	cur:foreach("dhcp", "host",
		function(s)
			for mac in luci.util.imatch(s.mac) do
				mac = luci.ip.checkmac(mac)
				if mac then
					_add(what, mac, s.ip, nil, s.name)
				end
			end
		end)

	for _, e in ipairs(nixio.getifaddrs()) do
		if e.name ~= "lo" then
			ifn[e.name] = ifn[e.name] or { }
			if e.family == "packet" and e.addr and #e.addr == 17 then
				ifn[e.name][1] = e.addr:upper()
			elseif e.family == "inet" then
				ifn[e.name][2] = e.addr
			elseif e.family == "inet6" then
				ifn[e.name][3] = e.addr
			end
		end
	end

	for _, e in pairs(ifn) do
		if e[what] and (e[2] or e[3]) then
			_add(what, e[1], e[2], e[3], e[4])
		end
	end

	for _, e in pairs(hosts) do
		lookup[#lookup+1] = (what > 1) and e[what] or (e[2] or e[3])
	end

	if #lookup > 0 then
		lookup = luci.util.ubus("network.rrdns", "lookup", {
			addrs   = lookup,
			timeout = 250,
			limit   = 1000
		}) or { }
	end

	for _, e in luci.util.kspairs(hosts) do
		callback(e[1], e[2], e[3], lookup[e[2]] or lookup[e[3]] or e[4])
	end
end

--          Each entry contains the values in the following order:
--          [ "mac", "name" ]
function net.mac_hints(callback)
	if callback then
		_nethints(1, function(mac, v4, v6, name)
			name = name or v4
			if name and name ~= mac then
				callback(mac, name or v4)
			end
		end)
	else
		local rv = { }
		_nethints(1, function(mac, v4, v6, name)
			name = name or v4
			if name and name ~= mac then
				rv[#rv+1] = { mac, name or v4 }
			end
		end)
		return rv
	end
end

--          Each entry contains the values in the following order:
--          [ "ip", "name" ]
function net.ipv4_hints(callback)
	if callback then
		_nethints(2, function(mac, v4, v6, name)
			name = name or mac
			if name and name ~= v4 then
				callback(v4, name)
			end
		end)
	else
		local rv = { }
		_nethints(2, function(mac, v4, v6, name)
			name = name or mac
			if name and name ~= v4 then
				rv[#rv+1] = { v4, name }
			end
		end)
		return rv
	end
end

--          Each entry contains the values in the following order:
--          [ "ip", "name" ]
function net.ipv6_hints(callback)
	if callback then
		_nethints(3, function(mac, v4, v6, name)
			name = name or mac
			if name and name ~= v6 then
				callback(v6, name)
			end
		end)
	else
		local rv = { }
		_nethints(3, function(mac, v4, v6, name)
			name = name or mac
			if name and name ~= v6 then
				rv[#rv+1] = { v6, name }
			end
		end)
		return rv
	end
end

function net.host_hints(callback)
	if callback then
		_nethints(1, function(mac, v4, v6, name)
			if mac and mac ~= "00:00:00:00:00:00" and (v4 or v6 or name) then
				callback(mac, v4, v6, name)
			end
		end)
	else
		local rv = { }
		_nethints(1, function(mac, v4, v6, name)
			if mac and mac ~= "00:00:00:00:00:00" and (v4 or v6 or name) then
				local e = { }
				if v4   then e.ipv4 = v4   end
				if v6   then e.ipv6 = v6   end
				if name then e.name = name end
				rv[mac] = e
			end
		end)
		return rv
	end
end

function net.conntrack(callback)
	local ok, nfct = pcall(io.lines, "/proc/net/nf_conntrack")
	if not ok or not nfct then
		return nil
	end

	local line, connt = nil, (not callback) and { }
	for line in nfct do
		local fam, l3, l4, timeout, tuples =
			line:match("^(ipv[46]) +(%d+) +%S+ +(%d+) +(%d+) +(.+)$")

		if fam and l3 and l4 and timeout and not tuples:match("^TIME_WAIT ") then
			l4 = nixio.getprotobynumber(l4)

			local entry = {
				bytes = 0,
				packets = 0,
				layer3 = fam,
				layer4 = l4 and l4.name or "unknown",
				timeout = tonumber(timeout, 10)
			}

			local key, val
			for key, val in tuples:gmatch("(%w+)=(%S+)") do
				if key == "bytes" or key == "packets" then
					entry[key] = entry[key] + tonumber(val, 10)
				elseif key == "src" or key == "dst" then
					if entry[key] == nil then
						entry[key] = luci.ip.new(val):string()
					end
				elseif key == "sport" or key == "dport" then
					if entry[key] == nil then
						entry[key] = val
					end
				elseif val then
					entry[key] = val
				end
			end

			if callback then
				callback(entry)
			else
				connt[#connt+1] = entry
			end
		end
	end

	return callback and true or connt
end


--- Determine the current IPv4 default route. If multiple default routes exist,
-- return the one with the lowest metric.
-- @return	Table with the properties of the current default route.
--			The following fields are defined:
--			{ "dest", "gateway", "metric", "refcount", "usecount", "irtt",
--			  "flags", "device" }
function net.defaultroute()
	local route

	net.routes(function(rt)
		if rt.dest:prefix() == 0 and (not route or route.metric > rt.metric) then
			route = rt
		end
	end)

	return route
end

--- Determine the current IPv6 default route. If multiple default routes exist,
-- return the one with the lowest metric.
-- @return	Table with the properties of the current default route.
--			The following fields are defined:
--			{ "source", "dest", "nexthop", "metric", "refcount", "usecount",
--			  "flags", "device" }
function net.defaultroute6()
	local route

	net.routes6(function(rt)
		if rt.dest:prefix() == 0 and rt.device ~= "lo" and 
		   (not route or route.metric > rt.metric)
		then
			route = rt
		end
	end)

	if not route then
		local global_unicast = luci.ip.IPv6("2000::/3")
		net.routes6(function(rt)
			if rt.dest:equal(global_unicast) and
			   (not route or route.metric > rt.metric)
			then
				route = rt
			end
		end)
	end

	return route
end

function net.duid_to_mac(duid)
	local b1, b2, b3, b4, b5, b6

	if type(duid) == "string" then
		-- DUID-LLT / Ethernet
		if #duid == 28 then
			b1, b2, b3, b4, b5, b6 = duid:match("^00010001(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)%x%x%x%x%x%x%x%x$")

		-- DUID-LL / Ethernet
		elseif #duid == 20 then
			b1, b2, b3, b4, b5, b6 = duid:match("^00030001(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)$")

		-- DUID-LL / Ethernet (Without Header)
		elseif #duid == 12 then
			b1, b2, b3, b4, b5, b6 = duid:match("^(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)$")
		end
	end

	return b1 and luci.ip.checkmac(table.concat({ b1, b2, b3, b4, b5, b6 }, ":"))
end

--- Returns the current kernel routing table entries.
-- @return	Table of tables with properties of the corresponding routes.
--			The following fields are defined for route entry tables:
--			{ "dest", "gateway", "metric", "refcount", "usecount", "irtt",
--			  "flags", "device" }
function net.routes(callback)
	local routes = { }

	for line in io.lines("/proc/net/route") do

		local dev, dst_ip, gateway, flags, refcnt, usecnt, metric,
			  dst_mask, mtu, win, irtt = line:match(
			"([^%s]+)\t([A-F0-9]+)\t([A-F0-9]+)\t([A-F0-9]+)\t" ..
			"(%d+)\t(%d+)\t(%d+)\t([A-F0-9]+)\t(%d+)\t(%d+)\t(%d+)"
		)

		if dev then
			gateway  = luci.ip.Hex( gateway,  32, luci.ip.FAMILY_INET4 )
			dst_mask = luci.ip.Hex( dst_mask, 32, luci.ip.FAMILY_INET4 )
			dst_ip   = luci.ip.Hex(
				dst_ip, dst_mask:prefix(dst_mask), luci.ip.FAMILY_INET4
			)

			local rt = {
				dest     = dst_ip,
				gateway  = gateway,
				metric   = tonumber(metric),
				refcount = tonumber(refcnt),
				usecount = tonumber(usecnt),
				mtu      = tonumber(mtu),
				window   = tonumber(window),
				irtt     = tonumber(irtt),
				flags    = tonumber(flags, 16),
				device   = dev
			}

			if callback then
				callback(rt)
			else
				routes[#routes+1] = rt
			end
		end
	end

	return routes
end

--- Returns the current ipv6 kernel routing table entries.
-- @return	Table of tables with properties of the corresponding routes.
--			The following fields are defined for route entry tables:
--			{ "source", "dest", "nexthop", "metric", "refcount", "usecount",
--			  "flags", "device" }
function net.routes6(callback)
	if fs.access("/proc/net/ipv6_route", "r") then
		local routes = { }

		for line in io.lines("/proc/net/ipv6_route") do

			local dst_ip, dst_prefix, src_ip, src_prefix, nexthop,
				  metric, refcnt, usecnt, flags, dev = line:match(
				"([a-f0-9]+) ([a-f0-9]+) " ..
				"([a-f0-9]+) ([a-f0-9]+) " ..
				"([a-f0-9]+) ([a-f0-9]+) " ..
				"([a-f0-9]+) ([a-f0-9]+) " ..
				"([a-f0-9]+) +([^%s]+)"
			)

			if dst_ip and dst_prefix and
			   src_ip and src_prefix and
			   nexthop and metric and
			   refcnt and usecnt and
			   flags and dev
			then
				src_ip = luci.ip.Hex(
					src_ip, tonumber(src_prefix, 16), luci.ip.FAMILY_INET6, false
				)

				dst_ip = luci.ip.Hex(
					dst_ip, tonumber(dst_prefix, 16), luci.ip.FAMILY_INET6, false
				)

				nexthop = luci.ip.Hex( nexthop, 128, luci.ip.FAMILY_INET6, false )

				local rt = {
					source   = src_ip,
					dest     = dst_ip,
					nexthop  = nexthop,
					metric   = tonumber(metric, 16),
					refcount = tonumber(refcnt, 16),
					usecount = tonumber(usecnt, 16),
					flags    = tonumber(flags, 16),
					device   = dev,

					-- lua number is too small for storing the metric
					-- add a metric_raw field with the original content
					metric_raw = metric
				}

				if callback then
					callback(rt)
				else
					routes[#routes+1] = rt
				end
			end
		end

		return routes
	end
end

--- Return information about available network interfaces.
-- @return	Table containing all current interface names and their information
function net.deviceinfo()
	local devs = {}
	for k, v in ipairs(nixio.getifaddrs()) do
		if v.family == "packet" then
			local d = v.data
			d[1] = d.rx_bytes
			d[2] = d.rx_packets
			d[3] = d.rx_errors
			d[4] = d.rx_dropped
			d[5] = 0
			d[6] = 0
			d[7] = 0
			d[8] = d.multicast
			d[9] = d.tx_bytes
			d[10] = d.tx_packets
			d[11] = d.tx_errors
			d[12] = d.tx_dropped
			d[13] = 0
			d[14] = d.collisions
			d[15] = 0
			d[16] = 0
			devs[v.name] = d
		end
	end
	return devs
end

process = {}

function process.info(key)
	local s = {uid = nixio.getuid(), gid = nixio.getgid()}
	return not key and s or s[key]
end

function process.list()
	local data = {}
	local k
	local ps = luci.util.execi("/bin/busybox top -bn1")

	if not ps then
		return
	end

	for line in ps do
		local pid, ppid, user, stat, vsz, mem, cpu, cmd = line:match(
			"^ *(%d+) +(%d+) +(%S.-%S) +([RSDZTW][<NW ][<N ]) +(%d+m?) +(%d+%%) +(%d+%%) +(.+)"
		)

		local idx = tonumber(pid)
		if idx and not cmd:match("top %-bn1") then
			data[idx] = {
				['PID']     = pid,
				['PPID']    = ppid,
				['USER']    = user,
				['STAT']    = stat,
				['VSZ']     = vsz,
				['%MEM']    = mem,
				['%CPU']    = cpu,
				['COMMAND'] = cmd
			}
		end
	end

	return data
end

function process.setgroup(gid)
	return nixio.setgid(gid)
end

function process.setuser(uid)
	return nixio.setuid(uid)
end

process.signal = nixio.kill

local function xclose(fd)
	if fd and fd:fileno() > 2 then
		fd:close()
	end
end

function process.exec(command, stdout, stderr, nowait)
	local out_r, out_w, err_r, err_w
	if stdout then out_r, out_w = nixio.pipe() end
	if stderr then err_r, err_w = nixio.pipe() end

	local pid = nixio.fork()
	if pid == 0 then
		nixio.chdir("/")

		local null = nixio.open("/dev/null", "w+")
		if null then
			nixio.dup(out_w or null, nixio.stdout)
			nixio.dup(err_w or null, nixio.stderr)
			nixio.dup(null, nixio.stdin)
			xclose(out_w)
			xclose(out_r)
			xclose(err_w)
			xclose(err_r)
			xclose(null)
		end

		nixio.exec(unpack(command))
		os.exit(-1)
	end

	local _, pfds, rv = nil, {}, { code = -1, pid = pid }

	xclose(out_w)
	xclose(err_w)

	if out_r then
		pfds[#pfds+1] = {
			fd = out_r,
			cb = type(stdout) == "function" and stdout,
			name = "stdout",
			events = nixio.poll_flags("in", "err", "hup")
		}
	end

	if err_r then
		pfds[#pfds+1] = {
			fd = err_r,
			cb = type(stderr) == "function" and stderr,
			name = "stderr",
			events = nixio.poll_flags("in", "err", "hup")
		}
	end

	while #pfds > 0 do
		local nfds, err = nixio.poll(pfds, -1)
		if not nfds and err ~= nixio.const.EINTR then
			break
		end

		local i
		for i = #pfds, 1, -1 do
			local rfd = pfds[i]
			if rfd.revents > 0 then
				local chunk, err = rfd.fd:read(4096)
				if chunk and #chunk > 0 then
					if rfd.cb then
						rfd.cb(chunk)
					else
						rfd.buf = rfd.buf or {}
						rfd.buf[#rfd.buf + 1] = chunk
					end
				else
					table.remove(pfds, i)
					if rfd.buf then
						rv[rfd.name] = table.concat(rfd.buf, "")
					end
					rfd.fd:close()
				end
			end
		end
	end

	if not nowait then
		_, _, rv.code = nixio.waitpid(pid)
	end

	return rv
end


user = {}

--				{ "uid", "gid", "name", "passwd", "dir", "shell", "gecos" }
user.getuser = nixio.getpw

function user.getpasswd(username)
	local pwe = nixio.getsp and nixio.getsp(username) or nixio.getpw(username)
	local pwh = pwe and (pwe.pwdp or pwe.passwd)
	if not pwh or #pwh < 1 or pwh == "!" or pwh == "x" then
		return nil, pwe
	else
		return pwh, pwe
	end
end

function user.checkpasswd(username, pass)
	local pwh, pwe = user.getpasswd(username)
	if pwe then
		return (pwh == nil or nixio.crypt(pass, pwh) == pwh)
	end
	return false
end

function user.setpasswd(username, password)
	return os.execute("(echo %s; sleep 1; echo %s) | passwd %s >/dev/null 2>&1" %{
		luci.util.shellquote(password),
		luci.util.shellquote(password),
		luci.util.shellquote(username)
	})
end


wifi = {}

function wifi.getiwinfo(ifname)
	local ntm = require "luci.model.network"

	ntm.init()

	local wnet = ntm:get_wifinet(ifname)
	if wnet and wnet.iwinfo then
		return wnet.iwinfo
	end

	local wphy = ntm:get_wifiphy(ifname)
	if wphy and wphy.iwinfo then
		return wphy.iwinfo
	end

	--[[ local wdev = ntm:get_wifidev(ifname)
	if wdev and wdev.iwinfo then
		return wdev.iwinfo
	end ]]

	return { ifname = ifname }
end


init = {}
init.dir = "/etc/init.d/"

function init.names()
	local names = { }
	for name in fs.glob(init.dir.."*") do
		names[#names+1] = fs.basename(name)
	end
	return names
end

function init.index(name)
	if fs.access(init.dir..name) then
		return call("env -i sh -c 'source %s%s enabled; exit ${START:-255}' >/dev/null"
			%{ init.dir, name })
	end
end

local function init_action(action, name)
	if fs.access(init.dir..name) then
		return call("env -i %s%s %s >/dev/null" %{ init.dir, name, action })
	end
end

function init.enabled(name)
	return (init_action("enabled", name) == 0)
end

function init.enable(name)
	return (init_action("enable", name) == 0)
end

function init.disable(name)
	return (init_action("disable", name) == 0)
end

function init.start(name)
	return (init_action("start", name) == 0)
end

function init.stop(name)
	return (init_action("stop", name) == 0)
end

function init.restart(name)
	return (init_action("restart", name) == 0)
end

function init.reload(name)
	return (init_action("reload", name) == 0)
end
