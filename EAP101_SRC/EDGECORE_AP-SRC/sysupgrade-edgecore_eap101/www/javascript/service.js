
var pre_ibeacon_id='#cbid\\.ibeacon\\.ibeacon\\.';function validate_form(){var res=validate_port()&&validate_ntp()&&validate_ibeacon_uuid();if(!res){cbi_show_form_error();}
return res;}
function set_err_msg(_io_id,err_ctrl,err_msg){var $io_id=_io_id;if(!(_io_id instanceof jQuery)){$io_id=$(_io_id);}
if(err_ctrl==true){$io_id.attr('data-original-title',err_msg);if($io_id.parent().hasClass('controls')){$io_id.parents('.control-group').addClass('error');}else{$io_id.parent('.control-group').addClass('error');}
$io_id.addClass('tooltip-error');$io_id.attr('data-trigger','focus');$io_id.tooltip();}else{$io_id.removeClass('tooltip-error');if($io_id.parent().hasClass('controls')){$io_id.parents('.control-group').removeClass('error');}else{$io_id.parent('.control-group').removeClass('error');}
$io_id.parent('.control-group').removeClass('error');$io_id.attr('data-original-title','');}}
function validate_ntp(){var res=false;var ntp_field_selector;if(!$('[id*="system.ntp.ntp_service"]').is(':checked')){return true;}
for(var i=0;i<$('[id*="system.ntp.server"]').length;i++){ntp_field_selector='[id*="system.ntp.server"]:eq('+i+')';if($.trim($(ntp_field_selector).val())!=''){set_err_msg(ntp_field_selector,false);return true;}}
if(!res){for(var i=0;i<$('[id*="system.ntp.server"]').length;i++){ntp_field_selector='[id*="system.ntp.server"]:eq('+i+')';set_err_msg(ntp_field_selector,true,'NTP server cannot be empty.');}}
return res;}
function validate_port(){var res=true;var err_msg=new Array(false,false,false,false,false);var http_port_id=document.getElementById('cbid.uhttpd.main.listen_http');var https_port_id=document.getElementById('cbid.uhttpd.main.listen_https');var http_port_val=$(http_port_id).val();var https_port_val=$(https_port_id).val();set_err_msg(http_port_id,false);set_err_msg(https_port_id,false);var telnet_port_obj=document.getElementById(telnet_port_id);var ssh_port_obj=document.getElementById(ssh_port_id);var telnet_port_value='',ssh_port_value='';var error_detail='Port is duplicated.';if(telnet_port_obj){telnet_port_value=$(telnet_port_obj).val();set_err_msg(telnet_port_obj,false);if(!is_in_range(telnet_port_value,0,65535)){res=false;err_msg[0]=true;}}
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
if(err_msg[0]){set_err_msg(telnet_port_obj,true,'Not a valid port range! Allowed values are integers between 0 and 65535, inclusive.');}
if(err_msg[1]){set_err_msg(ssh_port_obj,true,'Not a valid port range! Allowed values are integers between 0 and 65535, inclusive.');}
if(err_msg[2]){set_err_msg(http_port_id,true,'Not a valid port range! Allowed values are 80 or integers between 1025 and 65534, inclusive.');}
if(err_msg[3]){set_err_msg(https_port_id,true,'Not a valid port range! Allowed values are 443 or integers between 1025 and 65534, inclusive.');}
return res;}
function validate_ibeacon_uuid(){var res=true;var err_msg=new Array(false,false,false,false,false);var ibeacon_enabled_obj=$(pre_ibeacon_id+'enabled');var uuid_id_1=pre_ibeacon_id+'uuid';var uuid_id_2=pre_ibeacon_id+'_uuid_2';var uuid_id_3=pre_ibeacon_id+'_uuid_3';var uuid_id_4=pre_ibeacon_id+'_uuid_4';var uuid_id_5=pre_ibeacon_id+'_uuid_5';var re=/^[a-fA-F0-9]+$/;clear_validate_error(uuid_id_1);clear_validate_error(uuid_id_2);clear_validate_error(uuid_id_3);clear_validate_error(uuid_id_4);clear_validate_error(uuid_id_5);if(!ibeacon_enabled_obj.is(':checked')){return res;}
if($(uuid_id_1).val().length!=8||!re.test($(uuid_id_1).val())){res=false;set_err_msg($(uuid_id_1),true,'Value must be 8 Hex characters.');}
if($(uuid_id_2).val().length!=4||!re.test($(uuid_id_2).val())){res=false;set_err_msg($(uuid_id_2),true,'Value must be 4 Hex characters.');}
if($(uuid_id_3).val().length!=4||!re.test($(uuid_id_3).val())){res=false;set_err_msg($(uuid_id_3),true,'Value must be 4 Hex characters.');}
if($(uuid_id_4).val().length!=4||!re.test($(uuid_id_4).val())){res=false;set_err_msg($(uuid_id_4),true,'Value must be 4 Hex characters.');}
if($(uuid_id_5).val().length!=12||!re.test($(uuid_id_5).val())){res=false;set_err_msg($(uuid_id_5),true,'Value must be 12 Hex characters.');}
return res;}
function add_validation_handlers(){var $http_port=$('#cbid\\.uhttpd\\.main\\.listen_http');var $https_port=$('#cbid\\.uhttpd\\.main\\.listen_https');$http_port.change(validate_port);$https_port.change(validate_port);$http_port.change();$https_port.change();if(ssh_port_id!=''){var $ssh_port=$('#'+ssh_port_id.replace(/\./g,'\\.'));$ssh_port.change(validate_port);$ssh_port.change();}
if(telnet_port_id!=''){var $telent_port=$('#'+telnet_port_id.replace(/\./g,'\\.'));$telent_port.change(validate_port);$telent_port.change();}
var uuid_id_1=$(pre_ibeacon_id+'uuid');var uuid_id_2=$(pre_ibeacon_id+'_uuid_2');var uuid_id_3=$(pre_ibeacon_id+'_uuid_3');var uuid_id_4=$(pre_ibeacon_id+'_uuid_4');var uuid_id_5=$(pre_ibeacon_id+'_uuid_5');uuid_id_1.change(validate_ibeacon_uuid);uuid_id_2.change(validate_ibeacon_uuid);uuid_id_3.change(validate_ibeacon_uuid);uuid_id_4.change(validate_ibeacon_uuid);uuid_id_5.change(validate_ibeacon_uuid);uuid_id_1.change();uuid_id_2.change();uuid_id_3.change();uuid_id_4.change();uuid_id_5.change();}
var snmpd_section_num='';function snmpd_enable_click(_val){if(_val){$('#cbi-snmpd-public').removeClass('hide');$('#cbi-snmpd-private').removeClass('hide');}else{$('#cbi-snmpd-public').addClass('hide');$('#cbi-snmpd-private').addClass('hide');}}
function fill_uuid(_checked){if(_checked){var uuid_id=$(pre_ibeacon_id+'uuid');var uuid2_id=$(pre_ibeacon_id+'_uuid_2');var uuid3_id=$(pre_ibeacon_id+'_uuid_3');var uuid4_id=$(pre_ibeacon_id+'_uuid_4');var uuid5_id=$(pre_ibeacon_id+'_uuid_5');var uuid_val=uuid_id.val();if(uuid_val.length==32){uuid_id.val(uuid_val.substr(0,8));uuid2_id.val(uuid_val.substr(8,4));uuid3_id.val(uuid_val.substr(12,4));uuid4_id.val(uuid_val.substr(16,4));uuid5_id.val(uuid_val.substr(20));}}}
var ssh_port_id='';var telnet_port_id='';$(function(){var ibeacon_enabled_obj=$(pre_ibeacon_id+'enabled');fill_uuid(ibeacon_enabled_obj.is(':checked'));ibeacon_enabled_obj.click(function(){fill_uuid(this.checked);add_validation_handlers();});$('#cbi').submit(function(){if(!$('#cbid\\.snmpd\\.'+snmpd_section_num+'\\.enable').is(':checked')){$('#cbid\\.snmpd\\.public\\.community').val('');}
return validate_form();});$('.cbi-section-node input').each(function(input){if(this.id.indexOf('dropbear')>=0&&this.id.indexOf('Port')>=0){ssh_port_id=this.id;}
if(this.id.indexOf('telnetd')>=0&&this.id.indexOf('Port')>=0){telnet_port_id=this.id;}});add_validation_handlers();$('.control-group input').each(function(input){if(this.id.indexOf('snmpd')>=0){var id_arr=this.id.split('.');snmpd_section_num=id_arr[2];if(this.id.indexOf('enable')>=0){snmpd_enable_click($('#cbid\\.snmpd\\.'+snmpd_section_num+'\\.enable').is(':checked'));}
if(this.id.indexOf('name')>=0){var _permission_val=$('#cbid\\.snmpd\\.'+snmpd_section_num+'\\.permission').val();if(_permission_val=='ro'){$('#cbi-snmpd-'+snmpd_section_num+'-name-tel').html('Read Community'+'&nbsp;  &nbsp;');}else if(_permission_val=='rw'){$('#cbi-snmpd-'+snmpd_section_num+'-name-tel').html('Write Community'+'&nbsp;  &nbsp;');}
var _ipv6permission_val=$('#cbid\\.snmpd\\.'+snmpd_section_num+'\\.ipv6permission').val();if(_ipv6permission_val=='ro'){$('#cbi-snmpd-'+snmpd_section_num+'-name-tel').html('IPv6 Read Community'+'&nbsp;  &nbsp;');}else if(_ipv6permission_val=='rw'){$('#cbi-snmpd-'+snmpd_section_num+'-name-tel').html('IPv6 Write Community'+'&nbsp;  &nbsp;');}}}});$('#cbid\\.snmpd\\.'+snmpd_section_num+'\\.enable').click(function(){snmpd_enable_click(this.checked);});});