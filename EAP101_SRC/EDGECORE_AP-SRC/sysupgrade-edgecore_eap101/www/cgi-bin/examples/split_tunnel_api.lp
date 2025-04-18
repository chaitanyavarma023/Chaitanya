#!/usr/bin/env cgilua.cgi
<%
  local cmd = ""
  local act = cgilua.POST.act
  if (act == "login") then
    cmd = "/usr/sbin/split_tunnel_user.sh login " .. cgilua.POST.mac .. " " .. cgilua.POST.cui .. " " .. cgilua.POST.idle
  elseif (act == "set") then
    cmd = "/etc/rc.d/rc.split_tunnel set_dnat_mac " .. cgilua.POST.dnat_mac
  elseif (act == "add_logout_ip") then
    cmd = "echo " .. cgilua.POST.ips .. " >> /tmp/add_logout_ip"
  elseif (act == "set_logout_ip") then
    cmd = "/usr/sbin/split_tunnel_user.sh logout_ip_list"
  elseif (act == "add_walled_garden") then
    cmd = "echo " .. cgilua.POST.items .. " >> /tmp/add_walled_garden"
  elseif (act == "set_walled_garden") then
    cmd = "/usr/sbin/split_tunnel_user.sh walled_garden"
  elseif (act == "qos_add") then
    cmd = "/sbin/QosUserCli add " .. cgilua.POST.mac .. " " .. cgilua.POST.reqDL .. " " .. cgilua.POST.maxDL .. " " .. cgilua.POST.reqUL .. " " .. cgilua.POST.maxUL
  elseif (act == "qos_del") then
    cmd = "/sbin/QosUserCli del " .. cgilua.POST.mac
  else
    cmd = "/usr/sbin/split_tunnel_user.sh " .. act .. " " .. cgilua.POST.mac .. " " .. cgilua.POST.kick
  end
  os.execute(cmd)

%>
