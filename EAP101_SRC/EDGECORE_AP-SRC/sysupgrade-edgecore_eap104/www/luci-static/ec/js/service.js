
var pre_ibeacon_id='#cbid\\.ibeacon\\.ibeacon\\.';function validate_form(){var res=validate_port()&&validate_ntp()&&validate_ibeacon_uuid()&&validate_community();if(!res){cbi_show_form_error();}
return res;}
function validate_community(){var ro_community=document.getElementById('cbid.snmpd.ro_community.name');var rw_community=document.getElementById('cbid.snmpd.rw_community.name');var ro_community6=document.getElementById('cbid.snmpd.ro_community6.name');var rw_community6=document.getElementById('cbid.snmpd.rw_community6.name');var error_detail=_('Read and write community should not be the same.');var error_str=_('Shouldn\'t include space, \' or \".');const isAscii=str=>/^[\x00-\x7F]+$/.test(str);if(ro_community.value.indexOf(' ')>=0||ro_community.value.indexOf('"')>=0||ro_community.value.indexOf("'")>=0||!isAscii(ro_community.value)){set_err_msg(ro_community,true,error_str);return false;}
if(rw_community.value.indexOf(' ')>=0||rw_community.value.indexOf('"')>=0||rw_community.value.indexOf("'")>=0||!isAscii(rw_community.value)){set_err_msg(rw_community,true,error_str);return false;}
if(ro_community6.value.indexOf(' ')>=0||ro_community6.value.indexOf('"')>=0||ro_community6.value.indexOf("'")>=0||!isAscii(ro_community6.value)){set_err_msg(ro_community6,true,error_str);return false;}
if(rw_community6.value.indexOf(' ')>=0||rw_community6.value.indexOf('"')>=0||rw_community6.value.indexOf("'")>=0||!isAscii(rw_community6.value)){set_err_msg(rw_community6,true,error_str);return false;}
if(ro_community.value.trim()==rw_community.value.trim()){set_err_msg(ro_community,true,error_detail);set_err_msg(rw_community,true,error_detail);return false;}
if(ro_community6.value.trim()==rw_community6.value.trim()){set_err_msg(ro_community6,true,error_detail);set_err_msg(rw_community6,true,error_detail);return false;}
return true;}
function validate_ntp(){if(document.getElementsByClassName('cbi-input-invalid').length){return false;}else{return true}}
function validate_port(){var res=true;var err_msg=new Array(false,false,false,false,false);var http_port_id=document.getElementById('cbid.uhttpd.main.listen_http');var https_port_id=document.getElementById('cbid.uhttpd.main.listen_https');var http_port_val=$(http_port_id).val();var https_port_val=$(https_port_id).val();set_err_msg(http_port_id,false);set_err_msg(https_port_id,false);var telnet_port_obj=document.getElementById(telnet_port_id);var ssh_port_obj=document.getElementById(ssh_port_id);var telnet_port_value='',ssh_port_value='';var error_detail=_('Port is duplicated.');if(telnet_port_obj){telnet_port_value=$(telnet_port_obj).val();set_err_msg(telnet_port_obj,false);if(!is_in_range(telnet_port_value,0,65535)){res=false;err_msg[0]=true;}}
if(ssh_port_obj){ssh_port_value=$(ssh_port_obj).val();set_err_msg(ssh_port_obj,false);if(!is_in_range(ssh_port_value,0,65535)){res=false;err_msg[1]=true;}}
if(!is_in_range(http_port_val,1025,65534)){if(http_port_val!=80){res=false;err_msg[2]=true;}}
if(!is_in_range(https_port_val,1025,65534)){if(https_port_val!=443){res=false;err_msg[3]=true;}}
if(http_port_val!=''||https_port_val!=''||telnet_port_obj||ssh_port_obj){if(http_port_val==https_port_val){res=false;err_msg[4]=true;}
if(http_port_val==telnet_port_value){res=false;err_msg[5]=true;}
if(http_port_val==ssh_port_value){res=false;err_msg[6]=true;}
if(https_port_val==telnet_port_value){res=false;err_msg[7]=true;}
if(https_port_val==ssh_port_value){res=false;err_msg[8]=true;}
if(telnet_port_value!=''&&ssh_port_value!=''&&telnet_port_value==ssh_port_value){res=false;err_msg[9]=true;}}
if(err_msg[4]){set_err_msg(https_port_id,true,error_detail);set_err_msg(http_port_id,true,error_detail);}
if(err_msg[5]){set_err_msg(telnet_port_obj,true,error_detail);set_err_msg(http_port_id,true,error_detail);}
if(err_msg[6]){set_err_msg(ssh_port_obj,true,error_detail);set_err_msg(http_port_id,true,error_detail);}
if(err_msg[7]){set_err_msg(telnet_port_obj,true,error_detail);set_err_msg(https_port_id,true,error_detail);}
if(err_msg[8]){set_err_msg(ssh_port_obj,true,error_detail);set_err_msg(https_port_id,true,error_detail);}
if(err_msg[9]){set_err_msg(ssh_port_obj,true,error_detail);set_err_msg(telnet_port_obj,true,error_detail);}
if(err_msg[0]){set_err_msg(telnet_port_obj,true,_('Not a valid port range! Allowed values are integers between %d and %d, inclusive.').format(0,65535));}
if(err_msg[1]){set_err_msg(ssh_port_obj,true,_('Not a valid port range! Allowed values are integers between %d and %d, inclusive.').format(0,65535));}
if(err_msg[2]){set_err_msg(http_port_id,true,_('Not a valid port range! Allowed values are %d or integers between %d and %d, inclusive.').format(80,1025,65534));}
if(err_msg[3]){set_err_msg(https_port_id,true,_('Not a valid port range! Allowed values are %d or integers between %d and %d, inclusive.').format(443,1025,65534));}
return res;}
function validate_ibeacon_uuid(){var res=true;var err_msg=new Array(false,false,false,false,false);var ibeacon_enabled_obj=$(pre_ibeacon_id+'enabled');var uuid_id_1=pre_ibeacon_id+'uuid';var uuid_id_2=pre_ibeacon_id+'_uuid_2';var uuid_id_3=pre_ibeacon_id+'_uuid_3';var uuid_id_4=pre_ibeacon_id+'_uuid_4';var uuid_id_5=pre_ibeacon_id+'_uuid_5';var re=/^[a-fA-F0-9]+$/;clear_validate_error(uuid_id_1);clear_validate_error(uuid_id_2);clear_validate_error(uuid_id_3);clear_validate_error(uuid_id_4);clear_validate_error(uuid_id_5);if(!ibeacon_enabled_obj.is(':checked')){return res;}
if($(uuid_id_1).val().length!=8||!re.test($(uuid_id_1).val())){res=false;set_err_msg($(uuid_id_1),true,_('Value must be %d Hex characters.').format(8));}
if($(uuid_id_2).val().length!=4||!re.test($(uuid_id_2).val())){res=false;set_err_msg($(uuid_id_2),true,_('Value must be %d Hex characters.').format(4));}
if($(uuid_id_3).val().length!=4||!re.test($(uuid_id_3).val())){res=false;set_err_msg($(uuid_id_3),true,_('Value must be %d Hex characters.').format(4));}
if($(uuid_id_4).val().length!=4||!re.test($(uuid_id_4).val())){res=false;set_err_msg($(uuid_id_4),true,_('Value must be %d Hex characters.').format(4));}
if($(uuid_id_5).val().length!=12||!re.test($(uuid_id_5).val())){res=false;set_err_msg($(uuid_id_5),true,_('Value must be %d Hex characters.').format(12));}
return res;}
function add_validation_handlers(){$('.cbi-section-node input').each(function(input){if(this.id.indexOf('dropbear')>=0&&this.id.indexOf('enable')>=0){ssh_enable_id=this.id;}
if(this.id.indexOf('dropbear')>=0&&this.id.indexOf('Port')>=0){ssh_port_id=this.id;}
if(this.id.indexOf('telnetd')>=0&&this.id.indexOf('enable')>=0){telnet_enable_id=this.id;}
if(this.id.indexOf('telnetd')>=0&&this.id.indexOf('Port')>=0){telnet_port_id=this.id;}});var $http_port=$('#cbid\\.uhttpd\\.main\\.listen_http');var $https_port=$('#cbid\\.uhttpd\\.main\\.listen_https');$http_port.change(validate_port);$https_port.change(validate_port);$http_port.change();$https_port.change();if(ssh_port_id!=''){var $ssh_port=$('#'+ssh_port_id.replace(/\./g,'\\.'));$ssh_port.change(validate_port);$ssh_port.change();}
if(telnet_port_id!=''){var $telent_port=$('#'+telnet_port_id.replace(/\./g,'\\.'));$telent_port.change(validate_port);$telent_port.change();}
var uuid_id_1=$(pre_ibeacon_id+'uuid');var uuid_id_2=$(pre_ibeacon_id+'_uuid_2');var uuid_id_3=$(pre_ibeacon_id+'_uuid_3');var uuid_id_4=$(pre_ibeacon_id+'_uuid_4');var uuid_id_5=$(pre_ibeacon_id+'_uuid_5');uuid_id_1.change(validate_ibeacon_uuid);uuid_id_2.change(validate_ibeacon_uuid);uuid_id_3.change(validate_ibeacon_uuid);uuid_id_4.change(validate_ibeacon_uuid);uuid_id_5.change(validate_ibeacon_uuid);uuid_id_1.change();uuid_id_2.change();uuid_id_3.change();uuid_id_4.change();uuid_id_5.change();}
function fill_uuid(_checked){if(_checked){var uuid_id=$(pre_ibeacon_id+'uuid');var uuid2_id=$(pre_ibeacon_id+'_uuid_2');var uuid3_id=$(pre_ibeacon_id+'_uuid_3');var uuid4_id=$(pre_ibeacon_id+'_uuid_4');var uuid5_id=$(pre_ibeacon_id+'_uuid_5');var uuid_val=uuid_id.val();if(uuid_val.length==32){uuid_id.val(uuid_val.substr(0,8));uuid2_id.val(uuid_val.substr(8,4));uuid3_id.val(uuid_val.substr(12,4));uuid4_id.val(uuid_val.substr(16,4));uuid5_id.val(uuid_val.substr(20));}}}
function snmpd_enable_click(_val){if(_val){$('#cbi-snmpd-snmp_trap').removeClass('hide');}else{$('#cbi-snmpd-snmp_trap').addClass('hide');}}
var ssh_enable_id='';var ssh_port_id='';var telnet_enable_id='';var telnet_port_id='';function before_submit(){if(!validate_form()||!before_submit_snmpv3()){cbi_show_form_error();return false;}else{return true;}}
function ble_scan(){$('#spinner_scan').addClass('icon-spin');$('#spinner_scan_container').show();$('#ble_scan_results').html('');$.get(ble_scan_url,null,function(data){if(data.search('<form method="post" name="login"')!=-1){top.location.href=ssid_url;return;}
$('#ble_scan_results').html(data);$('#spinner_scan').removeClass('icon-spin');$('#spinner_scan_container').hide();});}
window.onload=function(){var ibeacon_enabled_obj=$(pre_ibeacon_id+'enabled');fill_uuid(ibeacon_enabled_obj.is(':checked'));ibeacon_enabled_obj.click(function(){fill_uuid(this.checked);add_validation_handlers();});$('#cbi').submit(function(){return before_submit();});var snmpd_section_num='';$('.cbi-section-node input').each(function(input){if(this.id.indexOf('snmpd')>=0&&this.id.indexOf('enabled')>=0){var id_arr=this.id.split('.');snmpd_section_num=id_arr[2];var snmpd_enabled_id='#cbid\\.snmpd\\.'+snmpd_section_num+'\\.enabled';$(snmpd_enabled_id).change(function(){snmpd_enable_click($(snmpd_enabled_id).is(':checked'));});}});add_validation_handlers();var $telnet_enable_obj=$('#'+telnet_enable_id.replace(/\./g,'\\.'));var $ssh_enable_obj=$('#'+ssh_enable_id.replace(/\./g,'\\.'));$telnet_enable_obj.click(function(){add_validation_handlers();});$ssh_enable_obj.click(function(){add_validation_handlers();});$('#btn_ble_scan').click(function(){ble_scan();});}