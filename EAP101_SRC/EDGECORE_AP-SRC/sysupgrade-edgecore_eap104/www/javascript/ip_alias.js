
var ipalias_row='<tr class="cbi-section-table-row" id="cbi-network-cfgCFG_ID" data-lan="IFACE_NAME"> '
+' <td class="cbi-value-field">'
+' <div id="cbi-network-cfgCFG_ID-ipaddr">'
+'     <input type="hidden" id="acn.new.IFACE_NAME.cfgNEW_ID"  '
+' name="acn.new.IFACE_NAME.cfgNEW_ID" value="CFG_ID" /> '
+'  '
+'     <input title="" type="text" class="ace-tooltip" data-rel="tooltip" name="cbid.network.cfgCFG_ID.ipaddr" id="cbid.network.cfgCFG_ID.ipaddr" value="" cbi_optional="true" data-original-title="" /> '
+'          '
+'  '
+' </div> '
+' <div id="cbip-network-cfgCFG_ID-ipaddr"></div> '
+' </td> '
+'  '
+' <td class="cbi-value-field"> '
+' <div id="cbi-network-cfgCFG_ID-netmask">     '
+'      '
+'         <input type="text" class="ace-tooltip" onchange="cbi_d_update(this.id)" id="cbid.network.cfgCFG_ID.netmask" name="cbid.network.cfgCFG_ID.netmask" size="1"> '
+'  '
+' </div> '
+' <div id="cbip-network-cfgCFG_ID-netmask"></div> '
+' </td> '
+'  '
+' <td class="cbi-value-field"> '
+' <div id="cbi-network-cfgCFG_ID-comment"> '
+'      '
+'     <input title="" type="text" class="ace-tooltip" onchange="cbi_d_update(this.id)" name="cbid.network.cfgCFG_ID.comment" id="cbid.network.cfgCFG_ID.comment" value="" maxlength="100"/> '
+'          '
+'      '
+' </div> '
+' <div id="cbip-network-cfgCFG_ID-comment"></div> '
+' </td> '
+'  '
+' <td class="cbi-section-table-cell" style="width:50px"> '
+'                              '
+' <input type="hidden" name="acn.del.network.cfgCFG_ID" id="acn.del.network.cfgCFG_ID" value="0">'
+' <button class="btn btn-info btn-mini btn-danger"  value="cfgCFG_ID" onclick="removeIpAliasRow(\'IFACE_NAME\', this.id); return false;" name="cbi.rts.network.cfgCFG_ID" id="cbi.rts.network.cfgCFG_ID" alt="Delete" title="Delete"><i class="icon-trash"></i></button>             '
+' </td></tr>';var new_row_counter=0;function openIpAliases(network){var name='acn-dialog-network-'+network;$('#'+name).modal('show').on('shown',function(){isExceedMax(network);});}
function removeIpAliasRow(network,btn){var selAlert='#table_ip_alias_'+network+' + div #alert_up_max';$(selAlert).hide();var selBtn='#table_ip_alias_'+network+' + div .btn-add';$(selBtn).attr('disabled',false);btn=btn.replace(/\./g,'\\.');if($('#'+btn).hasClass('disabled')){return;}
var value=$('#'+btn).attr('value');var id='acn\\.del\\.network\\.'+value;$('#'+id).attr('value',1);$('#cbi-network-'+value).hide();updateBadgeCount(network);validate_form();}
function initIpAliasBadgeCount(network){var len=$('#table_ip_alias_'+network+' tr').length-2;if($('#table_ip_alias_'+network+'_row_empty').length<=0){len=len+1;}
var lbl='';if(len>0){lbl=len;}
$('#ip_alias_count_'+network).text(lbl);}
function updateBadgeCount(network,row_offset,initial){var len=0;if(initial){len=$('#table_ip_alias_'+network+' tr').length+row_offset;if($('#table_ip_alias_'+network+'_row_empty').length<=0){len=len+1;}}else{len=getVisibleRowCount(network,row_offset);}
var lbl='';if(len>0){lbl=len;}
$('#ip_alias_count_'+network).text(lbl);}
function getVisibleRowCount(network,row_offset){var offset=row_offset;if(offset===undefined){offset=-1;}
var len=$('#table_ip_alias_'+network+' tr:visible').length+offset;return len;}
function addIpAliasRow(network){var name='#table_ip_alias_'+network;$(name+'_row_empty').hide();var cfg_id=new_row_counter;new_row_counter++;var row=ipalias_row.replace(/CFG_ID/g,cfg_id);row=row.replace(/CFG_ID/g,cfg_id);row=row.replace(/NEW_ID/g,cfg_id);row=row.replace(/IFACE_NAME/g,network);row=$.parseHTML(row);if($(name+' tr').length>0){var selector=name+' tr:last';$(selector).after(row);updateBadgeCount(network,-1);}else{$(name+' tbody').append(row);updateBadgeCount(network,-1);}
add_validation_ipaliases_handlers($('#cbi-network-cfg'+cfg_id)[0].id);isExceedMax(network);return false;}
function isExceedMax(network){if(getVisibleRowCount(network,-1)>=5){var selAlert='#table_ip_alias_'+network+' + div #alert_up_max';$(selAlert).show();var selBtn='#table_ip_alias_'+network+' + div .btn-add';$(selBtn).attr('disabled',true);return;}}