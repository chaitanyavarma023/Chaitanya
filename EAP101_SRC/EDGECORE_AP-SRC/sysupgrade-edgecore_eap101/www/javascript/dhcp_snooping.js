
var dhcp_row='<tr class="cbi-section-table-row" id="cbi-trustdhcpserver-cfgCFG_ID">'
+' '
+'    <td class="cbi-value-field">'
+'        <div id="cbi-trustdhcpserver-cfgCFG_ID-mac">'
+'        <input type="hidden" id="acn.new.cfgCFG_ID" name="acn.new.cfgCFG_ID" value="CFG_ID" />'
+'            <input  title="" autocomplete="off" type="text" class="ace-tooltip"'
+'            onchange="cbi_d_update(this.id)" name="cbid.trustdhcpserver.cfgCFG_ID.mac" id="cbid.trustdhcpserver.cfgCFG_ID.mac" value="" />'
+'            <script type="text/javascript">'
+'                cbi_validate_field("cbid.trustdhcpserver.cfgCFG_ID.mac", true, "macaddr");'
+'            </script>'
+'        </div>'
+'        <div id="cbip-trustdhcpserver-cfgCFG_ID-mac"></div>'
+'    </td>'
+''
+'    <td class="cbi-value-field">'
+'        <div id="cbi-trustdhcpserver-cfgCFG_ID-ip">'
+'            <input  title="" autocomplete="off" type="text" class="ace-tooltip"'
+'            onchange="cbi_d_update(this.id)" name="cbid.trustdhcpserver.cfgCFG_ID.ip" id="cbid.trustdhcpserver.cfgCFG_ID.ip" value="" />'
+'            <script type="text/javascript">'
+'                cbi_validate_field("cbid.trustdhcpserver.cfgCFG_ID.ip", true, "firewall_ipaddr");'
+'            </script>'
+'        </div>'
+'        <div id="cbip-trustdhcpserver-cfgCFG_ID-ip"></div>'
+'    </td>'
+''
+'    <td class="cbi-value-field">'
+'        <div id="cbi-trustdhcpserver-cfgCFG_ID-remark">'
+'            <input  title="" autocomplete="off" type="text" class="ace-tooltip"'
+'            onchange="cbi_d_update(this.id)" name="cbid.trustdhcpserver.cfgCFG_ID.remark" id="cbid.trustdhcpserver.cfgCFG_ID.remark" value="" />'
+'            <script type="text/javascript">'
+'                cbi_validate_field("cbid.trustdhcpserver.cfgCFG_ID.remark", true, "");'
+'            </script>'
+'        </div>'
+'        <div id="cbip-trustdhcpserver-cfgCFG_ID-remark"></div>'
+'    </td>'
+''
+'<td class="cbi-section-table-cell" style="width:50px">'
+''
+'<input type="hidden" name="acn.del.trustdhcpserver.cfgCFG_ID" id="acn.del.trustdhcpserver.cfgCFG_ID" value="0">'
+'<button class="btn btn-info btn-mini btn-danger" data-new="1"  value="cfgCFG_ID"  '
+'onclick="removeDHCPServerRow(this.id); return false;" '
+'name="cbi.rts.trustdhcpserver.cfgCFG_ID" id="cbi.rts.trustdhcpserver.cfgCFG_ID" alt="Delete"'
+' title="Delete"><i class="icon-trash"></i></button>     '
+'';var add_user_counter=0;var enable="[id*='dhcpsnooping_enable'][type='checkbox']"
function removeDHCPServerRow(btn){btn=btn.replace(/\./g,'\\.');var $btn=$('#'+btn);var value=$btn.attr('value');if($btn.hasClass('disabled')){return;}
var id='acn\\.del\\.trustdhcpserver\\.'+value;$('#'+id).attr('value',1);$('#cbi-trustdhcpserver-'+value).fadeOut();if($btn.data('new')==='1'){$('#cbi-trustdhcpserver-'+value).remove();}
$('#cbi-trustdhcpserver-'+value+' input').attr('deleted','deleted');if(getVisibleRowCount(-1)<=max_count){$('#alert_up_max').hide();$('#btn_add').attr('disabled',false);}}
function getVisibleRowCount(row_offset){var offset=row_offset;if(offset===undefined){offset=-2;}
var len=$('#table_dhcp_snooping tr:visible').length+offset;return len;}
function addDHCPServerRow(){var name='#table_dhcp_snooping';$(name+'_row_empty').hide();var cfg_id=add_user_counter;add_user_counter++;var row=dhcp_row.replace(/CFG_ID/g,cfg_id);row=$.parseHTML(row);if($(name+' tr').length>0){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
var row_id='cbi-trustdhcpserver-cfg'+cfg_id;$('#'+row_id+' input').change(function(e,data){cbi_d_update(this.id);});$('#'+row_id+' input').each(function(){if(this.id.indexOf('mac')>=0){cbi_validate_field(this.id,false,'macaddr');}
if(this.id.indexOf('ip')>=0){cbi_validate_field(this.id,false,'ip4addr');}});if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);return;}
return false;}
$(function(){$('#alert_up_max').hide();$("#table_dhcp_snooping").hide();$("#btn_add").hide();var is_enable=$(enable).is(":checked");if(is_enable){$("#table_dhcp_snooping").show();$("#btn_add").show();}
if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}
$('button.ace-tooltip').tooltip();$('button.disabled').click(function(){if(!$(this).hasClass('disabled')){$('.disabled').removeClass('disabled').attr('rel',null);$(this).addClass('disabled').attr('rel','tooltip');}});$(enable).change(function(){if(this.checked){$("#table_dhcp_snooping").show();$("#btn_add").show();if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}}else{$("#table_dhcp_snooping").hide();$("#btn_add").hide();$('#alert_up_max').hide();}});$('form').submit(function(){return true;});});