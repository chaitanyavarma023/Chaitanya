
var Venue_Names_row='<tr id="VenueNameCFG_ID_row">'
+'    <td>'
+'        <div id="VenueName-cfgCFG_ID">'
+'            <select style="width:100px" class="cbi-input-select" onchange="cbi_d_update(this.id)" id="VenueNameCFG_ID.lang" name="VenueNameCFG_ID.lang" size="1">'
+'             <option id="VenueName-cfgCFG_ID-ara" value="ara">Arabic</option>'
+'             <option id="VenueName-cfgCFG_ID-ben" value="ben">Bengali</option>'
+'             <option id="VenueName-cfgCFG_ID-zho" value="zho">Chinese</option>'
+'             <option id="VenueName-cfgCFG_ID-eng" value="eng"selected="selected">English</option>'
+'             <option id="VenueName-cfgCFG_ID-fra" value="fra">French</option>'
+'             <option id="VenueName-cfgCFG_ID-deu" value="deu">German</option>'
+'             <option id="VenueName-cfgCFG_ID-hin" value="hin">Hindi</option>'
+'             <option id="VenueName-cfgCFG_ID-ind" value="ind">Indonesian</option>'
+'             <option id="VenueName-cfgCFG_ID-jpn" value="jpn">Japanese</option>'
+'             <option id="VenueName-cfgCFG_ID-kor" value="kor">Korean</option>'
+'             <option id="VenueName-cfgCFG_ID-por" value="por">Portuguese</option>'
+'             <option id="VenueName-cfgCFG_ID-rus" value="rus">Russian</option>'
+'             <option id="VenueName-cfgCFG_ID-spa" value="spa">Spanish</option>'
+'             <option id="VenueName-cfgCFG_ID-tgl" value="tgl">Tagalog</option>'
+'             <option id="VenueName-cfgCFG_ID-tha" value="tha">Thai</option>'
+'             <option id="VenueName-cfgCFG_ID-urd" value="urd">Urdu</option>'
+'             <option id="VenueName-cfgCFG_ID-vie" value="vie">Vietnamese</option>'
+'            </select>'
+'        </div>'
+'    </td>'
+'    <td>'
+'         <input style="width:50px" type="text" class="ace-tooltip" '
+'           name="VenueNameCFG_ID.name" id="VenueNameCFG_ID.name" value="" > '
+'    </td>'
+'    <td>'
+'        <input style="width:150px" type="text" class="ace-tooltip" name="VenueNameCFG_ID.url"'
+'          id="VenueNameCFG_ID.url" value="" data-original-title=""> <br> </span>'
+'       </td>'
+'    <td> '
+'        <button class="btn btn-info btn-mini btn-danger" onclick="{removeRowVenueName(this.id);  return false;}" '
+'        alt="<%:Delete%>" id="VenueNameCFG_ID" value="CFG_ID" title="<%:Delete%>"> '
+'        <i class="icon-trash"></i></button> '
+'    </td> '
+'  </tr> ';var Cellular_Network_row='<tr id="3GPP_CellularCFG_ID_row">'
+'    <td>'
+'         <input style="width:50px" type="text" class="ace-tooltip" '
+'           name="cell_countryCFG_ID" id="cell_countryCFG_ID" value="" > '
+'    </td>'
+'    <td>'
+'        <input style="width:150px" type="text" class="ace-tooltip" name="cell_networkCFG_ID"'
+'          id="cell_networkCFG_ID" value="" data-original-title=""> <br> </span>'
+'    </td>'
+'    <td> '
+'        <button class="btn btn-info btn-mini btn-danger" onclick="{removeRowCellNetwork(this.id);  return false;}" '
+'        alt="<%:Delete%>" id="3GPPCellularCFG_ID" value="CFG_ID" title="<%:Delete%>"> '
+'        <i class="icon-trash"></i></button> '
+'    </td> '
+'  </tr> ';var Operator_Names_row='<tr id="OperatorNameCFG_ID_row">'
+'    <td>'
+'     <div id="OperatorName-cfgCFG_ID">'
+'       <select style="width:80px" class="cbi-input-select" onchange="cbi_d_update(this.id)" id="OperatorLangCFG_ID" name="OperatorLangCFG_ID" size="1">'
+'         <option id="OperatorName-cfgCFG_ID-ara" value="ara">Arabic</option>'
+'         <option id="OperatorName-cfgCFG_ID-ben" value="ben">Bengali</option>'
+'         <option id="OperatorName-cfgCFG_ID-zho" value="zho">Chinese</option>'
+'         <option id="OperatorName-cfgCFG_ID-eng" value="eng"selected="selected">English</option>'
+'         <option id="OperatorName-cfgCFG_ID-fra" value="fra">French</option>'
+'         <option id="OperatorName-cfgCFG_ID-deu" value="deu">German</option>'
+'         <option id="OperatorName-cfgCFG_ID-hin" value="hin">Hindi</option>'
+'         <option id="OperatorName-cfgCFG_ID-ind" value="ind">Indonesian</option>'
+'         <option id="OperatorName-cfgCFG_ID-jpn" value="jpn">Japanese</option>'
+'         <option id="OperatorName-cfgCFG_ID-kor" value="kor">Korean</option>'
+'         <option id="OperatorName-cfgCFG_ID-por" value="por">Portuguese</option>'
+'         <option id="OperatorName-cfgCFG_ID-rus" value="rus">Russian</option>'
+'         <option id="OperatorName-cfgCFG_ID-spa" value="spa">Spanish</option>'
+'         <option id="OperatorName-cfgCFG_ID-tgl" value="tgl">Tagalog</option>'
+'         <option id="OperatorName-cfgCFG_ID-tha" value="tha">Thai</option>'
+'         <option id="OperatorName-cfgCFG_ID-urd" value="urd">Urdu</option>'
+'         <option id="OperatorName-cfgCFG_ID-vie" value="vie">Vietnamese</option>'
+'       </select>'
+'      </div>'
+'    </td>'
+'    <td>'
+'     <input style="width:250px" type="text" class="ace-tooltip" '
+'      name="OperatorNameCFG_ID" id="OperatorNameCFG_ID" value="" > '
+'    </td>'
+'    <td> '
+'     <button class="btn btn-info btn-mini btn-danger" onclick="{removeRowOperatorName(this.id);  return false;}" '
+'      alt="<%:Delete%>" id="delOperatorNameCFG_ID" value="CFG_ID" title="<%:Delete%>"> '
+'      <i class="icon-trash"></i></button> '
+'    </td> '
+' </tr> ';var Roaming_row='<tr id="RoamingCFG_ID_row">'
+'   <td>'
+'     <input style="width:250px" type="text" class="ace-tooltip" name="RoamingConsortiumCFG_ID"'
+'       id="RoamingConsortiumCFG_ID" value="" data-original-title=""> <br> </span>'
+'   </td>'
+'   <td> '
+'     <button class="btn btn-info btn-mini btn-danger" onclick="{removeRowRoaming(this.id);  return false;}" '
+'     alt="<%:Delete%>" id="delRoamingCFG_ID" value="CFG_ID" title="<%:Delete%>"> '
+'       <i class="icon-trash"></i></button> '
+'   </td> '
+' </tr> ';var Domain_row='<tr id="DomainCFG_ID_row">'
+'   <td>'
+'     <input style="width:250px" type="text" class="ace-tooltip" name="DomainCFG_ID"'
+'       id="DomainCFG_ID" value="" data-original-title=""> <br> </span>'
+'   </td>'
+'   <td> '
+'     <button class="btn btn-info btn-mini btn-danger" onclick="{removeRowDomain(this.id);  return false;}" '
+'     alt="<%:Delete%>" id="delDomainCFG_ID" value="CFG_ID" title="<%:Delete%>"> '
+'     <i class="icon-trash"></i></button> '
+'   </td> '
+' </tr> ';var max_list_walled=32;function checkMemberEmpty(vid){var flag=true;if($('#bind_ssid_'+vid).text().length>0){flag=false;}
return flag;}
function getVisibleRowCount(tbl_name,row_offset){var offset=row_offset;if(offset===undefined){offset=-2;}
var len=$('#'+tbl_name+' tr:visible').length+offset;return len;}
function get_next_id(_id){for(var i=1;i<=MAX_Venue_Name;i++){var id='#VenueName'+i+'\\.name';if($(id).val()===undefined){return i;}}}
function get_next_id_operator(_id){for(var i=1;i<=MAX_Venue_Name;i++){var id=_id+i;if($(id).val()===undefined){return i;}}}
function iw_portal_change(){var portal_enable='cbid\\.iw_portal_enable';var portal_enable_val=$('#'+portal_enable).val();if(portal_enable_val=='1'){$('#cbi-iw_portal_url').show();$('#cbi-iw_portal_wall').show();}else{$('#cbi-iw_portal_url').hide();$('#cbi-iw_portal_wall').hide();}}
function nai_realm_auth1_change(_val){var auth2_id='cbid\\.nai_realm_auth2';$('#'+auth2_id+' option').remove();if(_val=='2'){$('#'+auth2_id).append($('<option>',{value:'1'}).text('PAP'));$('#'+auth2_id).append($('<option>',{value:'2'}).text('CHAP'));$('#'+auth2_id).append($('<option>',{value:'3'}).text('MSCHAP'));$('#'+auth2_id).append($('<option>',{value:'4'}).text('MSCHAPV2'));}else{$('#'+auth2_id).append($('<option>',{value:'1'}).text('SIM'));$('#'+auth2_id).append($('<option>',{value:'2'}).text('USIM'));$('#'+auth2_id).append($('<option>',{value:'3'}).text('NFC Secure Element'));$('#'+auth2_id).append($('<option>',{value:'4'}).text('Hardware Token'));$('#'+auth2_id).append($('<option>',{value:'5'}).text('Softoken'));$('#'+auth2_id).append($('<option>',{value:'6'}).text('Certificate'));$('#'+auth2_id).append($('<option>',{value:'7'}).text('username/password'));$('#'+auth2_id).append($('<option>',{value:'8'}).text('none'));$('#'+auth2_id).append($('<option>',{value:'9'}).text('Anonymous'));$('#'+auth2_id).append($('<option>',{value:'10'}).text('Vendor Specific'));}
cbi_d_update(auth2_id);}
function removeRowProfile(btn){var value=$('#'+btn).attr('value');var id='acn\\.del\\.profile'+value;$('#alert_member_nonempty').hide();if(!checkMemberEmpty(value)){$('#alert_member_nonempty').show();return false;}
$('#'+id).attr('value',1);$('#profile'+value+'_row').remove();var exist_row_num=getVisibleRowCount('table_profiles',-1);if(exist_row_num==0){$('#row_empty').show();}
if(exist_row_num<=(MAX_Profiles_COUNT)){$('#alert_up_max').hide();$('#btn_add').attr('disabled',false);}}
function removeRowVenueName(btn){var value=$('#'+btn).attr('value');var id='acn\\.del\\.venuename'+value;$('#'+id).attr('value',1);$('#VenueName'+value+'_row').remove();var exist_row_num=getVisibleRowCount('table_Venue_Names',-1);if(exist_row_num==0){$('#row_empty_Venue_Names').show();$('#alert_empty_Venue_Names').show();}
if(exist_row_num<=MAX_Venue_Name){$('#alert_up_max_Venue_Names').hide();$('#btn_add_Venue_Names').attr('disabled',false);}}
function addVenueNames(){var name='#table_Venue_Names';$('#row_empty_Venue_Names').hide();$('#alert_empty_Venue_Names').hide();if(getVisibleRowCount('table_Venue_Names',-1)>=MAX_Venue_Name){$('#alert_up_max_Venue_Names').show();$('#btn_add_Venue_Names').attr('disabled',true);return;}
var cfg_id=get_next_id();var row=Venue_Names_row.replace(/CFG_ID/g,cfg_id);row=$.parseHTML(row);if($(name+' tr').length>1){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
var row_id='#VenueName'+cfg_id+'_row';$(row_id+' input').change(function(){cbi_d_update(this.id);});$(row_id+' input').tooltip();return false;}
function removeRowCellNetwork(btn){var value=$('#'+btn).attr('value');var id='acn\\.del\\.cellnetwork'+value;$('#'+id).attr('value',1);$('#3GPP_Cellular'+value+'_row').remove();var exist_row_num=getVisibleRowCount('table_3GPP_Cellular',-1);if(exist_row_num==0){$('#row_empty_3GPP_Cellular').show();}
if(exist_row_num<=MAX_Venue_Name){$('#alert_up_max_3GPP_Cellular').hide();$('#btn_add_3GPP_Cellular').attr('disabled',false);}}
function add3GPPCellular(){var name='#table_3GPP_Cellular';$('#row_empty_3GPP_Cellular').hide();$('#alert_empty_3GPP_Cellular').hide();if(getVisibleRowCount('table_3GPP_Cellular',-1)>=MAX_Venue_Name){$('#alert_up_max_3GPP_Cellular').show();$('#btn_add_3GPP_Cellular').attr('disabled',true);return;}
var cfg_id=get_next_id_operator('#cell_country');var row=Cellular_Network_row.replace(/CFG_ID/g,cfg_id);row=$.parseHTML(row);if($(name+' tr').length>1){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
var row_id='#3GPP_Cellular'+cfg_id+'_row';$(row_id+' input').change(function(){cbi_d_update(this.id);});$(row_id+' input').tooltip();return false;}
function removeRowOperatorName(btn){var value=$('#'+btn).attr('value');var id='acn\\.del\\.operatorname'+value;$('#'+id).attr('value',1);$('#OperatorName'+value+'_row').remove();var exist_row_num=getVisibleRowCount('table_Operator_Names',-1);if(exist_row_num==0){$('#row_empty_Operator_Names').show();$('#alert_empty_Operator_Names').show();}
if(exist_row_num<=MAX_Venue_Name){$('#alert_up_max_Operator_Names').hide();$('#btn_add_Operator_Names').attr('disabled',false);}}
function addOperatorNames(){var name='#table_Operator_Names';$('#row_empty_Operator_Names').hide();$('#alert_empty_Operator_Names').hide();if(getVisibleRowCount('table_Operator_Names',-1)>=MAX_Venue_Name){$('#alert_up_max_Operator_Names').show();$('#btn_add_Operator_Names').attr('disabled',true);return;}
var cfg_id=get_next_id_operator('#OperatorName');var row=Operator_Names_row.replace(/CFG_ID/g,cfg_id);row=$.parseHTML(row);if($(name+' tr').length>1){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
var row_id='#OperatorName'+cfg_id+'_row';$(row_id+' input').change(function(){cbi_d_update(this.id);});$(row_id+' input').tooltip();return false;}
function removeRowRoaming(btn){var value=$('#'+btn).attr('value');var id='acn\\.del\\.roaming'+value;$('#'+id).attr('value',1);$('#Roaming'+value+'_row').remove();var exist_row_num=getVisibleRowCount('table_Roaming_Consortium',-1);if(exist_row_num==0){$('#row_empty_Roaming_Consortium').show();}
if(exist_row_num<=MAX_Venue_Name){$('#alert_up_max_Roaming_Consortium').hide();$('#btn_add_Roaming_Consortium').attr('disabled',false);}}
function addRoamingConsortium(){var name='#table_Roaming_Consortium';$('#row_empty_Roaming_Consortium').hide();$('#alert_up_max_Roaming_Consortium').hide();if(getVisibleRowCount('table_Roaming_Consortium',-1)>=MAX_Venue_Name){$('#alert_up_max_Roaming_Consortium').show();$('#btn_add_Roaming_Consortium').attr('disabled',true);return;}
var cfg_id=get_next_id_operator('#RoamingConsortium');var row=Roaming_row.replace(/CFG_ID/g,cfg_id);row=$.parseHTML(row);if($(name+' tr').length>1){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
var row_id='#Roaming'+cfg_id+'_row';$(row_id+' input').change(function(){cbi_d_update(this.id);});$(row_id+' input').tooltip();return false;}
function removeRowDomain(btn){var value=$('#'+btn).attr('value');var id='acn\\.del\\.domain'+value;$('#'+id).attr('value',1);$('#Domain'+value+'_row').remove();var exist_row_num=getVisibleRowCount('table_Domain',-1);if(exist_row_num==0){$('#row_empty_Domain').show();$('#alert_empty_Domain').show();}
if(exist_row_num<=MAX_Venue_Name){$('#alert_up_max_Domain').hide();$('#btn_add_Domain').attr('disabled',false);}}
function addDomain(){var name='#table_Domain';$('#row_empty_Domain').hide();$('#alert_empty_Domain').hide();if(getVisibleRowCount('table_Domain',-1)>=MAX_Venue_Name){$('#alert_up_max_Domain').show();$('#btn_add_Domain').attr('disabled',true);return;}
var cfg_id=get_next_id_operator('#Domain');var row=Domain_row.replace(/CFG_ID/g,cfg_id);row=$.parseHTML(row);if($(name+' tr').length>1){var selector=name+' tr:last';$(selector).after(row);}else{$(name+' tbody').append(row);}
var row_id='#Domain'+cfg_id+'_row';$(row_id+' input').change(function(){cbi_d_update(this.id);});$(row_id+' input').tooltip();return false;}
function removeRowNAIAuth(btn){var value=$('#'+btn).attr('value');var id='acn\\.del\\.naiauth'+value;$('#'+id).attr('value',1);$('#NAIAuth'+value+'_row').remove();}
function checkArrayRepeat(array){var hash={},hash_idx={};var flag=false;for(var i in array){var _row_idx=array[i].split(',')[0];var _tmp=array[i].split(',')[1];if(hash_idx[_tmp]===undefined){hash_idx[_tmp]=_row_idx+' ';}else{hash_idx[_tmp]+=_row_idx+' ';}
if(hash[_tmp]){var hash_idx_tmp=hash_idx[_tmp].split(' ');for(var j=0;j<hash_idx_tmp.length;j++){$('#NAIAuth'+hash_idx_tmp[j]+'_row').css('background','#ff000024');}
flag=true;}
hash[_tmp]=true;}
return flag;}
function nai_save(){var _domain_id='#cbid\\.nai_realm_domain'
var _domain=$(_domain_id).val();var _encoding=$('#cbid\\.nai_realm_encoding').val();var _method=$('#cbid\\.nai_realm_method').val();var _auth='';var res=true;if(_domain!=undefined){if(!cbi_validators.isDomain(_domain)){set_err_msg($(_domain_id),true,_('Not a valid Domain Name.'));res=false;}
if($(_domain_id).attr('disabled')==undefined){$("#table_NAI_Realm").find("td[id^='nai_domain_txt_']").each(function(){if($(this).text()==_domain){set_err_msg($(_domain_id),true,_('Duplicated Domain Name.'));res=false;return false;}})}}
if(res){$("#table_NAI_Auth").find("td[id^='nai_realm_auth_row']").each(function(){_auth=_auth+","+$(this).attr('value');})
var _val=_encoding+','+_domain+''+_auth;if(NAIRealm_edit_idx!=''){$('#hidden_nai_'+(NAIRealm_edit_idx-1)).val(_val);$('#nai_domain_txt_'+NAIRealm_edit_idx).text(_domain);NAIRealm_edit_idx='';}else{var exist_row_num=getVisibleRowCount('table_NAI_Realm',-1);var row_idx=(exist_row_num+1);$('#hidden_nai_'+exist_row_num).val(_val);var nai_realm_content='';nai_realm_content=nai_realm_content+'<tr id="NAI_Realm'+row_idx+'_row">'+'  <td id="nai_domain_txt_'+row_idx+'">'+
_domain+'</td>'+'  <td>'+'      <button class="btn btn-mini btn-danger"'+'      onclick="EditRow_NAIRealm(this.value, '+exist_row_num+');  return false;"'+'      alt="<%:Edit%>" id="NAIRealm_'+row_idx+'_edit" value="'+row_idx+'"><i class="icon-edit"></i></button>'+'     <button class="btn btn-mini btn-danger"'+'      onclick="removeRowNAIRealm(this.id);  return false;"'+'      alt="<%:Delete%>" id="NAIRealm_'+row_idx+'" value="'+row_idx+'" alt="<%:Delete%>"><i class="icon-trash"></i></button>'+'  </td>'+'</tr>';if(nai_realm_content!=''){$('#row_empty_NAI_Realm').hide();nai_realm_content=$.parseHTML(nai_realm_content);$('#table_NAI_Realm tbody').append(nai_realm_content);}}
$('#nai_realm_modal').modal('hide');$('#profile_modal').removeClass('modal-backdrop');$('#profile_modal').modal('show');}}
function nai_auth_save(){var _domain_id='#cbid\\.nai_realm_domain'
var _domain=$(_domain_id).val();var _encoding=$('#cbid\\.nai_realm_encoding').val();var _method=$('#cbid\\.nai_realm_method').val();var _method_name='';var _auth1=$('#cbid\\.nai_realm_auth1').val();var _auth2=$('#cbid\\.nai_realm_auth2').val();var _auth_id='#nai_realm_auth_row_'+_method;var _auth_list=$(_auth_id).text();var _auth_old='';var _auth='';var _auth_name='';var res=true;_auth=_auth1+':'+_auth2;_auth_name=nai_realm_auth1_name(_auth1)+":";_auth_name=_auth_name+nai_realm_auth2_name(_auth1,_auth2);_auth_old=$(_auth_id).attr('value');if(_auth_old!=undefined&&_auth_old.search(_auth)!=-1){$('#alert_duplicate').show();res=false;}else{$('#alert_duplicate').hide();}
if(res){_auth='['+_auth+']';if($('#nai_realm_method_'+_method).length){_auth_list=_auth_list+','+_auth_name;$(_auth_id).text(_auth_list);_auth_old=_auth_old+_auth;$(_auth_id).attr('value',_auth_old);}
else{_method_name=nai_realm_method_name(_method);var nai_auth_content='';nai_auth_content=nai_auth_content+'<tr id="NAIAuth'+_method+'_row">'+'  <td id="nai_realm_method_'+_method+'">'+''+_method_name+''+'  </td>'+'  <td id="nai_realm_auth_row_'+_method+'" value='+_method+_auth+'>'+_auth_name+'</td>'+'  <td>'+'    <button class="btn btn-info btn-mini btn-danger" onclick="{removeRowNAIAuth(this.id);  return false;}"'+'      alt="<%:Delete%>" id="delNAIAuth'+_method+'" value="'+_method+'" alt="<%:Delete%>">'+'    <i class="icon-trash"></i></button>'+'  </td> '+'</tr>';if(nai_auth_content!=''){$('#row_empty_NAI_Auth').hide();nai_auth_content=$.parseHTML(nai_auth_content);$('#table_NAI_Auth tbody').append(nai_auth_content);}}
$('#nai_realm_auth_modal').modal('hide');$('#nai_realm_modal').removeClass('modal-backdrop');$('#nai_realm_modal').modal('show');}}
function addNAIRealm(){$('#row_empty_NAI_Realm').hide();$('#alert_up_max_NAI_Realm').hide();var exist_row_num=getVisibleRowCount('table_NAI_Realm',-1);if(exist_row_num>=MAX_Venue_Name){$('#alert_up_max_NAI_Realm').show();$('#btn_add_NAI_Realm').attr('disabled',true);return false;}
$('#nai_realm_content').html(old_nai_realm_html);$('#nai_realm_modal').modal('show');return false;}
function removeRowNAIRealm(btn){var value=$('#'+btn).attr('value');var id='acn\\.del\\.naiRealm'+(value-1);$('#'+id).attr('value',1);$('#NAI_Realm'+value+'_row').remove();$('#hidden_nai_'+(value-1)).val('');var exist_row_num=getVisibleRowCount('table_NAI_Realm',-1);if(exist_row_num==0){$('#row_empty_NAI_Realm').show();}
if(exist_row_num<=MAX_Venue_Name){$('#alert_up_max_NAI_Realm').hide();$('#btn_add_NAI_Realm').attr('disabled',false);}}
function addNAIMethodAuth(){$('#alert_duplicate').hide();$('#nai_realm_auth_content').html(old_nai_realm_auth_html);$('#nai_realm_auth_modal').modal('show');return false;}
function addProfile(){$('#cbid.profile_name').val('');for(var i=0;i<MAX_Venue_Name;i++){$('#hidden_nai_'+i).val('');}
$('#profile_content').html(old_html);$('#profile_modal').modal('show');$('[data-rel=tooltip]').tooltip();}
function clear_error_msg(){clear_validate_error('#cbid\\.profile_name');clear_validate_error('#cbid\\.iw_hessid');clear_validate_error('#cbid\\.nai_realm_domain');$('#alert_empty_Venue_Names').hide();$('#alert_empty_Operator_Names').hide();$('#alert_empty_Domain').hide();for(var i=1;i<=MAX_Venue_Name;i++){clear_validate_error('#VenueName'+i+'\\.name');clear_validate_error('#VenueName'+i+'\\.url');clear_validate_error('#cell_country'+i);clear_validate_error('#cell_network'+i);clear_validate_error('#OperatorName'+i);clear_validate_error('#RoamingConsortium'+i);clear_validate_error('#Domain'+i);}}
function convert_list(val){var tmp_walled_str=val.replace(/\r\n|\r|\n/g,' ');tmp_walled_str=tmp_walled_str.replace(/(^\s*)|(\s*$)/g,'');tmp_walled_str=tmp_walled_str.replace(/\s+/g,' ');return tmp_walled_str;}
function validateWallGarden(){var walled_id='#cbid\\.iw_portal_wall';clear_validate_error(walled_id);if($(walled_id).val()!=''){$(walled_id).val(convert_list($(walled_id).val()));var tmp_arr=$(walled_id).val().split(' ');if(tmp_arr.length>max_list_walled){set_err_msg($(walled_id),true,_('The total Walled Garden List is up to %d.').format(max_list_walled));return false;}else{var cidrToSubnets=['0.0.0.0','128.0.0.0','192.0.0.0','224.0.0.0','240.0.0.0','248.0.0.0','252.0.0.0','254.0.0.0','255.0.0.0','255.128.0.0','255.192.0.0','255.224.0.0','255.240.0.0','255.248.0.0','255.252.0.0','255.254.0.0','255.255.0.0','255.255.128.0','255.255.192.0','255.255.224.0','255.255.240.0','255.255.248.0','255.255.252.0','255.255.254.0','255.255.255.0','255.255.255.128','255.255.255.192','255.255.255.224','255.255.255.240','255.255.255.248','255.255.255.252','255.255.255.254','255.255.255.255'];for(var i=0;i<tmp_arr.length;i++){if(tmp_arr[i].search('/')!=-1){var ip_netmask=tmp_arr[i].split('/');if(ip_netmask.length>2){set_err_msg($(walled_id),true,_('Some of walled garden addresses are invalid'));return false;}
var _ip=ip_netmask[0];var _netmask=cidrToSubnets[ip_netmask[1]];if(!is_ip(_ip)){set_err_msg($(walled_id),true,_('Not a valid IPv4 address!')+'('+_ip+')');return false;}
if(_netmask==undefined||!cbi_validators.netmask(_netmask)){set_err_msg($(walled_id),true,_('Not a valid netmask!')+'('+ip_netmask[1]+')');return false;}
if(is_broadcast(_ip,_netmask)){set_err_msg($(walled_id),true,_('IP address is a broadcast IP.')+'('+_ip+')');return false;}}else{if(!cbi_validators.host(tmp_arr[i])){set_err_msg($(walled_id),true,_('Some of walled garden addresses are invalid'));return false;}}}}}
return true;}
function verify_profilename(){var res_profilename=true;var profilename_id='#cbid\\.profile_name';var profilename_val=$(profilename_id).val();if(profilename_val==''){set_err_msg($(profilename_id),true,_('This field is required.'));res_profilename=false;}else{if(!cbi_validators.username(profilename_val)){set_err_msg($(profilename_id),true,_('Must be between 1 and 32 ASCII characters. Only accept A-Z, a-z, 0-9, Period (.), Underscore (_) and Hyphen (-), but NOT allow profile name that begin with Hyphen (-).'));res_profilename=false;}{for(var i=0;i<MAX_Profiles_COUNT;i++){var _cfg_name=$('#profile_name_'+i).text().replace(/ /g,'').replace(/\n/g,'');if(edit_profile_name==''||edit_profile_name!=profilename_val){if(profilename_val==_cfg_name){set_err_msg($(profilename_id),true,_('Duplicated Profile Name.'));res_profilename=false;break;}}}}}
return res_profilename;}
function before_submit(){var res=true;clear_error_msg();if($('#profile_modal').css("display")!='none'){if(!verify_profilename()){res=false;}
var _id='#cbid\\.iw_hessid'
var _val=$(_id).val();if(!cbi_validators.macaddr(_val)||_val.toUpperCase()=='FF:FF:FF:FF:FF:FF'){set_err_msg($(_id),true,_('Not a valid MAC address!')+' '+_('Valid MAC address is not include of FF:FF:FF:FF:FF:FF.'));res=false;}
var _id='#cbid\\.hs20_operating_class'
var _val=$(_id).val();if(!cbi_validators.uinteger(_val)){set_err_msg($(_id),true,_('Not a valid number!'));res=false;}
var _id='#cbid\\.iw_portal_enable';var _val=$(_id).val();if(_val=='1'){var _id='#cbid\\.iw_portal_url'
var _val=$(_id).val();if(_val!=undefined){if(!cbi_validators.isURL(_val)){set_err_msg($(_id),true,_('The URL format is invalid.'));res=false;}}
res_validateWallGarden=validateWallGarden();if(res_validateWallGarden==false){res=false;}}
var _cnt=getVisibleRowCount('table_Venue_Names',-1);if(_cnt==0){$('#alert_empty_Venue_Names').show();$('html, body').scrollTop($("#alert_empty_Venue_Names").offset().top);res=false;}
var _cnt=getVisibleRowCount('table_Operator_Names',-1);if(_cnt==0){$('#alert_empty_Operator_Names').show();$('html, body').scrollTop($("#alert_empty_Operator_Names").offset().top);res=false;}
var _cnt=getVisibleRowCount('table_Domain',-1);if(_cnt==0){$('#alert_empty_Domain').show();$('html, body').scrollTop($("#alert_empty_Domain").offset().top);res=false;}
for(var i=1;i<=MAX_Venue_Name;i++){var _id='#VenueName'+i+'\\.name';var _val=$(_id).val();if(_val!=undefined){if(!cbi_validators.is_ascii(_val,[1,255])){set_err_msg($(_id),true,_('This value must be between %d and %d characters long.').format(1,255)+_(' Only accept A-Z, a-z, 0-9, space, and ~!@$%^*()_+-=[]{}|:;<>?,./'));res=false;}}
_id='#VenueName'+i+'\\.url';_val=$(_id).val();if(_val!=undefined){if(!cbi_validators.isURL(_val)){set_err_msg($(_id),true,_('The URL format is invalid.'));res=false;}}
var cell_country_id='#cell_country'+i;var cell_country_val=$(cell_country_id).val();var cell_network_id='#cell_network'+i;var cell_network_val=$(cell_network_id).val();if(cell_country_val!=undefined){if(cell_country_val.length!=3||!is_integer(cell_country_val)){set_err_msg(cell_country_id,true,_('Accept three decimal digits.'));res=false;}}
if(cell_network_val!=undefined){if((cell_network_val.length!=3&&cell_network_val.length!=2)||!is_integer(cell_network_val)){set_err_msg(cell_network_id,true,_('Accept two or three decimal digits.'));res=false;}}
var _id='#OperatorName'+i;var _val=$(_id).val();if(_val!=undefined){if(!cbi_validators.is_ascii(_val,[1,255])){set_err_msg($(_id),true,_('This value must be between %d and %d characters long.').format(1,255)+_(' Only accept A-Z, a-z, 0-9, space, and ~!@$%^*()_+-=[]{}|:;<>?,./'));res=false;}}
var _id='#RoamingConsortium'+i;var _val=$(_id).val();if(_val!=undefined){var _REGX=/^[a-fA-F0-9]+$/;var _length=_val.length;if(!_REGX.test(_val)||_length<6||_length>30||(_length%2)!=0){set_err_msg($(_id),true,_('This value must be between %d and %d octets and configured as a hexstring.').format(3,15));res=false;}}
var _id='#Domain'+i;var _val=$(_id).val();if(_val!=undefined){if(!cbi_validators.isDomain(_val)){set_err_msg($(_id),true,_('Not a valid Domain Name.'));res=false;}}}}
if(!res){cbi_show_form_error();}else{$('#cbid\\.profile_name').attr("disabled",false);}
return res;}
var old_html='';var old_nai_realm_html='';var old_nai_realm_auth_html='';$(function(){$('#alert_up_max').hide();var exist_row_num=getVisibleRowCount('table_profiles',-1);if(exist_row_num>=(MAX_Profiles_COUNT)){$('#alert_up_max').show();$('#btn_add').attr('disabled',true);}
$('#form_hs20_profile').submit(function(){return before_submit();});old_html=$("#profile_content").html();old_nai_realm_html=$("#nai_realm_content").html();old_nai_realm_auth_html=$("#old_nai_realm_auth_html").html();$('button.ace-tooltip').tooltip();$('button.disabled').click(function(){if(!$(this).hasClass('disabled')){$('.disabled').removeClass('disabled').attr('rel',null);$(this).addClass('disabled').attr('rel','tooltip');}});$('#close_profile_window').click(function(){edit_profile_name='';$('#Edit_section').val('');$('#form_error_msg_placeholder').addClass('hide');$('#profile_modal').modal('hide');});$('#close_nai_realm_window').click(function(){NAIRealm_edit_idx='';$('#profile_modal').removeClass('modal-backdrop');$('#nai_realm_modal').modal('hide');});$('#cbid\\.iw_portal_wall').change(validateWallGarden);});