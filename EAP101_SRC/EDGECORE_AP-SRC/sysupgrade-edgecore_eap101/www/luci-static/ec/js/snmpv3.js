
var user_row='<tr class="cbi-section-table-row" id="cbi-snmpd-cfgCFG_ID">'
+' '
+'<td class="cbi-value-field"> '
+'<div id="cbi-snmpd-cfgCFG_ID-name"> '
+'    <input type="hidden" id="acn.new.cfgCFG_ID" name="acn.new.cfgCFG_ID" value="CFG_ID" /> '
+' '
+'    <input title="" type="text" class="ace-tooltip" data-field="username" name="cbid.snmpd.cfgCFG_ID.name" '
+'   id="cbid.snmpd.cfgCFG_ID.name" value="" style="width:70px"/>'
+'   '
+'</div>'
+'<div id="cbip-snmpd-cfgCFG_ID-name"></div>'
+'</td>'
+' '
+'<td class="cbi-value-field">'
+'    <div id="cbi-snmpd-cfgCFG_ID-permission">'
+'        <select style="width:80px" class="cbi-input-select" onchange="cbi_d_update(this.id)" id="cbid.snmpd.cfgCFG_ID.permission" name="cbid.snmpd.cfgCFG_ID.permission" size="1">'
+'            <option id="cbi-snmpd-cfgCFG_ID-permission-rw" value="rw" selected="selected">Write</option>'
+'            <option id="cbi-snmpd-cfgCFG_ID-permission-ro" value="ro">Read</option>'
+'        </select>'
+'    </div>'
+'    <div id="cbip-snmpd-cfgCFG_ID-permission"></div>'
+'</td>'
+' '
+'<td class="cbi-value-field">'
+'    <div id="cbi-snmpd-cfgCFG_ID-authen">'
+'        <select style="width:80px" class="cbi-input-select" onchange="cbi_d_update(this.id)" id="cbid.snmpd.cfgCFG_ID.authen" name="cbid.snmpd.cfgCFG_ID.authen" size="1">'
+'            <option id="cbi-snmpd-cfgCFG_ID-authen-MD5" value="MD5" selected="selected">MD5</option>'
+'        </select>'
+'    </div>'
+'    <div id="cbip-snmpd-cfgCFG_ID-authen"></div>'
+'</td>'
+' '
+'<td class="cbi-value-field">'
+'<div id="cbi-snmpd-cfgCFG_ID-authenpw">'
+'    '
+'    <input title="" type="password" class="ace-tooltip"  '
+'    name="cbid.snmpd.cfgCFG_ID.authenpw" id="cbid.snmpd.cfgCFG_ID.authenpw" value="" style="width:80px" onchange="cbi_d_update(this.id)" /> '
+'        <i  class="icon-eye-open" style="cursor:pointer" '
+'        onclick="var e = document.getElementById(\'cbid.snmpd.cfgCFG_ID.authenpw\'); e.type = (e.type==\'password\') ? \'text\' : \'password\';"></i>'
+''
+'</div>'
+'<div id="cbip-snmpd-cfgCFG_ID-authenpw"></div>'
+'</td>'
+' '
+'<td class="cbi-value-field">'
+'    <div id="cbi-snmpd-cfgCFG_ID-encryp">'
+'        <select style="width:80px" class="cbi-input-select" onchange="cbi_d_update(this.id)" id="cbid.snmpd.cfgCFG_ID.encryp" name="cbid.snmpd.cfgCFG_ID.encryp" size="1">'
+'            <option id="cbi-snmpd-cfgCFG_ID-encryp-DES" value="DES" selected="selected">DES</option>'
+'        </select>'
+'    </div>'
+'    <div id="cbip-snmpd-cfgCFG_ID-encryp"></div>'
+'</td>'
+' '
+'<td class="cbi-value-field">'
+'<div id="cbi-snmpd-cfgCFG_ID-encryppw">'
+'    '
+'    <input title="" type="password" class="ace-tooltip"  '
+'    name="cbid.snmpd.cfgCFG_ID.encryppw" id="cbid.snmpd.cfgCFG_ID.encryppw" value=""  onchange="cbi_d_update(this.id)" /> '
+'        <i  class="icon-eye-open" style="cursor:pointer" '
+'        onclick="var e = document.getElementById(\'cbid.snmpd.cfgCFG_ID.encryppw\'); e.type = (e.type==\'password\') ? \'text\' : \'password\';"></i>'
+''
+'</div>'
+'<div id="cbip-snmpd-cfgCFG_ID-encryppw"></div>'
+'</td>'
+' '
+'<td class="cbi-section-table-cell" style="width:50px">'
+''
+'<button class="btn btn-info btn-mini btn-danger" data-new="1"  value="cfgCFG_ID"  '
+'onclick="removeSnmpV3UserRow(this.id); return false;" '
+'name="cbi.rts.snmpd.cfgCFG_ID" id="cbi.rts.snmpd.cfgCFG_ID" alt="Delete"'
+' title="Delete"><i class="icon-trash"></i></button>     '
+'';var add_snmpdv3user_counter=0;function authenpw_change(_id){var flag_authenpw=true;var authenpw_id=document.getElementById(_id);var authenpw_val=$(authenpw_id).val();clear_validate_error(authenpw_id);if((authenpw_val=='')||(!rangelength(authenpw_val,8,12))||(authenpw_val.match(/^[a-zA-Z0-9]+$/)==null)){set_err_msg($(authenpw_id),true,_('Must contain 8 to 12 alphanumeric characters. No symbols allowed!'));flag_authenpw=false;}
return flag_authenpw;}
function encryppw_change(_id){var flag_encryppw=true;var encryppw_id=document.getElementById(_id);var encryppw_val=$(encryppw_id).val();clear_validate_error(encryppw_id);if((encryppw_val=='')||(encryppw_val.length!=8)||(encryppw_val.match(/^[a-zA-Z0-9]+$/)==null)){set_err_msg($(encryppw_id),true,_('Must contain exactly 8 alphanumeric characters. No symbols allowed!'));flag_encryppw=false;}
return flag_encryppw;}
function removeSnmpV3UserRow(btn){btn=btn.replace(/\./g,'\\.');var $btn=$('#'+btn);var value=$btn.attr('value');if($btn.hasClass('disabled')){return;}
var id='acn\\.del\\.snmpd\\.'+value;$('#'+id).attr('value',1);$('#cbi-snmpd-'+value).fadeOut();if($btn.data('new')=='1'){$('#cbi-snmpd-'+value).remove();}
$('#cbi-snmpd-'+value+' input').attr('deleted','deleted');if(getVisibleRowCount(-1)<=MAX_COUNT){$('#alert_up_max').hide();$('#btn_add').attr('disabled',false);}}
function getVisibleRowCount(row_offset){var offset=row_offset;if(offset==undefined){offset=-2;}
var len=$('#table_snmpV3users tr:visible').length+offset;return len;}
function addUserRow(){var name='#table_snmpV3users';$(name+'_row_empty').hide();var cfg_id=add_snmpdv3user_counter;add_snmpdv3user_counter++;var z='0';var row=user_row.replace(/CFG_ID/g,cfg_id);var row=$.parseHTML(row);if($(name+' tr').length>0){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
var row_id='cbi-snmpd-cfg'+cfg_id;$('#'+row_id+' input').change(function(e,data){cbi_d_update(this.id);});$('#'+row_id+' input').tooltip();$('#'+row_id+' input').each(function(){if($(this).attr('type')=='text'&&this.id.indexOf('CFG_ID')<0){cbi_validate_field(this.id,false,'username');}
if($(this).attr('type')=='password'&&this.id.indexOf('CFG_ID')<0){if(this.id.indexOf('authenpw')>=0){var authenpw_id=document.getElementById(this.id);$(authenpw_id).change(function(){authenpw_change(this.id);});authenpw_change(this.id);}
if(this.id.indexOf('encryppw')>=0){var encryppw_id=document.getElementById(this.id);$(encryppw_id).change(function(){encryppw_change(this.id);});encryppw_change(this.id);}}});if(getVisibleRowCount(-1)>=MAX_COUNT){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);return;}
return false;}
function validate_snmpv3(){var res=true;var authenpw_val='';var encryppw_val='';$("#table_snmpV3users").find("input[id*='authenpw'][deleted!=deleted]").each(function(){authenpw_val=this.value;if((authenpw_val=='')||(!rangelength(authenpw_val,8,12))||(authenpw_val.match(/^[a-zA-Z0-9]+$/)==null)){set_err_msg($(this),true,_('Must contain 8 to 12 alphanumeric characters. No symbols allowed!'));res=false;}});$("#table_snmpV3users").find("input[id*='encryppw'][deleted!=deleted]").each(function(){encryppw_val=this.value;if((encryppw_val=='')||(encryppw_val.length!=8)||(encryppw_val.match(/^[a-zA-Z0-9]+$/)==null)){set_err_msg($(this),true,_('Must contain exactly 8 alphanumeric characters. No symbols allowed!'));res=false;}});return res;}
function validate_snmpv3_form(){var res_snmpv3=validate_snmpv3();var res=(res_snmpv3);if(!res){cbi_show_form_error();res=false;}
return res;}
function before_submit_snmpv3(){var usernames={};var duplicates=false;$('.cbi-value-field input').each(function(input){if(this.id.indexOf('CFG_ID')>=0){return;}
if($(this).attr('deleted')=='deleted'){return;}
if($(this).data('field')=='username'){var username=$(this).val();if(usernames[username]==username){set_err_msg($(this),true,_('Duplicated name!'));duplicates=true;return;}
usernames[username]=username;}});if(duplicates){$('#form_error_msg_placeholder').show();$('#form_error_msg').text('Duplicate usernames have been found! Please fix this issue before continuing.');return false;}
$('input[type=\'checkbox\']').removeAttr('disabled');if(!validate_snmpv3_form()){cbi_show_form_error();return false;}else{return true;}}
$(function(){$('#alert_up_max').hide();if(getVisibleRowCount(-1)>=MAX_COUNT){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}
$('.cbi-value-field input').each(function(input){if(this.id.indexOf('CFG_ID')>=0){return;}
if($(this).attr('type')=='text'){cbi_validate_field(this.id,false,'username');$(this).data('field','username');}
if($(this).attr('type')=='password'){if(this.id.indexOf('authenpw')>=0){var authenpw_id=document.getElementById(this.id);$(authenpw_id).change(function(){authenpw_change(this.id);});authenpw_change(this.id);}
if(this.id.indexOf('encryppw')>=0){var encryppw_id=document.getElementById(this.id);$(encryppw_id).change(function(){encryppw_change(this.id);});encryppw_change(this.id);}}});$('button.ace-tooltip').tooltip();$('button.disabled').click(function(e){if(!$(this).hasClass('disabled')){$('.disabled').removeClass('disabled').attr('rel',null);$(this).addClass('disabled').attr('rel','tooltip');}});});