
var vlan_row='<tr id="vlanCFG_ID_row">'
+'<td>'
+'                <input style="width:50px" type="text" class="ace-tooltip" '
+'                  name="vlanCFG_ID.id" id="vlanCFG_ID.id" value="" > '
+'             </td>'
+'             <td>'
+eth_inputs
+'            </td>'
+'            <td>'
+'               <input id="pppoe_CFG_ID" name="pppoe_CFG_ID" value="1" type="checkbox" onchange="pppoe_change(\'CFG_ID\');"><label class="lbl">&nbsp; <%:Enable%></label><br>'
+'               <span class="hide" id="input_user_CFG_ID"><%:PPPoe Username%> &nbsp; <input id="username_CFG_ID" name="username_CFG_ID" type="text" style="margin-bottom: 3px;"><br></span>'
+'               <span class="hide" id="input_pwd_CFG_ID"><%:PPPoe Password%> &nbsp; &nbsp;<input id="pwd_CFG_ID" name="pwd_CFG_ID" type="password" style="margin-bottom: 3px;">'
+'               <i class="icon-eye-open" style="cursor:pointer" onclick="var e = document.getElementById(\'pwd_CFG_ID\'); e.type = (e.type==\'password\') ? \'text\' : \'password\';"></i><br></span>'
+'               <span class="hide" id="input_ip_CFG_ID"><%:IP Address%> &nbsp; &nbsp;<input id="ip_CFG_ID" name="ip_CFG_ID" type="text"></span>'
+'            </td>'
+'            <td>(None)</td> '
+'            <td> '
+'               <button class="btn btn-info btn-mini btn-danger" onclick="{removeRow(this.id);  return false;}" '
+'               alt="Delete" id="vlanCFG_ID" value="CFG_ID" title="Delete"> '
+'               <i class="icon-trash"></i></button> '
+'           </td> '
+'            </tr> ';var vlan_id_min=2;var vlan_id_max=4094;function removeRow(btn){var value=$('#'+btn).attr('value');var id='acn\\.del\\.vlan'+value;$('#'+id).attr('value',1);$('#vlan'+value+'_row').remove();if(getVisibleRowCount(-1)<=(MAX_VLAN_COUNT-VLAN_START)){$('#alert_up_max').hide();$('#btn_add').attr('disabled',false);}}
function getVisibleRowCount(row_offset){var offset=row_offset;if(offset===undefined){offset=-2;}
var len=$('#table_vlans tr:visible').length+offset;return len;}
function get_next_vlan_id(){for(var i=VLAN_START;i<=MAX_VLAN_COUNT;i++){var id='#vlan'+i+'\\.id';if($(id).val()===undefined){return i;}}}
function addRow(){var name='#table_vlans';$('#row_empty').hide();var cfg_id=get_next_vlan_id();var row=vlan_row.replace(/CFG_ID/g,cfg_id);row=$.parseHTML(row);if($(name+' tr').length>1){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
var row_id='#vlan'+cfg_id+'_row';$(row_id+' input').change(function(){cbi_d_update(this.id);});$(row_id+' input[type=checkbox]').change(function(){validatePortSelection();});validatePortSelection();$(row_id+' input').tooltip();$(row_id+' input').each(function(){if($(this).attr('type')==='text'&&this.id.indexOf('.id')>=0){cbi_validate_field(this.id,false,'range('+vlan_id_min+', '+vlan_id_max+')');}});if(getVisibleRowCount(-1)>=(MAX_VLAN_COUNT-VLAN_START)){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);return;}
return false;}
function checkArrayRepeat(array){var hash={},hash_idx={};var flag=false;for(var i in array){if(hash_idx[array[i]]===undefined){hash_idx[array[i]]=i+' ';}else{hash_idx[array[i]]+=i+' ';}
if(hash[array[i]]){var hash_idx_tmp=hash_idx[array[i]].split(' ');for(var j=0;j<hash_idx_tmp.length;j++){$('#vlan'+hash_idx_tmp[j]+'_row').css('color','red');}
flag=true;}
hash[array[i]]=true;}
return flag;}
function is_duplicate_data(){var data_arr=new Array(MAX_VLAN_COUNT-1);var vlan_ids={};$('#alert_duplicate_mgmt').hide();var flag=true;for(var i=VLAN_START;i<MAX_VLAN_COUNT;i++){$('#vlan'+i+'_row').removeAttr('style');if($('#vlan'+i+'\\.id').val()===undefined){continue;}
var tmp=$('#vlan'+i+'\\.id').val()+'#';if($('#vlan'+i+'\\.id').val()===mgmt_vlan_id){$('#alert_duplicate_mgmt').show();$('#vlan'+i+'_row').css('color','red');flag=false;}
if(vlan_ids[$('#vlan'+i+'\\.id').val()]){$('#alert_duplicate').show();$('#vlan'+i+'_row').css('color','red');$('#vlan'+vlan_ids[$('#vlan'+i+'\\.id').val()]+'_row').css('color','red');flag=false;}
vlan_ids[$('#vlan'+i+'\\.id').val()]=i;var tmp_eth='';for(var j=1;j<=num_eths;j++){tmp_eth+=($('input[name=vlan'+i+'-eth'+j+']:checked').val())+'#';}
tmp+=tmp_eth;data_arr[i]=tmp;}
if(checkArrayRepeat(data_arr)){$('#alert_duplicate').show();flag=false;}
if(flag){$('#alert_duplicate').hide();}else{$('#alert_duplicate').show();}
return flag;}
function validatePortSelection(){var noPortsSelected=false;var rows=$('#table_vlans tbody tr');rows.each(function(){if($(this).children('td').eq(1).find('input[type=checkbox]:checked').length===0){noPortsSelected=true;return false;}});$('#alert_no_ports_selected').toggle(noPortsSelected);if(noPortsSelected){return false;}}
function isValidPortSelection(){return $('#alert_no_ports_selected').is(':hidden');}
function pppoe_change(checkbox_id){var row_id='#vlan'+checkbox_id+'_row';if($('#pppoe_'+checkbox_id).is(':checked')){$('#input_user_'+checkbox_id).show();$('#input_pwd_'+checkbox_id).show();$('#input_ip_'+checkbox_id).show();}else{$('#input_user_'+checkbox_id).hide();$('#input_pwd_'+checkbox_id).hide();$('#input_ip_'+checkbox_id).hide();}}
function validateOtherIP(input_value,input_id){var flag=true;for(var ipentry in ipdata){if(ipdata.hasOwnProperty(ipentry)){var _ipentry=ipdata[ipentry];if(input_value===_ipentry.ip){set_err_msg($(input_id),true,'Your Internet IP address is the same as the '+_ipentry.friendly+' IP address!');flag=false;}
if(is_in_netmask(_ipentry.ip,_ipentry.nm,input_value)){set_err_msg($(input_id),true,'Your Internet IP address falls in the same subnet as the '+_ipentry.friendly+' network IP address.');flag=false;}}}
return flag;}
$(function(){$('#alert_up_max').hide();if(getVisibleRowCount(-1)>=(MAX_VLAN_COUNT-VLAN_START)){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}
$('#form_vlans').submit(function(){var res=true;var val=cbi_validate_form(document.getElementById('form_vlans'),'Invalid parameters detected below!');if(val){$('#table_vlans input').each(function(input){if($(this).attr('type')==='text'&&this.id.indexOf('.id')>=0){var field=(typeof this.id==='string')?document.getElementById(this.id):this.id;}
if(field!==undefined){field.value=parseInt(field.value,10);}});}
var vlan_pppoe_ip={};for(var i=VLAN_START;i<MAX_VLAN_COUNT;i++){clear_validate_error('#username_'+i);clear_validate_error('#pwd_'+i);clear_validate_error('#ip_'+i);if($('#vlan'+i+'\\.id').val()===undefined){continue;}
if($('#pppoe_'+i).is(':checked')){if(!cbi_validators.username($('#username_'+i).val())){set_err_msg($('#username_'+i),true,'Must be between 1 and 32 ASCII characters. Only accept A-Z, a-z, 0-9, Period (.), Underscore (_) and Hyphen (-), but NOT allow username that begin with Hyphen (-).');res=false;}
if(!cbi_validators.limited_len_str($('#pwd_'+i).val(),[6,20])){set_err_msg($('#pwd_'+i),true,'This value must be between 6 and 60 characters long.');res=false;}
var _ip_id='#ip_'+i;var _ip_value=$(_ip_id).val();if(!cbi_validators.ip4addr(_ip_value)){set_err_msg($(_ip_id),true,'Not a valid IPv4 address!');res=false;}
if(!validateOtherIP(_ip_value,_ip_id)){res=false;}
if(vlan_pppoe_ip[_ip_value]){set_err_msg($(_ip_id),true,'The ip is duplicated with other pppoe vlan ip.');res=false;}
vlan_pppoe_ip[_ip_value]=i;}}
validatePortSelection();if(!is_duplicate_data()||!isValidPortSelection()){res=false;}
if(!res){cbi_show_form_error();}
return res&&val;});$('#table_vlans input').each(function(idx,input){if(this.id.indexOf('CFG_ID')<0){var attrType=$(this).attr('type');if(attrType==='text'&&this.id.indexOf('.id')>=0){cbi_validate_field(this.id,false,'range('+vlan_id_min+', '+vlan_id_max+')');}else if(attrType==='checkbox'){$(this).change(function(evt){validatePortSelection();});}}});$('button.ace-tooltip').tooltip();$('button.disabled').click(function(){if(!$(this).hasClass('disabled')){$('.disabled').removeClass('disabled').attr('rel',null);$(this).addClass('disabled').attr('rel','tooltip');}});for(var i=VLAN_START;i<MAX_VLAN_COUNT;i++){if($('#vlan'+i+'\\.id').val()===undefined){continue;}
pppoe_change(i);}});