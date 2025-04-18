'use strict';'require baseclass';'require rpc';'require network';'require uci';return baseclass.extend({title:'',load:function(){return Promise.all([uci.load('network'),uci.load('wireless'),uci.load('dhcp')]);},render_lan:function(){var networkSections=uci.sections('network'),wirelessSections=uci.sections('wireless'),dhcpSections=uci.sections('dhcp'),net_row=[],wifi_lan=[],lan_member=[],lan_dhcp=null,wan_dhcp_ignore=0;for(var j=0;j<wirelessSections.length;j++){var wirelessSection=wirelessSections[j],radio_device=wirelessSection.device,wifi_type=wirelessSection['.type'];if(wifi_type=='wifi-device')
var wifi_device_disabled=wirelessSection.disabled;if(radio_device=='radio0')
var radio_freq='5 GHz';else if(radio_device=='radio1')
var radio_freq='2.4 Ghz';if(wirelessSection.network=='lan'&&wirelessSection.disabled!='1'&&wifi_device_disabled!='1'){var lan_member_info=_('%s: %s'.format(radio_freq,wirelessSection.ssid));wifi_lan.push([lan_member_info]);}}
for(var m=0;m<dhcpSections.length;m++){var dhcpSection=dhcpSections[m],dhcp_ifname=dhcpSection['.name'];if(dhcp_ifname=='lan'){if(dhcpSection.ignore=='1')
lan_dhcp='Disabled';else
lan_dhcp='Enabled';}
if(dhcp_ifname=='wan'){if(dhcpSection.ignore=='1')
wan_dhcp_ignore=1;}}
for(var i=0;i<networkSections.length;i++){var networkSection=networkSections[i],network_name=networkSection['.name'];if(network_name=='lan'){var lan_ipaddr=networkSection.ipaddr,lan_netmask=networkSection.netmask,lan_proto=null;if(networkSection.proto=='static')
lan_proto='Static IP';else
lan_proto='DHCP IP';if(networkSection.ifname!=undefined){lan_member.push(E('span',{},[E('span',{'style':'text-transform:uppercase'},_('%s '.format(networkSection.ifname))),E('br')]));}
for(var k=0;k<wifi_lan.length;k++){lan_member.push(E('span',{},[E('span',_('%s '.format(wifi_lan[k]))),E('br')]));}
net_row.push([_('Default Local Network'),E('span',{},[E('span',_('%s (%s)'.format(lan_ipaddr,lan_proto))),E('br'),E('span',_('Netmask: %s'.format(lan_netmask)))]),lan_dhcp,lan_member]);}}
for(var l=0;l<networkSections.length;l++){var wifi_vlan=[],vlan_member=[],vlan_active_net=[],vlan_dhcp=null;var networkSection=networkSections[l],network_name=networkSection['.name'];if(network_name.includes("vlan")){var vlan_ifname=[],vlan_port=[],vlan_tag_id=null;if(networkSection.enabled=='1'||networkSection.vlan_net=='1'){if(!wan_dhcp_ignore&&networkSection.proto=='dhcp')
vlan_dhcp='Enabled';else
vlan_dhcp='Disabled';vlan_ifname=networkSection.ifname.split(' ');for(var n=0;n<vlan_ifname.length;n++){if(vlan_ifname[n].includes("eth")){vlan_port.push(vlan_ifname[n]);}
if(vlan_ifname[n].match(/eth(\d).(\d+)/)){vlan_tag_id=vlan_ifname[n].split(/(\.)/)[2];}}
var vlan_port_list=vlan_port.join(' ');for(var o=0;o<wirelessSections.length;o++){var wirelessSection=wirelessSections[o],radio_device=wirelessSection.device,wifi_type=wirelessSection['.type'];if(wifi_type=='wifi-device')
var wifi_device_disabled=wirelessSection.disabled;if(radio_device=='radio0')
var radio_freq='5 GHz';else if(radio_device=='radio1')
var radio_freq='2.4 Ghz';if(wirelessSection.network!=undefined){if(wirelessSection.network.includes(network_name)&&wirelessSection.disabled!='1'&&wifi_device_disabled!='1'){var vlan_member_info=_('%s: %s'.format(radio_freq,wirelessSection.ssid));wifi_vlan.push([vlan_member_info]);var vlan_active=wirelessSection.network;vlan_active_net.push(vlan_active);}}}
for(var p=0;p<wifi_vlan.length;p++){if(vlan_active_net[p]==network_name){vlan_member.push(E('span',{},[E('span',_('%s '.format(wifi_vlan[p]))),E('br')]));}}
net_row.push([_('VLAN-Tagged Network (VLAN ID #%d)'.format(vlan_tag_id)),E('span',{},[E('span',{'style':'text-transform:uppercase'},_('Ports: %s '.format(vlan_port_list)))]),vlan_dhcp,vlan_member]);}}}
var table=E('div',{'class':'table'},[E('div',{'class':'tr table-titles'},[E('div',{'class':'th'},_('Name')),E('div',{'class':'th'},_('Network Info')),E('div',{'class':'th'},_('DHCP Server')),E('div',{'class':'th'},_('Members'))])]);cbi_update_table(table,net_row,E('em',_('There are no active local networks')));return E([E('h3',_('Local Networks')),table]);},render:function(){return this.render_lan();}});