#!/usr/bin/env cgilua.cgi

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<title>Login</title>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="/css/bootstrap.min.css"/>
	<link rel="stylesheet" href="/css/bootstrap-responsive.min.css"/>
	<link rel="stylesheet" href="/css/font-awesome.min.css"/>
	<link rel="stylesheet" href="/css/ace.min.css"/>
	<link rel="stylesheet" href="/css/ace-responsive.min.css"/>
	<link rel="stylesheet" href="/css/acn-default.css"/>
	<link rel="stylesheet" href="/css/brand.css"/>
	<script src="/javascript/jquery-1.9.1.min.js"></script>
	<script src="/javascript/bootstrap.min.js"></script>
	<script src="/javascript/common.js"></script>
</head>

<body class="login-layout" style="background-image: url('/img/background.png');background-repeat: no-repeat;background-attachment: fixed; background-size: cover;">
<div class="container-fluid" id="main-container">
<div id="main-content">
<div id="container">
<h2>Result</h2>

<%
function user_login(username, password, usage, method, reply_msg)
	local handle = {}
	local reply_str = ""
	local auth_cmd = ""
	local sta_ip = tostring(cgilua.servervariable("REMOTE_ADDR"))
	local ap_ip = {}
	local dev_mac = {}
	local ap_mac = {}
	local sta_mac = {}
	local sess_timeout = 0
	local byte_amount = 0
	local byte_amount_4g = 0
	local code = 0
	local byte_quota_error = false
	local reply_cmd = ""

	-- Get STA MAC address
	handle = io.popen("/sbin/arp", "r")
	reply_str = handle:read("*a")
	handle:close()
	dev_mac = reply_str:match(string.format("%%(%s%%) at ([%%:%%x]*)", sta_ip))
	sta_mac = dev_mac and string.upper(dev_mac) or ""

	-- Get AP IP/MAC addrss: TODO: Use ubus instead of this
	handle = io.popen("ifconfig br-wan", "r")
	reply_str = handle:read("*a")
	handle:close()
	if reply_str ~= nil and string.len(reply_str) > 0 then
		dev_mac = reply_str:match("HWaddr ([%:%x]*)")
		ap_mac = dev_mac and string.upper(dev_mac) or ""
		ap_ip = reply_str:match("inet addr:([%.%d]*)")
	else
		handle = io.popen("ifconfig eth0", "r")
		reply_str = handle:read("*a")
		handle:close()
		dev_mac = reply_str:match("HWaddr ([%:%x]*)")
		ap_mac = dev_mac and string.upper(dev_mac) or ""
		ap_ip = reply_str:match("inet addr:([%.%d]*)")
	end

	if (reply_msg ~= "") then
		reply_cmd = ", Reply-Message = \"" .. reply_msg .. "\""
	end
	auth_cmd = "echo 'User-Name= \"" .. username ..
			"\", CHAP-Password = \"" .. password ..
			"\", Framed-IP-Address = \"" .. sta_ip ..
			"\", Calling-Station-Id = \"" .. sta_mac ..
			"\", NAS-IP-Address = \"" .. ap_ip ..
			"\", ZVendor-Auth-Method = \"" .. method .. 
                        "\", Called-Station-Id = \"" .. ap_mac ..
			"\"" .. reply_cmd ..  "' | radclient -x 127.0.0.1:1812 auth 12345678"

	handle = io.popen(auth_cmd, "r")
	reply_str = handle:read("*a")
	handle:close()
	reply_str = string.gsub(reply_str, "-", "_")
	if (string.find(reply_str, "Received Access_Accept") ~= nil) then
		code = "2";
		sess_timeout = reply_str:match("Session_Timeout = ([%d]*)") or 0
		byte_amount = reply_str:match("ZVendor_Byte_Amount = ([%d]*)") or 0
		byte_amount_4g = reply_str:match("ZVendor_Byte_Amount_4GB = ([%d]*)") or 0

		usage[0] = sess_timeout
		if (byte_amount_4g ~= 0) then
			usage[1] = byte_amount + (1024*1024*1024*4*byte_amount_4g)
		else
			usage[1] = byte_amount
		end
	end

	if (string.find(reply_str, "Received Access_Reject") ~= nil) then
		if (reply_str.find(reply_str, "byte_quota_expired") ~= nil) then
			byte_quota_error = true
		end
	end
	usage[2] = byte_quota_error

	return code
end

function user_logout(mac)
	local sta_ip = tostring(cgilua.servervariable("REMOTE_ADDR"))
	local dev_mac = {}
	local sta_mac = {}
	local handle = {}
	local reply_str = {}

	-- Get STA MAC address
	handle = io.popen("/sbin/arp", "r")
	reply_str = handle:read("*a")
	handle:close()
	dev_mac = reply_str:match(string.format("%%(%s%%) at ([%%:%%x]*)", sta_ip))
	sta_mac = dev_mac and string.upper(dev_mac) or ""

	os.execute("/ramfs/bin/cipgwcli logout " .. sta_mac)
end

function parseurl(s)
	local ans = {}
	for k,v in s:gmatch('([^&=?]-)=([^&=?]+)' ) do
		ans[ k ] = v
	end
	return ans
end

local reply_code = 0
local logout = 0
local result = ""
local usage = {0, 0, false}
local uname = ""
local pwd = ""
local method = "UAM"
local reply_msg = ""
local uri = os.getenv("QUERY_STRING")
local item = parseurl(uri)

if (cgilua.POST.logout ~= nil) then
	user_logout(cgilua.POST.mac)
	logout = 1;
else
	if (cgilua.POST.username ~= nil) then
		uname = cgilua.POST.username
	elseif (item['username'] ~= nil) then
		uname = item['username']
	end

	if (cgilua.POST.password ~= nil) then
		pwd = cgilua.POST.password
	end

	if (item['method'] ~= nil) then
		method = item['method']
	end

	if (item['result'] ~= nil) then
		result = item['result']
	end

	if (item['reply'] ~= nil) then
		reply_msg = item['reply']
	end

	if (uname ~= "") then
		result = "Fail"
		reply_code = user_login(uname, pwd, usage, method, reply_msg)
		if (reply_code == "2") then
			result = "Success"
		else
			if usage[2] == true then
				result = result .. "<br>" .. "Traffic quota exceeds the limit. Please renew the data plan."
			end
		end
	end
end
%>
<hr></hr>

<% if (logout == 1) then %>
<blockquote style="background-color: white">
Logout Success
</blockquote>
<% else %>
<blockquote style="background-color: white">
<table class="table">
	<tr>
		<td>Result</td>
		<td style="font-size: 20px; font-weight: bold;"><%= result %></td>
	</tr>
	<tr>
		<td>Username</td>
		<td><%= uname %></td>
	</tr>
	<% if (result == "Success" ) then %>
	<tr>
		<td>Time Quota</td>
		<td><span id="usage_time"></span></td>
	</tr>
	<tr>
		<td>Volume Quota</td>
		<td><span id="volume"></span></td>
	</tr>
	<% end %>
</table>
</blockquote>
<% end %>
<div class="space"></div>

<div class="row-fluid">
<form method="post" name="logout_form" id="logout_form" actoin="test1.lp">
	<input type="hidden" name="logout" id="logout" value="1">
	<input type="hidden" name="mac" id="mac" value="<%= sta_mac %>">
</form>
<% if (logout ~= 1) then %>
	<button onclick="return false;" class="btn btn-info" value="Logout" id="Apply">
		<i class="icon-key"></i> Logout
	</button>
<% end %>
</div>
<script>
$("#Apply").click(function() {
	$("#logout_form").submit();
	return true;
});
$(document).ready(function(){
	var time = "<%= usage[0] %>";
	var volume = "<%= usage[1] %>";
	var time_usage = "";
	var volume_usage = "";

	if (time > 0) {
		day = Math.floor(time/86400);
		if (day > 0)
			time_usage = time_usage + day + " day(s) ";

		time = time%86400;
		if (time > 0) {
			hr = Math.floor(time/3600);
			if (hr > 0) {
				time_usage = time_usage + hr + " hour(s) ";
			}
			time = time%3600;
			if (time > 0) {
				min = Math.floor(time/60);
				if (min > 0)
					time_usage = time_usage + min + " min(s) ";
				time = time%60;
				if (time > 0)
					time_usage = time_usage + time + " sec(s)";
			}
		}
		$("#usage_time").html(time_usage);
	} else {
		$("#usage_time").html("Unlimited");
	}
	if (volume > 0) {
		$("#volume").html("Unlimited");

		volume_usage = "";
		GB = Math.floor(volume/(1024*1024*1024));
		if (GB > 0) {
			volume_usage = volume_usage + GB + " GB ";
		}

		volume = volume % (1024*1024*1024);
		if (volume > 0) {
			MB = Math.floor(volume/(1024*1024));
			if (MB > 0)
				volume_usage = volume_usage + MB + " MB ";
			volume = volume%(1024*1024);
			if (volume > 0) {
				KB = Math.floor(volume/1024);
				if (KB > 0)
					volume_usage = volume_usage + KB + " KB ";
				B = volume%1024;
				if (B > 0)
					volme_usage = volume_usage + B + " Bytes ";
			}
		}
		$("#volume").html(volume_usage);
	} else {
		$("#volume").html("Unlimited");
	}
});
</script>

</div> <!-- id="content" -->

</div> <!-- id="main" -->

</div> <!-- id="container" -->
</body>
</html>
