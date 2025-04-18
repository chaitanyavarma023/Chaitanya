
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
+'<div id="cbi-wifi_channel-CFG_ID-EIRP_limit">'
+'</div>'
+'</td>'
+' '
+'<td class="cbi-value-field">'
+'<div id="cbi-wifi_channel-CFG_ID-DFS_required">'
+'</div>'
+'</td>'
+'';var channel_all_array=new Array();var channel_array=new Array();function wifi_channel(){var tbl_name='#table_channel';$(tbl_name+' tbody').html('');$('#row_empty').hide();$('#spinner_scan').addClass('icon-spin');$('#spinner_scan_container').show();channel_array=channel_val.split('-');$('#spinner_scan').removeClass('icon-spin');$('#spinner_scan_container').hide();var ht_mode=document.getElementById('cbid.wireless.'+radio_iface+'.htmode');var ht_mode_val=$(ht_mode).val();if(chan_detail[ht_mode_val]!=undefined){for(var attr in chan_detail[ht_mode_val]){var _freq=chan_detail[ht_mode_val][attr].freq;var _channel=chan_detail[ht_mode_val][attr].chan;var _power=chan_detail[ht_mode_val][attr].max_tx;var _eirp=chan_detail[ht_mode_val][attr].eirp;var _dfs=(chan_detail[ht_mode_val][attr].dfs==false?'No':'Yes');if(_freq!=undefined){var row=channel_row.replace(/CFG_ID/g,_channel);row=$.parseHTML(row);if($(tbl_name+' tr').length>1){var selector=tbl_name+' tr:last';$(selector).after(row);}else{$(tbl_name+' tbody').append(row);}
channel_all_array.push(_channel);$('#cbi-wifi_channel-'+_channel+'-checkbox').prop('checked',false);for(var i=0;i<channel_array.length;i++){if(channel_array[i]==_channel){$('#cbi-wifi_channel-'+channel_array[i]+'-checkbox').prop('checked',true);}}
$('#cbi-wifi_channel-'+_channel+'-frequency').text(_freq+' ('+_channel+')');$('#cbi-wifi_channel-'+_channel+'-transmit_pw').text(_power);$('#cbi-wifi_channel-'+_channel+'-EIRP_limit').text(_eirp);$('#cbi-wifi_channel-'+_channel+'-DFS_required').text(_dfs);}}}
if($('#'+channel_id).val()=='auto'){$('#select_all').prop('checked',true);$('#select_all').trigger('change');}
$(tbl_name).trigger('update');}
function save_channel(){$('#wifi_frequency_modal').modal('hide');var _channel_value='';for(var i=0;i<channel_all_array.length;i++){var channel_checkbox_id='#cbi-wifi_channel-'+channel_all_array[i]+'-checkbox';if($(channel_checkbox_id).is(':checked')){if(_channel_value==''){_channel_value=$(channel_checkbox_id).val();}else{_channel_value+='-'+$(channel_checkbox_id).val();}}}
if(_channel_value==''||$('#select_all').is(':checked')){$('#cbi-wireless-'+radio_iface+'channel-auto').prop('selected','selected');$('#'+channel_id).val('auto');for(var j=0;j<channel_array.length;j++){$('#cbi-wifi_channel-'+channel_array[j]+'-checkbox').prop('checked',false);}
$('#frequency_btn_'+radio_iface).val('Auto');}else{var channel_specific_option_id='cbi-wireless-'+radio_iface+'-channel-'+_channel_value;var channel_specific_option='<option id="'+channel_specific_option_id+'" value="'+_channel_value+'">Specific Frequency</option>';var channel_auto_option='<option id="cbi-wireless-'+radio_iface+'-channel-auto" value="auto">Auto</option>';$('#'+channel_id).empty();$('#'+channel_id).append(channel_auto_option);$('#'+channel_id).append(channel_specific_option);$('#'+channel_specific_option_id).prop('selected','selected');$('#'+channel_id).val(_channel_value);if(_channel_value.search('-')>=0){$('#frequency_btn_'+radio_iface).val('Auto');}else{var selected_freq_full=$('#cbi-wifi_channel-'+_channel_value+'-frequency').text();var selected_freq_full_arr=selected_freq_full.split(' ');$('#frequency_btn_'+radio_iface).val(_channel_value+' ('+(selected_freq_full_arr[0]/1000)+' GHz)');}}
set_txpower_list();}