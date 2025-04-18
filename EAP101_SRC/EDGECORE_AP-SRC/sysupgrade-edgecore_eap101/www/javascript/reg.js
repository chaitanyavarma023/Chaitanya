
var tx_power_list_cnt=0;function get_max_tx_power(chan,chan_bw){var _chan=chan.split('-');var max_pw_arr=new Array();var ret_max=0;for(var i=0;i<_chan.length;i++){var power_id='#cbi-wifi_channel-'+_chan[i]+'-transmit_pw';if($(power_id)){max_pw_arr.push($(power_id).text());}}
if(max_pw_arr!=''){ret_max=Math.max(parseInt(max_pw_arr,10));}else{if(chan_detail[chan_bw]){for(var attr in chan_detail[chan_bw]){tx_power_list_cnt++;var _chan=chan_detail[chan_bw][attr].chan;if(_chan==chan){ret_max=chan_detail[chan_bw][attr].max_tx;}}}}
return ret_max;}
function set_txpower_list(){var current_chan_bw=$('#cbid\\.wireless\\.'+radio_iface+'\\.htmode').val();var current_chan=$('#cbid\\.wireless\\.'+radio_iface+'\\.channel').val();if(!current_chan){current_chan='auto';}
var current_tx=$('#cbid\\.wireless\\.'+radio_iface+'\\.txpower').val();var tx_streams=$('#cbid\\.wireless\\.'+radio_iface+'\\.tx_streams').val();var tx_offset=Math.floor(10*Math.log(tx_streams)/Math.LN10+0.5);if(!current_tx&&current_txpower){current_tx=parseInt(current_txpower);}
var max_tx=get_max_tx_power(current_chan,current_chan_bw);if(tx_offset==0){var min_tx=1;}else{var min_tx=tx_offset;}
if(is_OAP&&country_code==='TH'&&(current_chan>=36&&current_chan<=48)){min_tx=2+tx_offset;}
var ctrl_tx=$('#cbid\\.wireless\\.'+radio_iface+'\\.txpower');ctrl_tx.empty();var found=false;for(var i=min_tx;i<=max_tx;i++){var tx=i;ctrl_tx.append($('<option>',{value:tx,id:'cbi-wireless-'+radio_iface+'-txpower-'+i}).text(tx+' dBm ('+Math.floor(Math.pow(10,tx/10))+' mW)'));if(tx===parseInt(current_tx)){found=true;$('#cbi-wireless-'+radio_iface+'-txpower-'+tx).prop('selected',true);}}
if(!found){$('#cbi-wireless-'+radio_iface+'-txpower-'+max_tx).prop('selected',true);}
var $slider=$('#tx_slider');if(tx_slider_initialized){$slider.slider('option','max',max_tx);$slider.slider('option','min',min_tx);}}