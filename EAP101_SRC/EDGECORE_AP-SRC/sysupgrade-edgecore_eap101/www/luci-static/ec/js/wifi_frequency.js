
var channel_row='<tr class="cbi-section-table-row" id="cbi-wifi_channel-CFG_ID" data-lan>'
+' '
+'<td class="cbi-value-field">'
+'<div id="cbi-wifi_channel-CFG_ID-div">'
+'  <input type="checkbox" class="region_ct" id="cbi-wifi_channel-CFG_ID-checkbox" name="cbi-wifi_channel-CFG_ID-checkbox" value="CFG_ID" style="position:static;opacity:initial">'
+'</div>'
+'</td>'
+' '
+'<td class="cbi-value-field">'
+'<div id="cbi-wifi_channel-CFG_ID-frequency">'
+'</div>'
+'</td>'
+' '
+'<td class="cbi-value-field">'
+'<div id="cbi-wifi_channel-CFG_ID-transmit_pw">'
+'</div>'
+'</td>'
+' '
+'<td class="cbi-value-field">'
+'<div id="cbi-wifi_channel-CFG_ID-DFS_required">'
+'</div>'
+'</td>'
+'';var channel_all_array=new Array();var channel_array=new Array();function sortItem(x,y){return((x.chan==y.chan)?0:((x.chan>y.chan)?1:-1));}
function wifi_channel(){channel_all_array=new Array();channel_array=new Array();var channel_hit=0;var tbl_name='#table_channel';$(tbl_name+' tbody').html('');$('#row_empty').hide();$('#spinner_scan').addClass('icon-spin');$('#spinner_scan_container').show();channel_array=channel_val.toString().split('-');$('#spinner_scan').removeClass('icon-spin');$('#spinner_scan_container').hide();var ht_mode=document.getElementById('cbid.wireless.'+radio_iface+'.htmode');var ht_mode_val=$(ht_mode).val();var _obj=chan_detail[ht_mode_val];if(ht_mode_val=="20"&&_obj==undefined){_obj=chan_detail["40"];}
var chans=[];var clean_arr=[];$.each(_obj,function(index,value){if($.inArray(value.chan,chans)==-1){chans.push(value.chan);clean_arr.push(value);}});_obj=clean_arr.sort(sortItem)
if(current_band=="2.4"&&ht_mode_val=="40"){clean_arr=[];var chan_limit=13;var last_ch=_obj[_obj.length-1].chan;if(last_ch=="auto"){last_ch=_obj[_obj.length-2].chan;}
if(last_ch==13){chan_limit=9;}
else if(last_ch==11){chan_limit=7;}
$.each(_obj,function(index,value){if(value.chan<=chan_limit||value.chan=="auto"){clean_arr.push(value);}});_obj=clean_arr;}
if(_obj!=undefined){for(var attr in _obj){var _freq=_obj[attr].freq;var _channel=_obj[attr].chan;var _power=(_obj[attr].max_tx>tx_power_max?tx_power_max:_obj[attr].max_tx);var _dfs=(_obj[attr].dfs==false?'No':'Yes');if(ht_mode_val=='40'||ht_mode_val=='80'||ht_mode_val=='160'){if(_channel=='165'){continue;}}
if(_freq!=undefined){var row=channel_row.replace(/CFG_ID/g,_channel);row=$.parseHTML(row);if($(tbl_name+' tr').length>1){var selector=tbl_name+' tr:last';$(selector).after(row);}else{$(tbl_name+' tbody').append(row);}
channel_all_array.push(_channel);$('#cbi-wifi_channel-'+_channel+'-checkbox').prop('checked',false);for(var i=0;i<channel_array.length;i++){if(channel_array[i]==_channel){$('#cbi-wifi_channel-'+channel_array[i]+'-checkbox').prop('checked',true);channel_hit++;if(_power>txpwr_list_limit){txpwr_list_limit=_power;}}}
$('#cbi-wifi_channel-'+_channel+'-frequency').text(_freq+' ('+_channel+')');$('#cbi-wifi_channel-'+_channel+'-transmit_pw').text(_power);$('#cbi-wifi_channel-'+_channel+'-DFS_required').text(_dfs);}}}
if(!channel_hit||channel_all_array.length==channel_hit||$("#select_all").is(':checked')){$('#select_all').prop('checked',true);$('#select_all').trigger('change');}
$(tbl_name).trigger('update');}
function save_channel(){var _channel_value='';var _channel_value_all='';for(var i=0;i<channel_all_array.length;i++){if(_channel_value_all==''){_channel_value_all=channel_all_array[i];}else{_channel_value_all+='-'+channel_all_array[i];}
var channel_col='#cbi-wifi_channel-'+channel_all_array[i];var channel_checkbox_id='#cbi-wifi_channel-'+channel_all_array[i]+'-checkbox';if($(channel_col).css('display')!='none'&&$(channel_checkbox_id).is(':checked')){if(_channel_value==''){_channel_value=$(channel_checkbox_id).val();}else{_channel_value+='-'+$(channel_checkbox_id).val();}}}
var channel_specific_option_id='cbi-wireless-'+radio_iface+'-channel-'+_channel_value;var channel_specific_option='<option id="'+channel_specific_option_id+'" value="'+_channel_value+'">Specific Frequency</option>';var channel_all_option_id='cbi-wireless-'+radio_iface+'-channel-all-'+_channel_value_all;var channel_all_option='<option id="'+channel_all_option_id+'" value="all-'+_channel_value_all+'">All Frequency</option>';var channel_auto_option='<option id="cbi-wireless-'+radio_iface+'-channel-auto" value="auto">Auto</option>';$('#'+channel_id).empty();$('#'+channel_id).append(channel_auto_option);$('#'+channel_id).append(channel_specific_option);$('#'+channel_id).append(channel_all_option);$('#'+channel_specific_option_id).prop('selected','selected');$('#'+channel_id).val(_channel_value);if(_channel_value==''||$('#select_all').is(':checked')){var all_channels_str='all-'+_channel_value_all;$('#cbi-wireless-'+radio_iface+'channel-auto').prop('selected','selected');$('#'+channel_id).val(all_channels_str);$('#frequency_btn_'+radio_iface).val('Auto');channel_val=_channel_value_all;}else{if(_channel_value.search('-')>=0){$('#frequency_btn_'+radio_iface).val('Auto');}else{var selected_freq_full=$('#cbi-wifi_channel-'+_channel_value+'-frequency').text();var selected_freq_full_arr=selected_freq_full.split(' ');$('#frequency_btn_'+radio_iface).val(_channel_value+' ('+(selected_freq_full_arr[0]/1000)+' GHz)');}
channel_val=_channel_value;}
$('#'+channel_id).change();}