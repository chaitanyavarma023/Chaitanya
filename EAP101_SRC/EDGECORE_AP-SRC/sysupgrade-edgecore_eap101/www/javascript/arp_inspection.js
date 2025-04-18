
var statictrust_row='<tr class="cbi-section-table-row" id="cbi-statictrust-cfgCFG_ID">'
+' '
+'    <td class="cbi-value-field">'
+'        <div id="cbi-statictrust-cfgCFG_ID-mac">'
+'        <input type="hidden" id="acn.new.cfgCFG_ID" name="acn.new.cfgCFG_ID" value="CFG_ID" />'
+'            <input  title="" autocomplete="off" type="text" class="ace-tooltip"'
+'            onchange="cbi_d_update(this.id)" name="cbid.statictrust.cfgCFG_ID.mac" id="cbid.statictrust.cfgCFG_ID.mac" value="" />'
+'            <script type="text/javascript">'
+'                cbi_validate_field("cbid.statictrust.cfgCFG_ID.mac", true, "macaddr");'
+'            </script>'
+'        </div>'
+'        <div id="cbip-statictrust-cfgCFG_ID-mac"></div>'
+'    </td>'
+''
+'    <td class="cbi-value-field">'
+'        <div id="cbi-statictrust-cfgCFG_ID-ip">'
+'            <input  title="" autocomplete="off" type="text" class="ace-tooltip"'
+'            onchange="cbi_d_update(this.id)" name="cbid.statictrust.cfgCFG_ID.ip" id="cbid.statictrust.cfgCFG_ID.ip" value="" />'
+'            <script type="text/javascript">'
+'                cbi_validate_field("cbid.statictrust.cfgCFG_ID.ip", true, "firewall_ipaddr");'
+'            </script>'
+'        </div>'
+'        <div id="cbip-statictrust-cfgCFG_ID-ip"></div>'
+'    </td>'
+''
+'<td class="cbi-value-field">'
+'    <div id="cbi-statictrust-cfgCFG_ID-state">'
+'        <input type="hidden" value="1" name="cbi.cbe.statictrust.cfgCFG_ID.custom">'
+'        <input type="hidden" value="1" name="cbi.cbe.statictrust.cfgCFG_ID.enabled">'
+'        <input title="" class="ace-tooltip ace-switch ace-switch-3 " onclick="cbi_d_update(this.id)" onchange="cbi_d_update(this.id)" '
+'       type="checkbox" id="cbid.statictrust.cfgCFG_ID.state" name="cbid.statictrust.cfgCFG_ID.state" value="1" checked="checked">'
+'        <span class="lbl">&nbsp;</span>'
+'    </div>'
+'    <div id="cbip-statictrust-cfgCFG_ID-enabled"></div>'
+'</td>'
+''
+'<td class="cbi-section-table-cell" style="width:50px">'
+''
+'<input type="hidden" name="acn.del.statictrust.cfgCFG_ID" id="acn.del.statictrust.cfgCFG_ID" value="0">'
+'<button class="btn btn-info btn-mini btn-danger" data-new="1"  value="cfgCFG_ID"  '
+'onclick="removeStatictrustRow(this.id); return false;" '
+'name="cbi.rts.statictrust.cfgCFG_ID" id="cbi.rts.statictrust.cfgCFG_ID" alt="Delete"'
+' title="Delete"><i class="icon-trash"></i></button>     '
+'';var add_user_counter=0;var arpinspection_enable="[id*='arpinspection_enable'][type='checkbox']";var forcedhcp_enable="[id*='forcedhcp_enable'][type='checkbox']";var trustlistbroadcast_enable="[id*='trustlistbroadcast_enable'][type='checkbox']";var statictrust_enable="[id*='statictrust_enable'][type='checkbox']";var forcedhcp_row="[id*='-forcedhcp_enable']";var trustlistbroadcast_row="[id*='-trustlistbroadcast_enable']";var statictrustlist_row="[id*='-statictrust_enable']";function removeStatictrustRow(btn){btn=btn.replace(/\./g,'\\.');var $btn=$('#'+btn);var value=$btn.attr('value');if($btn.hasClass('disabled')){return;}
var id='acn\\.del\\.statictrust\\.'+value;$('#'+id).attr('value',1);$('#cbi-statictrust-'+value).fadeOut();if($btn.data('new')==='1'){$('#cbi-statictrust-'+value).remove();}
$('#cbi-statictrust-'+value+' input').attr('deleted','deleted');if(getVisibleRowCount(-1)<=max_count){$('#alert_up_max').hide();$('#btn_add').attr('disabled',false);}}
function getVisibleRowCount(row_offset){var offset=row_offset;if(offset===undefined){offset=-2;}
var len=$('#table_arp_statictrust tr:visible').length+offset;return len;}
function addStatictrustRow(){var name='#table_arp_statictrust';$(name+'_row_empty').hide();var cfg_id=add_user_counter;add_user_counter++;var row=statictrust_row.replace(/CFG_ID/g,cfg_id);row=$.parseHTML(row);if($(name+' tr').length>0){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
var row_id='cbi-statictrust-cfg'+cfg_id;$('#'+row_id+' input').change(function(e,data){cbi_d_update(this.id);});$('#'+row_id+' input').each(function(){if(this.id.indexOf('mac')>=0){cbi_validate_field(this.id,false,'macaddr');}
if(this.id.indexOf('ip')>=0){cbi_validate_field(this.id,false,'ip4addr');}});if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);return;}
return false;}
$(function(){$('#alert_up_max').hide();$("#table_arp_statictrust").hide();$("#btn_add").hide();if($(arpinspection_enable).is(":checked")){$(forcedhcp_row).show();$(trustlistbroadcast_row).show();$(statictrustlist_row).show();}
else{$(forcedhcp_row).hide();$(trustlistbroadcast_row).hide();$(statictrustlist_row).hide();}
if($(statictrust_enable).is(":checked")){$("#table_arp_statictrust").show();$("#btn_add").show();}
if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}
$('button.ace-tooltip').tooltip();$('button.disabled').click(function(){if(!$(this).hasClass('disabled')){$('.disabled').removeClass('disabled').attr('rel',null);$(this).addClass('disabled').attr('rel','tooltip');}});$(arpinspection_enable).change(function(){if(this.checked){$(forcedhcp_row).show();$(trustlistbroadcast_row).show();$(statictrustlist_row).show();if($(statictrust_enable).is(":checked")){$("#table_arp_statictrust").show();$("#btn_add").show();if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}}else{$("#table_arp_statictrust").hide();$("#btn_add").hide();$('#alert_up_max').hide();}}
else{$(forcedhcp_row).hide();$(trustlistbroadcast_row).hide();$(statictrustlist_row).hide();$(forcedhcp_enable).attr('checked',false);$(trustlistbroadcast_enable).attr('checked',false);$(statictrust_enable).attr('checked',false);$("#table_arp_statictrust").hide();$("#btn_add").hide();$('#alert_up_max').hide();}});$(statictrust_enable).change(function(){if(this.checked){$("#table_arp_statictrust").show();$("#btn_add").show();if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}}else{$("#table_arp_statictrust").hide();$("#btn_add").hide();$('#alert_up_max').hide();}});$('form').submit(function(){return true;});});