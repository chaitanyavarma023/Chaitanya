
var capwap_row='<tr class="cbi-section-table-row" id="cbi-acn-cfgCFG_ID">'
+' '
+'    <td class="cbi-value-field">'
+'        <div id="cbi-acn-cfgCFG_ID-ip">'
+'            <input type="hidden" id="acn.new.cfgCFG_ID" name="acn.new.cfgCFG_ID" value="CFG_ID" />'
+'                <input  title="" autocomplete="off" type="text" class="ace-tooltip"'
+'                onchange="cbi_d_update(this.id)" name="cbid.acn.cfgCFG_ID.ip" id="cbid.acn.cfgCFG_ID.ip" value="" />'
+'                <script type="text/javascript">'
+'                    cbi_validate_field("cbid.acn.cfgCFG_ID.ip", true, "ipaddr");'
+'                </script>'
+'        </div>'
+'        <div id="cbip-acn-cfgCFG_ID-ip"></div>'
+'    </td>'
+''
+'    <td class="cbi-value-field">'
+'        <div id="cbi-acn-cfgCFG_ID-remark">'
+'            <input  title="" autocomplete="off" type="text" class="ace-tooltip"'
+'            onchange="cbi_d_update(this.id)" name="cbid.acn.cfgCFG_ID.remark" id="cbid.acn.cfgCFG_ID.remark" value="" />'
+'            <script type="text/javascript">'
+'                cbi_validate_field("cbid.acn.cfgCFG_ID.remark", true, "");'
+'            </script>'
+'        </div>'
+'        <div id="cbip-acn-cfgCFG_ID-remark"></div>'
+'    </td>'
+''
+'<td class="cbi-section-table-cell" style="width:50px">'
+''
+'<input type="hidden" name="acn.del.acn.cfgCFG_ID" id="acn.del.acn.cfgCFG_ID" value="0">'
+'<button class="btn btn-info btn-mini btn-danger" data-new="1"  value="cfgCFG_ID" '
+'onclick="removeCAPWAPRow(this.id); return false;" '
+'name="cbi.rts.acn.cfgCFG_ID" id="cbi.rts.acn.cfgCFG_ID" alt="Delete"'
+' title="Delete"><i class="icon-trash"></i></button> '
+'';var add_user_counter=0;var capwap_all_id="div[id*='cbi-acn-capwap-']";var mgmt_en_id='#cbid\\.acn\\.mgmt\\.enabled';var reg_url_pid="#cbi-acn-register-url";var reg_url_id="input[name='cbid.acn.register.url']";var capwap_status_id='#cbid\\.acn\\.capwap\\.state';var dns_srv_id='#cbid\\.acn\\.capwap\\.dns_srv';var dhcp_opt_id='#cbid\\.acn\\.capwap\\.dhcp_opt';var broadcast_id='#cbid\\.acn\\.capwap\\.broadcast';var multicast_id='#cbid\\.acn\\.capwap\\.multicast';var unicast_id='#cbid\\.acn\\.capwap\\.unicast';var srv_suffix_pid="#cbi-acn-capwap-srv_suffix";var srv_suffix_id="input[name='cbid.acn.capwap.srv_suffix']";var tbl_sel="select[id*='management']";function getVisibleRowCount(row_offset){var offset=row_offset;if(offset===undefined){offset=-2;}
var len=$('#table_capwap_ac tr:visible').length+offset;return len;}
function removeCAPWAPRow(btn){btn=btn.replace(/\./g,'\\.');var $btn=$('#'+btn);var value=$btn.attr('value');if($btn.hasClass('disabled')){return;}
var id='acn\\.del\\.acn\\.'+value;$('#'+id).attr('value',1);$('#cbi-acn-'+value).fadeOut();if($btn.data('new')=='1'){$('#cbi-acn-'+value).remove();}
$('#cbi-acn-'+value+' input').attr('deleted','deleted');if(getVisibleRowCount(-1)<=max_count){$('#alert_up_max').hide();$('#btn_add').attr('disabled',false);}}
function addCAPWAPRow(){var name='#table_capwap_ac';$(name+'_row_empty').hide();var cfg_id=add_user_counter;add_user_counter++;var row=capwap_row.replace(/CFG_ID/g,cfg_id);row=$.parseHTML(row);if($(name+' tr').length>0){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
var row_id='cbi-acn-cfg'+cfg_id;$('#'+row_id+' input').change(function(e,data){cbi_d_update(this.id);});$('#'+row_id+' input').each(function(){if(this.id.indexOf('ip')>=0){cbi_validate_field(this.id,false,'ipaddr');}});if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);return;}
return false;}
function validateCAPWAP(){var managment=$(tbl_sel).val();var capwap_enable=$(capwap_status_id).is(':checked');var dns_srv_enable=$(dns_srv_id).is(':checked');var dhcp_opt_enable=$(dhcp_opt_id).is(':checked');var broadcast_enable=$(broadcast_id).is(':checked');var multicast_enable=$(multicast_id).is(':checked');var unicast_enable=$(unicast_id).is(':checked');var srv_suffix=$(srv_suffix_id).val();clear_validate_error(srv_suffix_id);if(managment=="2"){if(dns_srv_enable){if(typeof srv_suffix!=="undefined"&&srv_suffix!==''&&!isValidDomain(srv_suffix)){set_err_msg($(srv_suffix_id),true,_('Domain name suffix is invalid.'));return false;}}
var error=0;var has_v4=0;var has_v6=0;var is_v4=false;var is_v6=false;$("#table_capwap_ac").find("input[id*='ip'][deleted!=deleted]").each(function(){is_v4=is_ip(this.value,ZERO_NO);is_v6=is_ipv6(this.value);if(!is_v4&&!is_v6){set_err_msg($(this),true,_('Not a valid IP address!'));error=1;return false;}
if(is_v4){has_v4=1;}
if(is_v6){has_v6=1;}
if(has_v4&&has_v6){set_err_msg($(this),true,_('Should be all IPv4 address or IPv6 address!'));error=1;return false;}});if(error==1){return false;}
if(capwap_enable){if((dns_srv_enable||dhcp_opt_enable||broadcast_enable||multicast_enable||unicast_enable)==0){alert(_("At least one of the Discovery should be enabled if CAPWAP is ON!"));set_err_msg($(capwap_status_id),true,'');return false;}}}
return true;}
function validate_form(){var res_capwap=validateCAPWAP();var res=(res_capwap);if(!res){cbi_show_form_error();res=false;}
return res;}
function before_submit(){var ac_addr={};var duplicates=false;$("#table_capwap_ac").find("input[id*='ip'][deleted!=deleted]").each(function(){var ip_addr=$(this).val();if(ac_addr[ip_addr]==ip_addr){duplicates=true;return;}
ac_addr[ip_addr]=ip_addr;});if(duplicates){$('#form_error_msg_placeholder').show();$('#form_error_msg').text('Duplicate IP addresses have been found! Please fix this issue before continuing.');return false;}
if(!validate_form()){cbi_show_form_error();return false;}else{return true;}}
$(function(){$('#alert_up_max').hide();$("#table_capwap_ac").hide();$("#btn_add").hide();$(reg_url_id).prop('readonly',true);if($(mgmt_en_id).is(':checked')){$(reg_url_pid).show();}
if($(tbl_sel).val()=="2"){$(capwap_all_id).show();if(!$(dns_srv_id).is(':checked')){$(srv_suffix_pid).hide();$(srv_suffix_id).val("");}
$("#table_capwap_ac").show();$("#btn_add").show();}
if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}
$('button.ace-tooltip').tooltip();$('button.disabled').click(function(){if(!$(this).hasClass('disabled')){$('.disabled').removeClass('disabled').attr('rel',null);$(this).addClass('disabled').attr('rel','tooltip');}});$(mgmt_en_id).change(function(){if($(this).is(':checked')){$(reg_url_pid).show();}
else{$(reg_url_pid).hide();}});$(dns_srv_id).change(function(){if($(this).is(':checked')){$(srv_suffix_pid).show();}
else{$(srv_suffix_pid).hide();}});$(tbl_sel).change(function(){$(reg_url_pid).hide();$(capwap_all_id).hide();$("#table_capwap_ac").hide();$("#btn_add").hide();$('#alert_up_max').hide();if(this.value=="0"||this.value=="3"){$(capwap_status_id).prop('checked',false);$(dns_srv_id).prop('checked',false);$(dhcp_opt_id).prop('checked',false);$(broadcast_id).prop('checked',false);$(multicast_id).prop('checked',false);}
else if(this.value=="1"){$(mgmt_en_id).change();$(capwap_status_id).prop('checked',false);$(dns_srv_id).prop('checked',false);$(dhcp_opt_id).prop('checked',false);$(broadcast_id).prop('checked',false);$(multicast_id).prop('checked',false);}
else if(this.value=="2"){$(capwap_all_id).show();$(capwap_status_id).prop('checked',true);$(dns_srv_id).prop('checked',true);$(dhcp_opt_id).prop('checked',true);$(broadcast_id).prop('checked',true);$(multicast_id).prop('checked',true);$(capwap_status_id).val('1');$(dns_srv_id).val('1');$(dhcp_opt_id).val('1');$(broadcast_id).val("255.255.255.255");$(multicast_id).val("224.0.1.140");if(!$(dns_srv_id).is(':checked')){$(srv_suffix_pid).hide();}
$("#table_capwap_ac").show();$("#btn_add").show();if(getVisibleRowCount(-1)>=max_count){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}}});$('form').submit(function(){return before_submit();});});