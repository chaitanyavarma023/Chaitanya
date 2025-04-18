
var user_row='<tr class="cbi-section-table-row" id="cbi-users-cfgCFG_ID">'
+' '
+'<td class="cbi-value-field">'
+'<div id="cbi-users-cfgCFG_ID-enabled">'
+'    <input type="hidden" value="1" name="cbi.cbe.users.cfgCFG_ID.enabled">'
+'    <input title="" class="ace-tooltip ace-switch ace-switch-2 " onclick="cbi_d_update(this.id)" onchange="cbi_d_update(this.id)" '
+'       type="checkbox" id="cbid.users.cfgCFG_ID.enabled" name="cbid.users.cfgCFG_ID.enabled" value="1" checked="checked">'
+'    <span class="lbl">&nbsp;</span>'
+'    </div>'
+'    <div id="cbip-users-cfgCFG_IDb-enabled"></div>'
+'</td>'
+'<td class="cbi-value-field"> '
+'<div id="cbi-users-cfgCFG_ID-name"> '
+'    <input type="hidden" id="acn.new.cfgCFG_ID" name="acn.new.cfgCFG_ID" value="CFG_ID" /> '
+' '
+'    <input title="" type="text" class="ace-tooltip" data-field="username" name="cbid.users.cfgCFG_ID.name" '
+'   id="cbid.users.cfgCFG_ID.name" value="" />'
+'   '
+'</div>'
+'<div id="cbip-users-cfgCFG_ID-name"></div>'
+'</td>'
+' '
+'<td class="cbi-value-field">'
+'<div id="cbi-users-cfgCFG_ID-passwd">'
+'    '
+'    <input title="" type="password" class="ace-tooltip"  '
+'    name="cbid.users.cfgCFG_ID.passwd" id="cbid.users.cfgCFG_ID.passwd" value="" /> '
+'        <i  class="icon-eye-open" style="cursor:pointer" '
+'        onclick="var e = document.getElementById(\'cbid.users.cfgCFG_ID.passwd\'); e.type = (e.type==\'password\') ? \'text\' : \'password\';"></i>'
+''
+'</div>'
+'<div id="cbip-users-cfgCFG_ID-passwd"></div>'
+'</td>'
+' '
+'<td class="cbi-section-table-cell" style="width:50px">'
+''
+'<button class="btn btn-info btn-mini btn-danger" data-new="1"  value="cfgCFG_ID"  '
+'onclick="removeUserRow(this.id); return false;" '
+'name="cbi.rts.users.cfgCFG_ID" id="cbi.rts.users.cfgCFG_ID" alt="Delete"'
+' title="Delete"><i class="icon-trash"></i></button>     '
+'';var add_user_counter=0;var enabled_cnt=0;function removeUserRow(btn){btn=btn.replace(/\./g,'\\.');var $btn=$('#'+btn);var value=$btn.attr('value');if($btn.hasClass('disabled')){return;}
var id='acn\\.del\\.users\\.'+value;$('#'+id).attr('value',1);$('#cbi-users-'+value).fadeOut();if($('#cbi-users-'+value+' input[type=\'checkbox\']').is(':checked')){enabled_cnt--;}
if($btn.data('new')=='1'){$('#cbi-users-'+value).remove();}
$('#cbi-users-'+value+' input').attr('deleted','deleted');check_last_entry();if(getVisibleRowCount(-1)<=MAX_COUNT){$('#alert_up_max').hide();$('#btn_add').attr('disabled',false);}}
function getVisibleRowCount(row_offset){var offset=row_offset;if(offset==undefined){offset=-2;}
var len=$('#table_users tr:visible').length+offset;return len;}
function addUserRow(){var name='#table_users';$(name+'_row_empty').hide();var cfg_id=add_user_counter;add_user_counter++;var z='0';var row=user_row.replace(/CFG_ID/g,cfg_id);var row=$.parseHTML(row);if($(name+' tr').length>0){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
var row_id='cbi-users-cfg'+cfg_id;$('#'+row_id+' input').change(function(e,data){cbi_d_update(this.id);});$('#'+row_id+' input').tooltip();$('#'+row_id+' input').each(function(){if($(this).attr('type')=='text'&&this.id.indexOf('CFG_ID')<0){cbi_validate_field(this.id,false,'username');}
if($(this).attr('type')=='password'&&this.id.indexOf('CFG_ID')<0){cbi_validate_field(this.id,false,'limited_len_str(6,20)');}});enabled_cnt++;$('input[name=\'cbid.users.cfg'+cfg_id+'.enabled\']').click(function(e){if(this.checked){enabled_cnt++;}else{enabled_cnt--;}
check_last_entry();});check_last_entry();if(getVisibleRowCount(-1)>=MAX_COUNT){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);return;}
return false;}
function check_last_entry(){var input_checkbox_obj=$('input[type=\'checkbox\']');if(input_checkbox_obj.length==1){input_checkbox_obj.prop('checked',true);input_checkbox_obj.prop('disabled','disabled');}
var $enableToggles=$('input[type=\'checkbox\']:checked');if(enabled_cnt==0){$('input[type=checkbox]')[0].checked=true;$('input[type=checkbox]')[0].disabled=true;enabled_cnt=1;}else if(enabled_cnt==1){$enableToggles.prop('disabled','disabled');}else{$enableToggles.removeAttr('disabled');}}
$(function(){$('#alert_up_max').hide();if(getVisibleRowCount(-1)>=MAX_COUNT){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}
$('.cbi-value-field input').each(function(input){if(this.id.indexOf('CFG_ID')>=0){return;}
if($(this).attr('type')=='text'){cbi_validate_field(this.id,false,'username');$(this).data('field','username');}
if($(this).attr('type')=='password'){cbi_validate_field(this.id,false,'limited_len_str(6,20)');}});$('button.ace-tooltip').tooltip();enabled_cnt=$('input[type=\'checkbox\']:checked').length;$('input[type=\'checkbox\']').click(function(e){if(this.checked){enabled_cnt++;}else{enabled_cnt--;}
check_last_entry();});check_last_entry();$('button.disabled').click(function(e){if(!$(this).hasClass('disabled')){$('.disabled').removeClass('disabled').attr('rel',null);$(this).addClass('disabled').attr('rel','tooltip');}});$('form').submit(function(){var usernames={};var duplicates=false;$('.cbi-value-field input').each(function(input){if(this.id.indexOf('CFG_ID')>=0){return;}
if($(this).attr('deleted')=='deleted'){return;}
if($(this).data('field')=='username'){var username=$(this).val();if(usernames[username]==username){duplicates=true;return;}
usernames[username]=username;}});if(duplicates){$('#form_error_msg_placeholder').show();$('#form_error_msg').text('Duplicate usernames have been found! Please fix this issue before continuing.');return false;}
$('input[type=\'checkbox\']').removeAttr('disabled');return true;});});