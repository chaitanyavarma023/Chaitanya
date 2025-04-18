
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
+'            <option id="cbi-snmpd-cfgCFG_ID-authen-SHA" value="SHA">SHA</option>'
+'        </select>'
+'    </div>'
+'    <div id="cbip-snmpd-cfgCFG_ID-authen"></div>'
+'</td>'
+' '
+'<td class="cbi-value-field">'
+'<div id="cbi-snmpd-cfgCFG_ID-authenpw">'
+'    '
+'    <input title="" type="password" class="ace-tooltip"  '
+'    name="cbid.snmpd.cfgCFG_ID.authenpw" id="cbid.snmpd.cfgCFG_ID.authenpw" value="" style="width:80px"/> '
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
+'            <option id="cbi-snmpd-cfgCFG_ID-encryp-AES" value="AES">AES</option>'
+'        </select>'
+'    </div>'
+'    <div id="cbip-snmpd-cfgCFG_ID-encryp"></div>'
+'</td>'
+' '
+'<td class="cbi-value-field">'
+'<div id="cbi-snmpd-cfgCFG_ID-encryppw">'
+'    '
+'    <input title="" type="password" class="ace-tooltip"  '
+'    name="cbid.snmpd.cfgCFG_ID.encryppw" id="cbid.snmpd.cfgCFG_ID.encryppw" value="" /> '
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
+'';var add_snmpdv3user_counter=0;function removeSnmpV3UserRow(btn){btn=btn.replace(/\./g,'\\.');var $btn=$('#'+btn);var value=$btn.attr('value');if($btn.hasClass('disabled')){return;}
var id='acn\\.del\\.snmpd\\.'+value;$('#'+id).attr('value',1);$('#cbi-snmpd-'+value).fadeOut();if($btn.data('new')=='1'){$('#cbi-snmpd-'+value).remove();}
$('#cbi-snmpd-'+value+' input').attr('deleted','deleted');if(getVisibleRowCount(-1)<=MAX_COUNT){$('#alert_up_max').hide();$('#btn_add').attr('disabled',false);}}
function getVisibleRowCount(row_offset){var offset=row_offset;if(offset==undefined){offset=-2;}
var len=$('#table_snmpV3users tr:visible').length+offset;return len;}
function addUserRow(){var name='#table_snmpV3users';$(name+'_row_empty').hide();var cfg_id=add_snmpdv3user_counter;add_snmpdv3user_counter++;var z='0';var row=user_row.replace(/CFG_ID/g,cfg_id);var row=$.parseHTML(row);if($(name+' tr').length>0){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
var row_id='cbi-snmpd-cfg'+cfg_id;$('#'+row_id+' input').change(function(e,data){cbi_d_update(this.id);});$('#'+row_id+' input').tooltip();$('#'+row_id+' input').each(function(){if($(this).attr('type')=='text'&&this.id.indexOf('CFG_ID')<0){cbi_validate_field(this.id,false,'username');}
if($(this).attr('type')=='password'&&this.id.indexOf('CFG_ID')<0){cbi_validate_field(this.id,false,'limited_len_str(6,20)');}});if(getVisibleRowCount(-1)>=MAX_COUNT){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);return;}
return false;}
$(function(){$('#alert_up_max').hide();if(getVisibleRowCount(-1)>=MAX_COUNT){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}
$('.cbi-value-field input').each(function(input){if(this.id.indexOf('CFG_ID')>=0){return;}
if($(this).attr('type')=='text'){cbi_validate_field(this.id,false,'username');$(this).data('field','username');}
if($(this).attr('type')=='password'){cbi_validate_field(this.id,false,'limited_len_str(6,20)');}});$('button.ace-tooltip').tooltip();$('button.disabled').click(function(e){if(!$(this).hasClass('disabled')){$('.disabled').removeClass('disabled').attr('rel',null);$(this).addClass('disabled').attr('rel','tooltip');}});$('form').submit(function(){var usernames={};var duplicates=false;$('.cbi-value-field input').each(function(input){if(this.id.indexOf('CFG_ID')>=0){return;}
if($(this).attr('deleted')=='deleted'){return;}
if($(this).data('field')=='username'){var username=$(this).val();if(usernames[username]==username){duplicates=true;return;}
usernames[username]=username;}});if(duplicates){$('#form_error_msg_placeholder').show();$('#form_error_msg').text('Duplicate usernames have been found! Please fix this issue before continuing.');return false;}
$('input[type=\'checkbox\']').removeAttr('disabled');return true;});});