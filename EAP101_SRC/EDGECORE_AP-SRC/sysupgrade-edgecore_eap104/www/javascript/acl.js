
var acl_row='<tr class="cbi-section-table-row" id="cbi-wireless-cfgCFG_ID">'
+' <td class="cbi-value-field">'
+' <div id="cbi-wireless-cfgCFG_ID-macaddr">'
+' <input type="hidden" id="acn.new.IFACE_NAME.cfgNEW_ID" name="acn.new.IFACE_NAME.cfgNEW_ID" value="CFG_ID" />'
+' <input title="" type="text" class="ace-tooltip" data-rel="tooltip" name="cbid.wireless.cfgCFG_ID.macaddr" id="cbid.wireless.cfgCFG_ID.macaddr" value=""  cbi_datatype="macaddr" cbi_optional="true" data-original-title="" />'
+' </div>'
+' <div id="cbip-wireless-cfgCFG_ID-macaddr"></div>'
+' </td>'
+' <td class="cbi-section-table-cell" style="width:50px">'
+' <button class="btn btn-info btn-mini"  value="cfgCFG_ID" onclick="removeAclRow(\'IFACE_NAME\', this.id); return false;" name="cbi.rts.wireless.cfgCFG_ID" id="cbi.rts.wireless.cfgCFG_ID" alt="Delete" title="Delete"><i class="  icon-remove icon-3x icon-only"></i></button>'
+' </td></tr>';var new_row_counter=0;function openAcl(section){var name="acn-dialog-wireless-"+section;$('#'+name).modal('show');}
function removeAclRow(section,btn){btn=btn.replace(/\./g,"\\.");var value=$('#'+btn).attr("value");var id="acn\\.del\\.wireless\\."+value;$('#'+id).attr("value",1);$('#cbi-wireless-'+value).fadeOut();updateBadgeCount(section);}
function initAclBadgeCount(section)
{var len=$('#table_acl_'+section+' tr').length-2;if($('#table_acl_'+section+'_row_empty').length<=0)
{len=len+1;}
var lbl="";if(len>0)
lbl=len;$('#acl_count_'+section).text(lbl);}
function updateBadgeCount(section,row_offset,initial)
{var len=0
if(initial)
{len=$('#table_acl_'+section+' tr').length+row_offset;if($('#table_acl_'+section+'_row_empty').length<=0)
len=len+1;}
else len=getVisibleRowCount(section,row_offset);var lbl="";if(len>0)
lbl=len;$('#acl_count_'+section).text(lbl);}
function getVisibleRowCount(section,row_offset)
{var offset=row_offset;if(offset==undefined)offset=-2;var len=$('#table_acl_'+section+' tr:visible').length+offset;return len}
function addAclRow(section)
{var name="#table_acl_"+section;$(name+"_row_empty").hide();var cfg_id=new_row_counter;new_row_counter++;var row=acl_row.replace(/CFG_ID/g,cfg_id);row=row.replace(/CFG_ID/g,cfg_id);row=row.replace(/NEW_ID/g,cfg_id);row=row.replace(/IFACE_NAME/g,section);var row=$.parseHTML(row);if($(name+' tr').length>0){var selector=name+' tr:last';$(selector).after(row);updateBadgeCount(section,-1);}
else{$(name+' tbody').append(row);updateBadgeCount(section,-1);}
var row_id="cbi-wireless-cfg"+cfg_id;;$('#'+row_id+" input").change(function(e,data){cbi_d_update(this.id);});$('#'+row_id+" input").tooltip();$('#'+row_id+" input").each(function(){if($(this).attr('type')=='text'&&this.id.indexOf('CFG_ID')<0)
cbi_validate_field(this.id,false,'macaddr');});return false;}