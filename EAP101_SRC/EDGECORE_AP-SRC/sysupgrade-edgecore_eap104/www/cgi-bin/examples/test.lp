#!/usr/bin/env cgilua.cgi
<%
function user_check()
	local handle = {}
	local reply_str = ""
	local auth_cmd = ""
	local sta_ip = tostring(cgilua.servervariable("REMOTE_ADDR"))
	local ap_ip = {}
	local dev_mac = {}
	local ap_mac = {}
	local sta_mac = {}
	local username = {}
	local code = 0

	-- Get STA MAC address
	handle = io.popen("/sbin/arp", "r")
	reply_str = handle:read("*a")
	handle:close()
	dev_mac = reply_str:match(string.format("%%(%s%%) at ([%%:%%x]*)", sta_ip))
	sta_mac = dev_mac and string.upper(dev_mac) or ""
	username = string.gsub(sta_mac, ":", "-")

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

	auth_cmd = "echo 'User-Name= \"" .. username .. 
		   "\", CHAP-Password = \"" .. username .. 
		   "\", Framed-IP-Address = \"" .. sta_ip .. 
		   "\", Calling-Station-Id = \"" .. sta_mac .. 
		   "\", NAS-IP-Address = \"" .. ap_ip .. 
		   "\", ZVendor-Auth-Method = \"roam\", " .. 
		   "Called-Station-Id = \"" .. ap_mac .. 
		   "\"' | radclient -x 127.0.0.1:1812 auth 12345678"

	handle = io.popen(auth_cmd, "r")
	reply_str = handle:read("*a")
	handle:close()
	reply_str = string.gsub(reply_str, "-", "_")
	if (string.find(reply_str, "Received Access_Accept") ~= nil) then
		code = "2";
	end

	return code

end

local reply_code = 0
local returnUrl = {}
local dec_cmd = {}
local handle = {}

reply_code = user_check()
if ( reply_code == "2") then
	dec_cmd = "/ramfs/bin/dec " .. cgilua.GET.ReturnUrl
	handle = io.popen(dec_cmd, "r")
	returnUrl = handle:read("*a")
	handle:close()
	if ( returnUrl ~= nil and returnUrl ~= "" ) then
		cgilua.redirect = returnUrl
	end
else
%>


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

<form method="post" name="login" action="test1.lp">
<div class="container-fluid" id="main-container">
    <div id="main-content">
        <div class="row-fluid">
            <div class="span12">
                <div class="container">

                   <div class="row-fluid">
                        <div class="center">
                            <h1 class="header">
                                 Welcome
                            </h1>
                        </div>
                    </div>
                    <div class="space-6">
					</div>

                    <div class="row-fluid center">
                    <div class="position-relative">
                    <div id="login-box" class="visible no-border">
                        <div>
                            <div>
                                    <fieldset>
                                        <label>
                                            <span class="block">
                                                <input type="text" class="form-text" name="username" value="" placeholder="Username" autofocus="focus" />
                                                <i class="icon-user icon-user-right"></i>
                                            </span>
                                        </label>
                                        <label>
                                            <span class="block">
                                                <input type="password" class="form-texts" placeholder="Password" name="password" />
                                                <i class="icon-lock icon-lock-right"></i>
                                            </span>
                                        </label>
                                        <div class="space"></div>
                                        <div class="row-fluid">
                                            <button onclick="return false;" class="btn btn-info" value="Login" id="Apply">
                                                <i class="icon-key"></i> Enter
                                            </button>
                                        </div>
                                    </fieldset>
                            </div>
                        </div>
                    </div>
                    </div>
                    </div>

                </div>
            </div>
        </div>
    </div>
</div>
</form>
<script>
$( "#Apply" ).click(function() {
  document.login.submit();
  return true;
});
</script>
</body>
</html>
<%
end
%>
