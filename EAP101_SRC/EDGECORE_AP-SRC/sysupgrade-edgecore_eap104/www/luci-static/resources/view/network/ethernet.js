'use strict';'require view';'require dom';'require poll';'require rpc';'require uci';'require form';'require validation';return view.extend({load:function(){return Promise.all([uci.load('ethernet')]);},render:function(){var m,s,o;m=new form.Map('ethernet',_('Ethernet Settings'),'');s=m.section(form.TypedSection,'eth_port','Ethernet Port #0');s.addremove=false;s.anonymous=true;var ether_status=s.option(form.Flag,"status",_("Status"))
ether_status.rmempty=false
ether_status.write=function(section_id,value){uci.set("ethernet",section_id,"status",value)
uci.set("network",section_id,"status",value)
uci.save("network")};var auto_nego=s.option(form.Flag,"auto_nego",_("Auto-negotiation"))
auto_nego.rmempty=false
var link_speed=s.option(form.ListValue,"link_speed",_("Link Speed"))
link_speed.value("10Mbps")
link_speed.value("100Mbps")
link_speed.value("1Gbps")
var full_duplex=s.option(form.Flag,"full_duplex",_("Full Duplex"))
full_duplex.rmempty=false
return m.render();}});