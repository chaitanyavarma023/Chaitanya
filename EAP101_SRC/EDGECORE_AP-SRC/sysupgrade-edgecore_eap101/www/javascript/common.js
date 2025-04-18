
function dec2bin(d){var b='';var i;for(i=0;i<8;i++){b=(d%2)+b;d=Math.floor(d/2);}
return b;}
function ip2bin(ipstr){var re=/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;var val,ipbin='';if(!re.test(ipstr)){return'';}
val=RegExp.$1;ipbin+=dec2bin(val);val=RegExp.$2;ipbin+=dec2bin(val);val=RegExp.$3;ipbin+=dec2bin(val);val=RegExp.$4;ipbin+=dec2bin(val);return ipbin;}
var ZERO_NO=1;var ZERO_OK=2;var MASK_NO=4;var MASK_OK=8;var LOOPBACK_IP_OK=16;function is_ip(str,flag){var re=/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;if(typeof(flag)=='undefined'||flag==null){flag=ZERO_NO|MASK_OK;}
if(re.test(str)){if((flag&ZERO_OK)&&str=='0.0.0.0'){return true;}
if((flag&LOOPBACK_IP_OK)&&str=='127.0.0.1'){return true;}
if(str!='0.0.0.0'&&(flag&MASK_NO)&&RegExp.$4==0){return false;}
if(RegExp.$1==127)
{return false;}
if(RegExp.$1>223)
{return false;}
if(RegExp.$1==0){return false;}
if(RegExp.$2==0&&RegExp.$3==0&&RegExp.$4==0){return false;}
if(RegExp.$2==255&&RegExp.$3==255&&RegExp.$4==255){return false;}
if(RegExp.$1.length>=2){if(RegExp.$1.indexOf('0')==0){return false;}}
if(RegExp.$2.length>=2){if(RegExp.$2.indexOf('0')==0){return false;}}
if(RegExp.$3.length>=2){if(RegExp.$3.indexOf('0')==0){return false;}}
if(RegExp.$4.length>=2){if(RegExp.$4.indexOf('0')==0){return false;}}
if(RegExp.$1<256&&RegExp.$2<256&&RegExp.$3<256&&RegExp.$4<256){return true;}}
return false;}
function is_broadcast(ipstr,netmaskstr){var i,ipbin,netmaskbin,checkipbin;ipbin=ip2bin(ipstr);netmaskbin=ip2bin(netmaskstr);i=netmaskbin.indexOf('0');checkipbin=ipbin.substr(i,ipbin.length-i);if(checkipbin.indexOf('0')!=-1){return false;}
return true;}
function is_net(ipstr,netmaskstr){var i,ipbin,netmaskbin,checkipbin;ipbin=ip2bin(ipstr);netmaskbin=ip2bin(netmaskstr);i=netmaskbin.indexOf('0');checkipbin=ipbin.substr(i,ipbin.length-i);if(checkipbin.indexOf('1')!=-1){return false;}
return true;}
function is_in_netmask(ipstr,netmaskstr,checkip){var i,ipbin,netmaskbin,checkipbin;ipbin=ip2bin(ipstr);netmaskbin=ip2bin(netmaskstr);checkipbin=ip2bin(checkip);i=netmaskbin.indexOf('0');if(i==-1){if(checkipbin!=ipbin){return false;}
return true;}
if(ipbin.substr(0,i)!=checkipbin.substr(0,i)){return false;}
return true;}
function is_ipv6(v){if(v.match(/^([a-fA-F0-9:.]+)(\/(\d+))?$/)){if(!RegExp.$2||((RegExp.$3>=0)&&(RegExp.$3<=128))){var addr=RegExp.$1;if(addr=='::'){return true;}
if(addr.indexOf('.')>0){var off=addr.lastIndexOf(':');if(!(off&&cbi_validators.ip4addr(addr.substr(off+1)))){return false;}
addr=addr.substr(0,off)+':0:0';}
if(addr.indexOf('::')>=0){var colons=0;var fill='0';for(var i=1;i<(addr.length-1);i++){if(addr.charAt(i)==':'){colons++;}}
if(colons>7){return false;}
for(var i=0;i<(7-colons);i++){fill+=':0';}
if(addr.match(/^(.*?)::(.*?)$/)){addr=(RegExp.$1?RegExp.$1+':':'')+fill+
(RegExp.$2?':'+RegExp.$2:'');}}
return(addr.match(/^(?:[a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}$/)!=null);}}
return false;}
function set_err_msg(_io_id,err_ctrl,err_msg){var $io_id=_io_id;if(!(_io_id instanceof jQuery)){$io_id=$(_io_id);}
if(err_ctrl==true){$io_id.attr('data-original-title',err_msg);if($io_id.parent().hasClass('controls')){$io_id.parents('.control-group').addClass('error');}else{$io_id.parent('.control-group').addClass('error');}
$io_id.addClass('tooltip-error');$io_id.attr('data-trigger','focus');$io_id.tooltip();}else{$io_id.removeClass('tooltip-error');if($io_id.parent().hasClass('controls')){$io_id.parents('.control-group').removeClass('error');}else{$io_id.parent('.control-group').removeClass('error');}
$io_id.parent('.control-group').removeClass('error');$io_id.attr('data-original-title','');}}
function clear_validate_error(field){$(field).removeClass('tooltip-error');$(field).parents('.control-group').removeClass('error');$(field).attr('data-original-title','');}
var ipv6=/^((([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){5}:([0-9A-Fa-f]{1,4}:)?[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){4}:([0-9A-Fa-f]{1,4}:){0,2}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){3}:([0-9A-Fa-f]{1,4}:){0,3}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){2}:([0-9A-Fa-f]{1,4}:){0,4}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(([0-9A-Fa-f]{1,4}:){0,5}:((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(::([0-9A-Fa-f]{1,4}:){0,5}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|([0-9A-Fa-f]{1,4}::([0-9A-Fa-f]{1,4}:){0,5}[0-9A-Fa-f]{1,4})|(::([0-9A-Fa-f]{1,4}:){0,6}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,7}:))$/;var ipv6_unit=/^[0-9A-Fa-f]{1,4}$/;var ipv6_multicast=/^([fF][fF][0-9A-Fa-f]{2})/;var ipv6_linklocal=/^([fF][eE][89aAbB][0-9A-Fa-f]{1})/;function is_ipv6_address(ip){if(ip=='::1'||!ipv6.test(ip)){return 1;}else if(ipv6_multicast.test(ip)){return 2;}
return 0;}
function get_canonical_form(ip){var i;var result='',result2='';halves=ip.split('::');if(halves.length==1){first_unit=halves[0].split(':');for(i=0;i<first_unit.length;i++){if(first_unit[i].length==0){result+='0000';}else if(first_unit[i].length==1){result+='000'+first_unit[i];}else if(first_unit[i].length==2){result+='00'+first_unit[i];}else if(first_unit[i].length==3){result+='0'+first_unit[i];}else{result+=first_unit[i];}}}else
{first_unit=halves[0].split(':');for(i=0;i<first_unit.length;i++){if(first_unit[i].length==0){result+='0000';}else if(first_unit[i].length==1){result+='000'+first_unit[i];}else if(first_unit[i].length==2){result+='00'+first_unit[i];}else if(first_unit[i].length==3){result+='0'+first_unit[i];}else{result+=first_unit[i];}}
last_unit=halves[1].split(':');for(i=0;i<last_unit.length;i++){if(last_unit[i].length==0){result2+='0000';}else if(last_unit[i].length==1){result2+='000'+last_unit[i];}else if(last_unit[i].length==2){result2+='00'+last_unit[i];}else if(last_unit[i].length==3){result2+='0'+last_unit[i];}else{result2+=last_unit[i];}}
for(i=(first_unit.length+last_unit.length);i<8;i++){result+='0000';}
result+=result2;}
return result;}
function paddingLeft(str,len){if(str.length>=len){return str;}else{return paddingLeft('0'+str,len);}}
function is_in_netmask_ipv6(ip,subnet,gw){var i,bip='',bgw='';cip=get_canonical_form(ip);cgw=get_canonical_form(gw);for(i=0;i<cip.length;i++){bip+=paddingLeft(parseInt(cip[i],16).toString(2),4);}
for(i=0;i<cgw.length;i++){bgw+=paddingLeft(parseInt(cgw[i],16).toString(2),4);}
for(i=0;i<parseInt(subnet,10);i++){if(bip[i]!=bgw[i]){return false;}}
return true;}
function is_mac(v){return(v.match(/^([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}$/)!=null);}
function is_contained_char(c,str){var i;for(i=0;i<str.length;i++){if(str.substr(i,1)==c){return true;}}
return false;}
function is_num(str){var num_string='0123456789';var i;if(str=='0'){return true;}
if(typeof(str)=='number'){return true;}else if(typeof(str)=='string'){str=str.replace(/^0*/,'');if(str==null||str==''){return false;}}else{return false;}
for(i=0;i<str.length;i++){if(!is_contained_char(str.substr(i,1),num_string)){return false;}}
return true;}
function is_in_range(a,min,max){if(!is_num(a)||!is_num(min)||!is_num(max)){return false;}
a=parseInt(a,10);min=parseInt(min,10);max=parseInt(max,10);if(a<min||a>max){return false;}
return true;}
function countAmountAddress(subNet){var cidrToSubnets=['0.0.0.0','128.0.0.0','192.0.0.0','224.0.0.0','240.0.0.0','248.0.0.0','252.0.0.0','254.0.0.0','255.0.0.0','255.128.0.0','255.192.0.0','255.224.0.0','255.240.0.0','255.248.0.0','255.252.0.0','255.254.0.0','255.255.0.0','255.255.128.0','255.255.192.0','255.255.224.0','255.255.240.0','255.255.248.0','255.255.252.0','255.255.254.0','255.255.255.0','255.255.255.128','255.255.255.192','255.255.255.224','255.255.255.240','255.255.255.248','255.255.255.252','255.255.255.254','255.255.255.255'];var tcidr,maxAmount;for(var i=0;i<cidrToSubnets.length;i++){if(subNet===cidrToSubnets[i]){tcidr=i;break;}}
if(tcidr===32){maxAmount=1;}else{maxAmount=(Math.pow(2,(32-tcidr)))-2;}
return maxAmount;}