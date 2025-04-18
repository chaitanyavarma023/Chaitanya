
var user_row='<tr class="cbi-section-table-row" id="cbi-firewall-cfgCFG_ID">'
+' '
+'    <td class="cbi-value-field">'
+'        <div id="cbi-firewall-cfgCFG_ID-enabled">'
+'        <input type="hidden" value="1" name="cbi.cbe.firewall.cfgCFG_ID.custom">'
+'            <input type="hidden" value="1" name="cbi.cbe.firewall.cfgCFG_ID.enabled" />'
+'            <input title="" class="ace-tooltip ace-switch ace-switch-2 "'
+'            onclick="cbi_d_update(this.id)"'
+'            onchange="cbi_d_update(this.id)" type="checkbox" id="cbid.firewall.cfgCFG_ID.enabled" name="cbid.firewall.cfgCFG_ID.enabled" value="1" checked/>'
+'            <span class="lbl">&nbsp;</span>'
+'        </div>'
+'        <div id="cbip-firewall-cfgCFG_ID-enabled"></div>'
+'    </td>'
+' '
+'    <td class="cbi-value-field">'
+'        <div id="cbi-firewall-cfgCFG_ID-name">'
+'            <input type="hidden" id="acn.new.cfgCFG_ID" name="acn.new.cfgCFG_ID" value="CFG_ID" /> '
+' '
+'            <input style="width:79px" title="" autocomplete="off" type="text" class="ace-tooltip"'
+'            onchange="cbi_d_update(this.id)" name="cbid.firewall.cfgCFG_ID.name" id="cbid.firewall.cfgCFG_ID.name" value="" />'
+'        </div>'
+'        <div id="cbip-firewall-cfgCFG_ID-name"></div>'
+'    </td>'
+''
+'    <td class="cbi-value-field">'
+'        <div id="cbi-firewall-cfgCFG_ID-target">'
+'            <select style="width:100px" class="cbi-input-select" onchange="cbi_d_update(this.id)" id="cbid.firewall.cfgCFG_ID.target" name="cbid.firewall.cfgCFG_ID.target" size="1">'
+'                <option id="cbi-firewall-cfgCFG_ID-target-ACCEPT" value="ACCEPT" selected="selected">ACCEPT</option>'
+'                <option id="cbi-firewall-cfgCFG_ID-target-REJECT" value="REJECT">REJECT</option>'
+'                <option id="cbi-firewall-cfgCFG_ID-target-DROP" value="DROP">DROP</option>'
+'            </select>'
+'        </div>'
+'        <div id="cbip-firewall-cfgCFG_ID-target"></div>'
+'    </td>'
+''
+'    <td class="cbi-value-field">'
+'        <div id="cbi-firewall-cfgCFG_ID-family">'
+'            <select style="width:63px" class="cbi-input-select" onchange="cbi_d_update(this.id)" id="cbid.firewall.cfgCFG_ID.family" name="cbid.firewall.cfgCFG_ID.family" size="1">'
+'                <option id="cbi-firewall-cfgCFG_ID-family-any" value="any" selected="selected">'+_("Any")+'</option>'
+'                <option id="cbi-firewall-cfgCFG_ID-family-ipv4" value="ipv4">ipv4</option>'
+'                <option id="cbi-firewall-cfgCFG_ID-family-ipv6" value="ipv6">ipv6</option>'
+'            </select>'
+'        </div>'
+'        <div id="cbip-firewall-cfgCFG_ID-family"></div>'
+'    </td>'
+''
+'    <td class="cbi-value-field">'
+'        <div id="cbi-firewall-cfgCFG_ID-src">'
+'            <select style="width:72px" class="cbi-input-select" onchange="cbi_d_update(this.id)" id="cbid.firewall.cfgCFG_ID.src" name="cbid.firewall.cfgCFG_ID.src" size="1">'
+'                <option id="cbi-firewall-cfgCFG_ID-dest-empty" value="">'+_("Any")+'</option>'
+'                zone_select_option'
+'            </select>'
+'        </div>'
+'        <div id="cbip-firewall-cfgCFG_ID-src"></div>'
+'    </td>'
+''
+'    <td class="cbi-value-field">'
+'        <div id="cbi-firewall-cfgCFG_ID-src_ip">'
+'            <input  title="" autocomplete="off" type="text" class="ace-tooltip"'
+'            data-rel="tooltip" onchange="cbi_d_update(this.id)" name="cbid.firewall.cfgCFG_ID.src_ip" id="cbid.firewall.cfgCFG_ID.src_ip" value="" />'
+'            <script type="text/javascript">'
+'                cbi_validate_field("cbid.firewall.cfgCFG_ID.src_ip", true, "firewall_ipaddr");'
+'            </script>'
+'        </div>'
+'        <div id="cbip-firewall-cfgCFG_ID-src_ip"></div>'
+'    </td>'
+''
+'    <td class="cbi-value-field">'
+'        <div id="cbi-firewall-cfgCFG_ID-src_port">'
+'            <input title="" autocomplete="off" type="text" class="ace-tooltip"'
+'            data-rel="tooltip" onchange="cbi_d_update(this.id)" name="cbid.firewall.cfgCFG_ID.src_port" id="cbid.firewall.cfgCFG_ID.src_port" value="" />'
+'            <script type="text/javascript">'
+'                cbi_validate_field("cbid.firewall.cfgCFG_ID.src_port", true, "portrange");'
+'            </script>'
+'        </div>'
+'        <div id="cbip-firewall-cfgCFG_ID-src_port"></div>'
+'    </td>'
+''
+'    <td class="cbi-value-field">'
+'        <div id="cbi-firewall-cfgCFG_ID-proto">'
+'            <select style="width:96px" class="cbi-input-select" onchange="change_proto(this.value, CFG_ID)" id="cbid.firewall.cfgCFG_ID.proto" name="cbid.firewall.cfgCFG_ID.proto" size="1">'
+'                <option id="cbi-firewall-cfgCFG_ID-proto-all" value="all">'+_("Any")+'</option>'
+'                <option id="cbi-firewall-cfgCFG_ID-proto-tcpudp" value="tcpudp" selected>TCP+UDP</option>'
+'                <option id="cbi-firewall-cfgCFG_ID-proto-tcp" value="tcp">TCP</option>'
+'                <option id="cbi-firewall-cfgCFG_ID-proto-udp" value="udp">UDP</option>'
+'                <option id="cbi-firewall-cfgCFG_ID-proto-icmp" value="icmp">ICMP</option>'
+'            </select>'
+'        </div>'
+'        <div id="cbip-firewall-cfgCFG_ID-proto"></div>'
+'    </td>'
+''
+'    <td class="cbi-value-field">'
+'        <div id="cbi-firewall-cfgCFG_ID-dest">'
+'            <select style="width:72px" class="cbi-input-select" onchange="cbi_d_update(this.id)" id="cbid.firewall.cfgCFG_ID.dest" name="cbid.firewall.cfgCFG_ID.dest" size="1">'
+'                <option id="cbi-firewall-cfgCFG_ID-dest-empty" value="">'+_("Any")+'</option>'
+'                zone_select_option'
+'            </select>'
+'        </div>'
+'        <div id="cbip-firewall-cfgCFG_ID-dest"></div>'
+'    </td>'
+''
+'    <td class="cbi-value-field">'
+'        <div id="cbi-firewall-cfgCFG_ID-dest_ip">'
+'            <input  title="" autocomplete="off" type="text" class="ace-tooltip"'
+'            data-rel="tooltip" onchange="cbi_d_update(this.id)" name="cbid.firewall.cfgCFG_ID.dest_ip" id="cbid.firewall.cfgCFG_ID.dest_ip" value=""/>'
+'            <script type="text/javascript">'
+'                cbi_validate_field("cbid.firewall.cfgCFG_ID.dest_ip", true, "firewall_ipaddr");'
+'            </script>'
+'        </div>'
+'        <div id="cbip-firewall-cfgCFG_ID-dest_ip"></div>'
+'    </td>'
+''
+'    <td class="cbi-value-field">'
+'        <div id="cbi-firewall-cfgCFG_ID-dest_port">'
+'            <input style="width:85px" title="" autocomplete="off" type="text" class="ace-tooltip"'
+'            data-rel="tooltip" onchange="cbi_d_update(this.id)" name="cbid.firewall.cfgCFG_ID.dest_port" id="cbid.firewall.cfgCFG_ID.dest_port" value="" />'
+'            <script type="text/javascript">'
+'                cbi_validate_field("cbid.firewall.cfgCFG_ID.dest_port", true, "portrange");'
+'            </script>'
+'        </div>'
+'        <div id="cbip-firewall-cfgCFG_ID-dest_port"></div>'
+'    </td>'
+''
+' '
+'<td class="cbi-section-table-cell" style="width:50px">'
+''
+'<input type="hidden" name="acn.del.firewall.cfgCFG_ID" id="acn.del.firewall.cfgCFG_ID" value="0">'
+'<button class="btn btn-info btn-mini btn-danger" data-new="1"  value="cfgCFG_ID"  '
+'onclick="removeRuleRow(this.id); return false;" '
+'name="cbi.rts.firewall.cfgCFG_ID" id="cbi.rts.firewall.cfgCFG_ID" alt="Delete"'
+' title="Delete"><i class="icon-trash"></i></button>     '
+'';var add_user_counter=0;function removeRuleRow(btn){btn=btn.replace(/\./g,'\\.');var $btn=$('#'+btn);var value=$btn.attr('value');if($btn.hasClass('disabled')){return;}
var id='acn\\.del\\.firewall\\.'+value;$('#'+id).attr('value',1);$('#cbi-firewall-'+value).fadeOut();if($btn.data('new')==='1'){$('#cbi-firewall-'+value).remove();}
$('#cbi-firewall-'+value+' input').attr('deleted','deleted');if(getVisibleRowCount(-1)<=max_count){$('#alert_up_max').hide();$('#btn_add').attr('disabled',false);}}
function getVisibleRowCount(row_offset){var offset=row_offset;if(offset===undefined){offset=-2;}
var len=$('#table_rule tr:visible').length+offset;return len;}
var zone_select_option='';function generate_zone_option(){zone_select_option='';var _list_length=zone_value_list.length;if(_list_length<=0){return;}
for(var i=0;i<_list_length;i++){var _val=zone_value_list[i];var _name=zone_name_list[i];zone_select_option+='<option id="cbi-firewall-cfgCFG_ID-src-'+_val+'" value="'+_val+'">'+_name+'</option>\n';}}
function addRuleRow(){var name='#table_rule';$(name+'_row_empty').hide();var cfg_id=add_user_counter;add_user_counter++;var row=user_row.replace(/CFG_ID/g,cfg_id);row=row.replace(/zone_select_option/g,zone_select_option);row=$.parseHTML(row);if($(name+' tr').length>0){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
if(!is_support_ipv6){$('#cbi-firewall-cfg'+cfg_id+'-family-ipv6').hide();}
var row_id='cbi-firewall-cfg'+cfg_id;$('#'+row_id+' input').change(function(e,data){cbi_d_update(this.id);});$('#'+row_id+' input').tooltip();$('#'+row_id+' input').each(function(){if($(this).attr('type')==='text'&&this.id.indexOf('CFG_ID')<0){if(this.id.indexOf('name')>=0){cbi_validate_field(this.id,false,'limited_len_str(1, 30)');$(this).data('field','limited_len_str(1, 30)');}
if(this.id.indexOf('src_port')>=0){cbi_validate_field(this.id,true,'portrange');}
if(this.id.indexOf('dest_port')>=0){cbi_validate_field(this.id,true,'portrange');}
if(this.id.indexOf('src_ip')>=0){var id_arr=this.id.split('.');var src_ip_id='#'+id_arr[0]+'\\.'+id_arr[1]+'\\.'+id_arr[2]+'\\.'+id_arr[3];$(src_ip_id).change(function(){ip_change(this.id);});ip_change(this.id);}
if(this.id.indexOf('dest_ip')>=0){var id_arr=this.id.split('.');var dest_ip_id='#'+id_arr[0]+'\\.'+id_arr[1]+'\\.'+id_arr[2]+'\\.'+id_arr[3];$(dest_ip_id).change(function(){ip_change(this.id);});ip_change(this.id);}}});$('.cbi-value-field select').each(function(select){if(this.id.indexOf('family')>=0){var id_arr=this.id.split('.');var family_id='#'+id_arr[0]+'\\.'+id_arr[1]+'\\.'+id_arr[2]+'\\.'+id_arr[3];$(family_id).change(function(){ip_change(this.id);});ip_change(this.id);}});$('#'+row_id+' select').change(function(e,data){cbi_d_update(this.id);});if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);return;}
return false;}
function change_proto(val,section_id){var src_port_id='#cbid\\.firewall\\.cfg'+section_id+'\\.src_port';var dest_port_id='#cbid\\.firewall\\.cfg'+section_id+'\\.dest_port';if(val==='tcp'||val==='udp'||val==='tcpudp'){$(src_port_id).show();$(dest_port_id).show();}else{$(src_port_id).hide();$(dest_port_id).hide();}}
function ip_change(_id){var flag_src_ip=true;var flag_dest_ip=true;var id_arr=_id.split('.');var family_id='#'+id_arr[0]+'\\.'+id_arr[1]+'\\.'+id_arr[2]+'\\.family';var family_value=$(family_id).val();var src_ip_id='#'+id_arr[0]+'\\.'+id_arr[1]+'\\.'+id_arr[2]+'\\.src_ip';var dest_ip_id='#'+id_arr[0]+'\\.'+id_arr[1]+'\\.'+id_arr[2]+'\\.dest_ip';var src_ip_value=$(src_ip_id).val();var dest_ip_value=$(dest_ip_id).val();clear_validate_error(src_ip_id);clear_validate_error(dest_ip_id);if(family_value==='any'){if(is_support_ipv6){if(src_ip_value!==''&&!cbi_validators.firewall_ipaddr(src_ip_value)){set_err_msg($(src_ip_id),true,_('Not a valid IP address!'));flag_src_ip=false;}
if(dest_ip_value!==''&&!cbi_validators.firewall_ipaddr(dest_ip_value)){set_err_msg($(dest_ip_id),true,_('Not a valid IP address!'));flag_dest_ip=false;}}else{if(src_ip_value!==''&&!cbi_validators.firewall_ipv4(src_ip_value)){set_err_msg($(src_ip_id),true,_('Not a valid IPv4 address!'));flag_src_ip=false;}
if(dest_ip_value!==''&&!cbi_validators.firewall_ipv4(dest_ip_value)){set_err_msg($(dest_ip_id),true,_('Not a valid IPv4 address!'));flag_dest_ip=false;}}}else if(family_value==='ipv4'){if(src_ip_value!==''&&!cbi_validators.firewall_ipv4(src_ip_value)){set_err_msg($(src_ip_id),true,_('Not a valid IPv4 address!'));flag_src_ip=false;}
if(dest_ip_value!==''&&!cbi_validators.firewall_ipv4(dest_ip_value)){set_err_msg($(dest_ip_id),true,_('Not a valid IPv4 address!'));flag_dest_ip=false;}}else{if(src_ip_value!==''&&!cbi_validators.ip6addr(src_ip_value)){set_err_msg($(src_ip_id),true,_('Not a valid IPv6 address!'));flag_src_ip=false;}
if(dest_ip_value!==''&&!cbi_validators.ip6addr(dest_ip_value)){set_err_msg($(dest_ip_id),true,_('Not a valid IPv6 address!'));flag_dest_ip=false;}}
return(flag_src_ip&&flag_dest_ip);}
function setReadOnlyOnSelect(selectList){if(!selectList.length){console.warn(_('Unable to find specified select list.'));return;}
var input=$('<input />',{type:'hidden',name:selectList.attr('name'),value:selectList.val()});selectList.attr('disabled',true).before(input);}
function validate_form(){var flag_src_ip=true;var flag_dest_ip=true;$('.cbi-value-field input').each(function(input){if(this.id.indexOf('CFG_ID')>=0){return;}
if($(this).attr('deleted')==='deleted'){return;}
if(this.id.indexOf('src_ip')>=0){var id_arr=this.id.split('.');var src_ip_id='#'+id_arr[0]+'\\.'+id_arr[1]+'\\.'+id_arr[2]+'\\.'+id_arr[3];if(!ip_change(this.id)){flag_src_ip=false;}}
if(this.id.indexOf('dest_ip')>=0){var id_arr=this.id.split('.');var dest_ip_id='#'+id_arr[0]+'\\.'+id_arr[1]+'\\.'+id_arr[2]+'\\.'+id_arr[3];if(!ip_change(this.id)){flag_dest_ip=false;}}});return flag_src_ip||flag_dest_ip;}
$(function(){$('#cbi').submit(function(){if(!validate_form()){cbi_show_form_error();window.document.body.scrollTop=0;window.document.documentElement.scrollTop=0;return false;}else{return true;}});$('#alert_up_max').hide();if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}else{$('#btn_add').attr('disabled',false);}
if(fw_alert){$('#firewall_msg_placeholder').removeClass('hide');}
$('.cbi-value-field input').each(function(input){if(this.id.indexOf('CFG_ID')>=0){return;}
if(this.id.indexOf('name')>=0){cbi_validate_field(this.id,false,'limited_len_str(1, 30)');$(this).data('field','limited_len_str(1, 30)');var id_arr=this.id.split('.');var item_arr=new Array('name','target','family','src','src_ip','src_port','proto','dest','dest_ip','dest_port');for(var i=0;i<item_arr.length;i++){var disable_obj='#cbid\\.firewall\\.'+id_arr[2]+'\\.'+item_arr[i];if(this.value==='Allow-Ping'){setReadOnlyOnSelect($(disable_obj));$('#cbi\\.rts\\.firewall\\.'+id_arr[2]).attr('disabled','disabled');}else{$(disable_obj).removeAttr('disabled');}}}
if(this.id.indexOf('src_port')>=0){cbi_validate_field(this.id,true,'portrange');}
if(this.id.indexOf('dest_port')>=0){cbi_validate_field(this.id,true,'portrange');}
if(this.id.indexOf('src_ip')>=0){var id_arr=this.id.split('.');var src_ip_id='#'+id_arr[0]+'\\.'+id_arr[1]+'\\.'+id_arr[2]+'\\.'+id_arr[3];$(src_ip_id).change(function(){ip_change(this.id);});ip_change(this.id);}
if(this.id.indexOf('dest_ip')>=0){var id_arr=this.id.split('.');var dest_ip_id='#'+id_arr[0]+'\\.'+id_arr[1]+'\\.'+id_arr[2]+'\\.'+id_arr[3];$(dest_ip_id).change(function(){ip_change(this.id);});ip_change(this.id);}});$('.cbi-value-field select').each(function(select){if(this.id.indexOf('proto')>=0){var id_arr=this.id.split('.');var custom_id='#'+id_arr[0]+'\\.'+id_arr[1]+'\\.'+id_arr[2]+'\\.'+'custom';if($(custom_id).val()){var esp_id='#cbi-'+id_arr[1]+'-'+id_arr[2]+'-proto-esp';$(esp_id).css('display','none');var igmp_id='#cbi-'+id_arr[1]+'-'+id_arr[2]+'-proto-igmp';$(igmp_id).css('display','none');}}
if(this.id.indexOf('family')>=0){var id_arr=this.id.split('.');var family_id='#'+id_arr[0]+'\\.'+id_arr[1]+'\\.'+id_arr[2]+'\\.'+id_arr[3];$(family_id).change(function(){ip_change(this.id);});ip_change(this.id);}});$('button.ace-tooltip').tooltip();$('button.disabled').click(function(e){if(!$(this).hasClass('disabled')){$('.disabled').removeClass('disabled').attr('rel',null);$(this).addClass('disabled').attr('rel','tooltip');}});$('form').submit(function(){return true;});generate_zone_option();if(!is_support_ipv6){$('.cbi-input-select').children('option[value="ipv6"]').hide();}});