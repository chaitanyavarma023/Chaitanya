
var max_list=64;var new_val='';function validate_form(){var id='cbid\\.network\\.security\\.direct_enable';var enabled=$('#'+id).is(':checked');if(!enabled){return true;}
var is_positive_int=/^[0-9]*[1-9][0-9]*$/;var list_id='#cbid\\.network\\.security\\.direct_list';clear_validate_error(list_id);new_val='';if($(list_id).val()!=''){var tmp_val=convert_list($(list_id).val());tmp_arr=tmp_val.split(' ');if(tmp_arr.length>max_list){set_err_msg($(list_id),true,'The total Excluded IP list is up to '+max_list+'.');return false;}
for(var i=0;i<tmp_arr.length;i++){var inputstr,netbits,netbits_str;inputstr=tmp_arr[i];ipaddr_usr_input=inputstr.match(/\d+\.\d+\.\d+\.\d+/g);if(ipaddr_usr_input==null||!is_ip(ipaddr_usr_input)){set_err_msg($(list_id),true,'Not a valid IPv4 address!('+tmp_arr[i]+')');return false;}
new_val=new_val+ipaddr_usr_input;netbits_str=inputstr.match(/\/.*/);if(netbits_str!=null){netbits=netbits_str[0].replace(/\//,'');if(netbits!=''){if(!is_positive_int.test(netbits)||!is_in_range(netbits,0,32)){set_err_msg($(list_id),true,'Not a valid netmask!('+tmp_arr[i]+')');return false;}
new_val=new_val+'/'+netbits+'\n';}else{new_val=new_val+'\n';}}else{new_val=new_val+'\n';}}
$(list_id).val(new_val);}
return true;}
function convert_list(val){var tmp_walled_str=val.replace(/\r\n|\r|\n/g,' ');tmp_walled_str=tmp_walled_str.replace(/(^\s*)|(\s*$)/g,'');tmp_walled_str=tmp_walled_str.replace(/\s+/g,' ');return tmp_walled_str;}
$(function(){$('#cbi').submit(function(){if(!validate_form()){$('#form_error_msg').text('Some fields are invalid, please see messages below!');$('#form_error_msg_placeholder').removeClass('hide');return false;}else{return true;}});});