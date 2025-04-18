
function network_prefix(network_short){if(network_short.startsWith('custom_')){return'custom LAN network alias';}
if(network_short=='lan'){return'default LAN network alias';}
if(network_short=='guest'){return'default guest LAN network alias';}
return network_short;}
function getIpAliasAddressList(){var _ipAliasArray=new Array();_ipAliasArray['Name']=new Array();_ipAliasArray['IP']=new Array();_ipAliasArray['Netmask']=new Array();_ipAliasArray['friendly']=new Array();$('.cbi-value-field input').each(function(input){var data_lan_value=$(this).closest('tr').attr('data-lan');if(this.id.indexOf('ipaddr')>=0&&this.value!=''){var tr_css_display=($(this).closest('tr').css('display')!='none');if(tr_css_display){_ipAliasArray['IP'].push(this.value);_ipAliasArray['Name'].push(data_lan_value);_ipAliasArray['friendly'].push(network_prefix(data_lan_value));}}
if(this.id.indexOf('netmask')>=0&&this.value!=''){var tr_css_display=($(this).closest('tr').css('display')!='none');if(tr_css_display){_ipAliasArray['Netmask'].push(this.value);}}});return _ipAliasArray;}
function GetUnique(inputArray){var outputArray=[];for(var i=0;i<inputArray.length;i++){if((jQuery.inArray(inputArray[i],outputArray))==-1){outputArray.push(inputArray[i]);}}
return outputArray;}
function validateNetwork(ip_id,netmask_id){var ip_value=$(ip_id).val();var netmask_value=$(netmask_id).val();var res_ip=true,res_netmask=true;if(!is_ip(ip_value)){set_err_msg($(ip_id),true,_('Not a valid IPv4 address!'));res_ip=false;}
if(!cbi_validators.netmask(netmask_value)){set_err_msg($(netmask_id),true,_('Not a valid netmask!'));res_netmask=false;}
if(res_ip&&res_netmask){if(is_broadcast(ip_value,netmask_value)){set_err_msg($(ip_id),true,_('IP address is a broadcast IP.'));return false;}
if(is_net(ip_value,netmask_value)){set_err_msg($(ip_id),true,_('Not a valid network.'));return false;}}
return(res_ip&&res_netmask);}
function get_own_lan(ctrl){var network=$(ctrl).data('lan');if(network===null||network===''||network===undefined||network==='%CUSTOM%'){return null;}
return network;}
function get_lan(ctrl){var network=$(ctrl).closest('.lan_section').data('lan');if(network===null||network===''||network===undefined||network==='%CUSTOM%'){return null;}
return network;}
function validate_dhcp_fields(){var res=true;$('.dhcp_button').each(function(){var network=get_lan(this);res=res&&validate_dhcp(network);});return res;}
function validate_dns_list($customDns){if(val==' '){return true;}
var res=true;var val=$customDns.val();var preparedVal=val.trim().replace(/\s+,/g,'\n').replace(/;/g,'\n').replace(/,/g,'\n');if(preparedVal!==''){var list=preparedVal.split('\n');if(list.length>3){res=false;}
list.forEach(ip_addr=>{res=is_ip(ip_addr)&&res;});$customDns.val(preparedVal);}
if(res){set_err_msg($customDns,false);}else{set_err_msg($customDns,true,_('Please enter a list of no more than 3 IPs of DNS servers, separated by space, comma, semicolon or newline.'));}
return res;}
function validate_dhcp(param){var res=true;var network=param;if(typeof network!=='string'){network=get_lan(this);}
if(network===null){return true;}
var $mask=$('#cbid\\.network\\.'+network+'\\.netmask');var $start=$('#cbid\\.network\\.'+network+'\\.dhcp_start');var $end=$('#cbid\\.network\\.'+network+'\\.dhcp_max');var $customDns=$('#cbid\\.network\\.'+network+'\\.dhcp_dns');if(!$customDns.val()){$customDns.val(' ');}
var mask_val=$mask.val().split('.');var sumofbits=0;for(var i=0;i<mask_val.length;i++){var tmpvar=parseInt(mask_val[i],10);var bitsfromleft=h_countbitsfromleft(tmpvar);if(isNaN(bitsfromleft)){set_err_msg($mask,true,_('Value not allowed!'));return false;}
sumofbits+=bitsfromleft;}
var ip_max=Math.pow(2,(32-sumofbits))-2;var ip_end=ip_max-$start.val()+1;res=check_range($start,1,ip_max)&&res;res=check_range($end,1,ip_end)&&res;res=validate_dns_list($customDns)&&res;return res;}
function check_range($io_id,start_num,end_num){var res=true;var io_val=$io_id.val();if(is_in_range(io_val,start_num,end_num)){if(end_num>0){set_err_msg($io_id,false,_('Allowed values are integers between %d and %d, inclusive.').format(start_num,end_num));}else{set_err_msg($io_id,false,_('Value not allowed!'));}}else{if(end_num>0){if(end_num===1){set_err_msg($io_id,true,_('Allowed values is 1.'));}else{set_err_msg($io_id,true,_('Allowed values are integers between %d and %d, inclusive.').format(start_num,end_num));}}else{set_err_msg($io_id,true,_('Value not allowed!'));}
res=false;}
return res;}
function validateCustomName(){var res=true;$('.widget-header').each(function(){var network=get_own_lan(this);if(network===null||network.indexOf('custom_')<0){return;}
var custom_title_id=document.getElementById('cbid.network.'+network+'.title');var custom_title_val=$(custom_title_id).val();var customTitleIdx=network.match(/\d+/g);var title_list=[];$('.widget-header').each(function(){var network=get_own_lan(this);if(network===null||network.indexOf('custom_')<0){return;}
var current_custom_title_id=document.getElementById('cbid.network.'+network+'.title');var current_custom_title_val=$(current_custom_title_id).val();if(custom_title_id.id!==current_custom_title_id.id){var currentCustomIdx=network.match(/\d+/g);title_list[currentCustomIdx]=current_custom_title_val;}});title_list[customTitleIdx]=custom_title_val;if(checkArrayRepeat(title_list)){res=false;}
title_list=[];});return res;}
function checkArrayRepeat(array){var hashAll={},hashIdx={};var flag=false;var i=0;for(i in array){if(hashIdx[array[i]]===undefined){hashIdx[array[i]]=new Array();}
hashIdx[array[i]].push(i);}
i=0;for(i in array){var titleId='#cbid\\.network\\.custom_'+i+'\\.title';$(titleId).removeClass('tooltip-error');$(titleId).attr('data-original-title','');if(array[i]===''){$(titleId).addClass('tooltip-error');set_err_msg($(titleId),true,_('This field is required.'));flag=true;}else{if(hashAll[array[i]]){for(var j=0;j<hashIdx[array[i]].length;j++){var titleIdDuplicated='#cbid\\.network\\.custom_'+hashIdx[array[i]][j]+'\\.title';$(titleIdDuplicated).addClass('tooltip-error');set_err_msg($(titleIdDuplicated),true,_('Duplicated custom LAN name.'));}
flag=true;}
hashAll[array[i]]=true;}}
return flag;}
function getSectionId(val){var idValue=val;var tmpArr='';if(idValue!==undefined){tmpArr=idValue.split('-');}
if(tmpArr===null||tmpArr.length===0||tmpArr===undefined){return null;}
return tmpArr[2];}
function validate_ip_addrs(){var res=true;$('#lan_list > .lan_section').each(function(){var network=get_own_lan(this);var ip_id=document.getElementById('cbid.network.'+network+'.ipaddr');var netmask_id=document.getElementById('cbid.network.'+network+'.netmask');var ip_value=$(ip_id).val();var netmask_value=$(netmask_id).val();if(!ipdata.hasOwnProperty(network)){ipdata[network]={};ipdata[network].friendly='other LAN';}
if((ipdata[network].ip!==ip_value||ipdata[network].nm!==netmask_value)){ipdata[network].ip=ip_value;ipdata[network].nm=netmask_value;}
set_err_msg(ip_id,false,'Not a valid IPv4 address!');});$('#lan_list > .lan_section').each(function(){var network=get_own_lan(this);var ip_id=document.getElementById('cbid.network.'+network+'.ipaddr');var netmask_id=document.getElementById('cbid.network.'+network+'.netmask');var ip_value=$(ip_id).val();var netmask_value=$(netmask_id).val();var tmp=validateNetwork(ip_id,netmask_id);if(!tmp){res=false;return;}
for(var ipentry in ipdata){if(ipdata.hasOwnProperty(ipentry)){if(!ipentry.startsWith(network)&&ipentry.indexOf('-alias')<0){var _ipentry=ipdata[ipentry];if(ip_value===_ipentry.ip){set_err_msg($(ip_id),true,_('Your Internet IP address is the same as the %s IP address!').format(_ipentry.friendly));res=false;}
if(is_in_netmask(_ipentry.ip,_ipentry.nm,ip_value)){set_err_msg($(ip_id),true,_('Your Internet IP address falls in the same subnet as the %s network IP address.').format(_ipentry.friendly));res=false;}}}}
var ipAliasArray=getIpAliasAddressList();for(var i=0;i<ipAliasArray['IP'].length;i++){if(!ipAliasArray['Name'][i].startsWith(network)){if(ip_value===ipAliasArray['IP'][i]){set_err_msg($(ip_id),true,_('Your Internet IP address is the same as the %s IP address!').format(ipAliasArray['friendly'][i]));res=false;}
if(is_in_netmask(ipAliasArray['IP'][i],ipAliasArray['Netmask'][i],ip_value)){set_err_msg($(ip_id),true,_('Your Internet IP address falls in the same subnet as the %s network IP address.').format(ipAliasArray['friendly'][i]));res=false;}}}});return res;}
function validateIpAliases(){var res=true;var ip_aliases_waring=new Array();var ip_aliases_inf_list=new Array();$('.cbi-section-table-row').each(function(){var this_res=true;var network=get_own_lan(this);if(network==null){return;}
ip_aliases_inf_list.push(network);var sectionId=getSectionId(this.id);if(sectionId===null){return;}
var is_deleted=($('#acn\\.del\\.network\\.'+sectionId).val()==='1');var ip_id='#cbid\\.network\\.'+sectionId+'\\.ipaddr';var netmask_id='#cbid\\.network\\.'+sectionId+'\\.netmask';clear_validate_error(ip_id);clear_validate_error(netmask_id);if(!is_deleted){var ip_value=$(ip_id).val();var netmask_value=$(netmask_id).val();var res_ip=true,res_netmask=true;var _alias_index=$(this).index();var alias_short=network+'-alias_'+(+_alias_index+1);if(ipdata.hasOwnProperty(alias_short)&&(ipdata[alias_short].ip!==ip_value||ipdata[alias_short].nm!==netmask_value)){ipdata[alias_short].ip=ip_value;ipdata[alias_short].nm=netmask_value;}
clear_validate_error(ip_id);clear_validate_error(netmask_id);if(!is_ip(ip_value)){set_err_msg($(ip_id),true,_('Not a valid IPv4 address!'));res_ip=false;this_res=false;}
if(!cbi_validators.netmask(netmask_value)){set_err_msg($(netmask_id),true,_('Not a valid netmask!'));res_netmask=false;this_res=false;}
if(res_ip&&res_netmask){if(is_broadcast(ip_value,netmask_value)){set_err_msg($(ip_id),true,_('IP address is a broadcast IP.'));this_res=false;}
if(is_net(ip_value,netmask_value)){set_err_msg($(ip_id),true,_('Not a valid network.'));this_res=false;}
for(var ipentry in ipdata){if(ipdata.hasOwnProperty(ipentry)){if(!ipentry.startsWith(network)&&ipentry.indexOf('-alias')<0){var _ipentry=ipdata[ipentry];if(ip_value===_ipentry.ip){set_err_msg($(ip_id),true,_('Your Internet IP address is the same as the %s IP address!').format(_ipentry.friendly));res_ip=false;this_res=false;}
if(is_in_netmask(_ipentry.ip,_ipentry.nm,ip_value)){set_err_msg($(ip_id),true,_('Your Internet IP address falls in the same subnet as the %s network IP address.').format(_ipentry.friendly));res_ip=false;this_res=false;}}}}}}
if(!this_res){ip_aliases_waring.push(network);}
res=res&&this_res;});ip_aliases_waring=GetUnique(ip_aliases_waring);ip_aliases_inf_list=GetUnique(ip_aliases_inf_list);for(var i=0;i<ip_aliases_inf_list.length;i++){if($.inArray(ip_aliases_inf_list[i],ip_aliases_waring)>=0){$('#open_ip_aliases_'+ip_aliases_inf_list[i]).addClass('ip_aliases_warning');}else{$('#open_ip_aliases_'+ip_aliases_inf_list[i]).removeClass('ip_aliases_warning');}}
return res;}
function add_validation_handlers(){var network=get_own_lan(this);if(network===null){return;}
initIpAliasBadgeCount(network);cbi_validate_field('cbid.network.'+network+'.netmask',false,'netmask');cbi_validate_field('cbid.network.'+network+'.mtu',false,'range(1400,1500)');var $dhcp=$('#cbid\\.network\\.'+network+'\\.dhcp');var $ip_addr=$('#cbid\\.network\\.'+network+'\\.ipaddr');var $netmask=$('#cbid\\.network\\.'+network+'\\.netmask');var $dhcp_end=$('#cbid\\.network\\.'+network+'\\.dhcp_max');var $dhcp_start=$('#cbid\\.network\\.'+network+'\\.dhcp_start');var $customDns=$('#cbid\\.network\\.'+network+'\\.dhcp_dns');$ip_addr.change(function(){validate_ip_addrs();validateIpAliases();});$netmask.change(function(){validate_ip_addrs();validate_dhcp();validateIpAliases();});$dhcp.change(validate_dhcp);$dhcp_start.change(validate_dhcp);$dhcp_end.change(validate_dhcp);$customDns.change(validate_dhcp);var $title=$('#cbid\\.network\\.'+network+'\\.title');$title.change(validateCustomName);$ip_addr.change();$netmask.change();$dhcp_start.change();$dhcp_end.change();$customDns.change();}
function add_validation_ipaliases_handlers(val){var sectionId=getSectionId(val);if(sectionId===null){return;}
var $ip_addr=$('#cbid\\.network\\.'+sectionId+'\\.ipaddr');var $netmask=$('#cbid\\.network\\.'+sectionId+'\\.netmask');$ip_addr.change(function(){validateIpAliases();validate_ip_addrs();});$netmask.change(function(){validateIpAliases();validate_ip_addrs();});$ip_addr.change();$netmask.change();}
function h_countbitsfromleft(num){if(num===255){return(8);}
var i=0;var bitpat=0xff00;while(i<8){if(num===(bitpat&0xff)){return(i);}
bitpat=bitpat>>1;i++;}
return(Number.NaN);}