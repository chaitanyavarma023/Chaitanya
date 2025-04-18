
var user_row='<tr class="cbi-section-table-row" id="cbi-firewall-cfgCFG_ID">'
+' '
+'<td class="cbi-value-field">'
+'    <div id="cbi-firewall-cfgCFG_ID-enabled">'
+'        <input type="hidden" value="1" name="cbi.cbe.firewall.cfgCFG_ID.custom">'
+'        <input type="hidden" value="1" name="cbi.cbe.firewall.cfgCFG_ID.enabled">'
+'        <input title="" class="ace-tooltip ace-switch ace-switch-2 " onclick="cbi_d_update(this.id)" onchange="cbi_d_update(this.id)" '
+'       type="checkbox" id="cbid.firewall.cfgCFG_ID.enabled" name="cbid.firewall.cfgCFG_ID.enabled" value="1" checked="checked">'
+'        <span class="lbl">&nbsp;</span>'
+'    </div>'
+'    <div id="cbip-firewall-cfgCFG_ID-enabled"></div>'
+'</td>'
+' '
+'<td class="cbi-value-field"> '
+'    <div id="cbi-firewall-cfgCFG_ID-name"> '
+'        <input type="hidden" id="acn.new.cfgCFG_ID" name="acn.new.cfgCFG_ID" value="CFG_ID" /> '
+' '
+'        <input title="" type="text" class="ace-tooltip" name="cbid.firewall.cfgCFG_ID.name" '
+'   id="cbid.firewall.cfgCFG_ID.name" value="" style="width:100px" size="10"/>'
+'   '
+'    </div>'
+'    <div id="cbip-firewall-cfgCFG_ID-name"></div>'
+'</td>'
+' '
+'<td class="cbi-value-field">'
+'    <div id="cbi-firewall-cfgCFG_ID-proto">'
+'    '
+'        <select class="cbi-input-select" onchange="cbi_d_update(this.id)" id="cbid.firewall.cfgCFG_ID.proto" name="cbid.firewall.cfgCFG_ID.proto" size="1">'
+'            <option id="cbi-firewall-cfgCFG_ID-proto-tcp" value="tcp">TCP</option>'
+'            <option id="cbi-firewall-cfgCFG_ID-proto-udp" value="udp">UDP</option>'
+'            <option id="cbi-firewall-cfgCFG_ID-proto-tcpudp" value="tcpudp">TCP+UDP</option>'
+'        </select>'
+'    </div>'
+'    <div id="cbip-firewall-cfgCFG_ID-proto"></div>'
+'</td>'
+' '
+'<td class="cbi-value-field"> '
+'    <div id="cbi-firewall-cfgCFG_ID-src_dport"> '
+'        <input title="" type="text" class="ace-tooltip" data-field="portrange" name="cbid.firewall.cfgCFG_ID.src_dport" '
+'   id="cbid.firewall.cfgCFG_ID.src_dport" value="" onchange="cbi_d_update(this.id)" size="5" style="width:100px" />'
+'    </div>'
+'    <div id="cbip-firewall-cfgCFG_ID-src_dport"></div>'
+'</td>'
+' '
+'<td class="cbi-value-field"> '
+'    <div id="cbi-firewall-cfgCFG_ID-dest_ip"> '
+'          <input title="" type="text" class="ace-tooltip" data-field="ipaddr" name="cbid.firewall.cfgCFG_ID.dest_ip" '
+'   id="cbid.firewall.cfgCFG_ID.dest_ip" value="" onchange="cbi_d_update(this.id)" style="width:100px" />'
+'    </div>'
+'    <div id="cbip-firewall-cfgCFG_ID-dest_ip"></div>'
+'</td>'
+' '
+'<td class="cbi-value-field"> '
+'    <div id="cbi-firewall-cfgCFG_ID-dest_port"> '
+'        <input autocomplete="off" type="text" class="ace-tooltip" data-field="portrange" name="cbid.firewall.cfgCFG_ID.dest_port" '
+'            id="cbid.firewall.cfgCFG_ID.dest_port" value="" onchange="cbi_d_update(this.id)" size="5" style="width:100px" />'
+'    </div>'
+'    <div id="cbip-firewall-cfgCFG_ID-dest_port"></div>'
+'</td>'
+' '
+'<td class="cbi-section-table-cell" style="width:50px">'
+''
+'<input type="hidden" name="acn.del.firewall.cfgCFG_ID" id="acn.del.firewall.cfgCFG_ID" value="0">'
+'<button class="btn btn-info btn-mini btn-danger" data-new="1"  value="cfgCFG_ID"  '
+'onclick="removePortfwRow(this.id); return false;" '
+'name="cbi.rts.firewall.cfgCFG_ID" id="cbi.rts.firewall.cfgCFG_ID" alt="Delete"'
+' title="Delete"><i class="icon-trash"></i></button>     '
+'';var add_user_counter=0;function removePortfwRow(btn){btn=btn.replace(/\./g,'\\.');var $btn=$('#'+btn);var value=$btn.attr('value');if($btn.hasClass('disabled')){return;}
var id='acn\\.del\\.firewall\\.'+value;$('#'+id).attr('value',1);$('#cbi-firewall-'+value).fadeOut();if($btn.data('new')==='1'){$('#cbi-firewall-'+value).remove();}
$('#cbi-firewall-'+value+' input').attr('deleted','deleted');if(getVisibleRowCount(-1)<=max_count){$('#alert_up_max').hide();$('#btn_add').attr('disabled',false);}}
function getVisibleRowCount(row_offset){var offset=row_offset;if(offset===undefined){offset=-2;}
var len=$('#table_portfw tr:visible').length+offset;return len;}
var arp_select_option='';var js_arp_option='';function generate_arp_ip_option(){arp_select_option='';js_arp_option='';var _list_length=arp_ip_list.length;if(_list_length<=0){return;}
for(var i=0;i<_list_length;i++){var _val=arp_ip_list[i];arp_select_option+='<option value="'+_val+'">'+_val+'</option>';if(js_arp_option!==''){js_arp_option+=',';}
js_arp_option+='"'+_val+'":"'+_val+'"';}}
function addPortfwRow(){var name='#table_portfw';$(name+'_row_empty').hide();var cfg_id=add_user_counter;add_user_counter++;var row=user_row.replace(/CFG_ID/g,cfg_id);row=row.replace(/arp_select_option/g,arp_select_option);row=row.replace(/js_arp_option/g,js_arp_option);row=$.parseHTML(row);if($(name+' tr').length>0){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
var row_id='cbi-firewall-cfg'+cfg_id;$('#'+row_id+' input').change(function(){cbi_d_update(this.id);});$('#'+row_id+' input').tooltip();$('#'+row_id+' input').each(function(){if($(this).attr('type')==='text'&&this.id.indexOf('CFG_ID')<0){if(this.id.indexOf('name')>=0){cbi_validate_field(this.id,false,'limited_len_str(1, 30)');$(this).data('field','limited_len_str(1, 30)');}
if(this.id.indexOf('src_dport')>=0){cbi_validate_field(this.id,false,'portrange');}
if(this.id.indexOf('dest_port')>=0){cbi_validate_field(this.id,false,'portrange');}
if(this.id.indexOf('dest_ip')>=0){cbi_validate_field(this.id,false,'firewall_ipaddr');}}});if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);return;}
return false;}
$(function(){$('#alert_up_max').hide();if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}
$('.cbi-value-field input').each(function(){if(this.id.indexOf('CFG_ID')>=0){return;}
if(this.id.indexOf('name')>=0){cbi_validate_field(this.id,false,'limited_len_str(1, 30)');$(this).data('field','limited_len_str(1, 30)');}
if(this.id.indexOf('src_dport')>=0){cbi_validate_field(this.id,false,'portrange');}
if(this.id.indexOf('dest_port')>=0){cbi_validate_field(this.id,false,'portrange');}
if(this.id.indexOf('dest_ip')>=0){cbi_validate_field(this.id,false,'firewall_ipaddr');}});$('button.ace-tooltip').tooltip();$('button.disabled').click(function(){if(!$(this).hasClass('disabled')){$('.disabled').removeClass('disabled').attr('rel',null);$(this).addClass('disabled').attr('rel','tooltip');}});$('form').submit(function(){return true;});generate_arp_ip_option();});