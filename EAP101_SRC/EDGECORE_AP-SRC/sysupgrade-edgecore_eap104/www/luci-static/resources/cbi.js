
var cbi_d=[];var cbi_t=[];var cbi_c=[];var cbi_strings={path:{},label:{}};function s8(bytes,off){var n=bytes[off];return(n>0x7F)?(n-256)>>>0:n;}
function u16(bytes,off){return((bytes[off+1]<<8)+bytes[off])>>>0;}
function sfh(s){if(s===null||s.length===0)
return null;var bytes=[];for(var i=0;i<s.length;i++){var ch=s.charCodeAt(i);if(ch<=0x7F)
bytes.push(ch);else if(ch<=0x7FF)
bytes.push(((ch>>>6)&0x1F)|0xC0,(ch&0x3F)|0x80);else if(ch<=0xFFFF)
bytes.push(((ch>>>12)&0x0F)|0xE0,((ch>>>6)&0x3F)|0x80,(ch&0x3F)|0x80);else if(code<=0x10FFFF)
bytes.push(((ch>>>18)&0x07)|0xF0,((ch>>>12)&0x3F)|0x80,((ch>>6)&0x3F)|0x80,(ch&0x3F)|0x80);}
if(!bytes.length)
return null;var hash=(bytes.length>>>0),len=(bytes.length>>>2),off=0,tmp;while(len--){hash+=u16(bytes,off);tmp=((u16(bytes,off+2)<<11)^hash)>>>0;hash=((hash<<16)^tmp)>>>0;hash+=hash>>>11;off+=4;}
switch((bytes.length&3)>>>0){case 3:hash+=u16(bytes,off);hash=(hash^(hash<<16))>>>0;hash=(hash^(s8(bytes,off+2)<<18))>>>0;hash+=hash>>>11;break;case 2:hash+=u16(bytes,off);hash=(hash^(hash<<11))>>>0;hash+=hash>>>17;break;case 1:hash+=s8(bytes,off);hash=(hash^(hash<<10))>>>0;hash+=hash>>>1;break;}
hash=(hash^(hash<<3))>>>0;hash+=hash>>>5;hash=(hash^(hash<<4))>>>0;hash+=hash>>>17;hash=(hash^(hash<<25))>>>0;hash+=hash>>>6;return(0x100000000+hash).toString(16).substr(1);}
var plural_function=null;function trimws(s){return String(s).trim().replace(/[ \t\n]+/g,' ');}
function _(s,c){var k=(c!=null?trimws(c)+'\u0001':'')+trimws(s);return(window.TR&&TR[sfh(k)])||s;}
function N_(n,s,p,c){if(plural_function==null&&window.TR)
plural_function=new Function('n',(TR['00000000']||'plural=(n != 1);')+'return +plural');var i=plural_function?plural_function(n):(n!=1),k=(c!=null?trimws(c)+'\u0001':'')+trimws(s)+'\u0002'+i.toString();return(window.TR&&TR[sfh(k)])||(i?p:s);}
var port_min=0;var port_max=65535;var is_ipv4_flag=true;var is_netmask_flag=true;var is_not_broadcast_flag=true;var is_not_network_flag=true;var ZERO_NO=1;var ZERO_OK=2;var MASK_NO=4;var MASK_OK=8;var LOOPBACK_IP_OK=16;function getUtf8Length(s){return~-encodeURI(s).split(/%..|./).length;}
function is_contained_char(c,str){var i;for(i=0;i<str.length;i++){if(str.substr(i,1)==c){return true;}}
return false;}
var cbi_validators={'integer':function(v){return(v.match(/^-?[0-9]+$/)!=null);},'uinteger':function(v){return(cbi_validators.integer(v)&&(v>=0));},'float':function(v){return!isNaN(parseFloat(v));},'ufloat':function(v){return(cbi_validators['float'](v)&&(v>=0));},'ipaddr':function(v,args){return cbi_validators.ip4addr(v,args)||cbi_validators.ip6addr(v);},'firewall_ipv4':function(v){var ipv4_result=false;if(v.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)(\/(\d+))?$/)){ipv4_result=(RegExp.$1>=0)&&(RegExp.$1<=255)&&(RegExp.$2>=0)&&(RegExp.$2<=255)&&(RegExp.$3>=0)&&(RegExp.$3<=255)&&(RegExp.$4>=0)&&(RegExp.$4<=255)&&(!RegExp.$5||((RegExp.$6>=0)&&(RegExp.$6<=32)));}
return ipv4_result;},'firewall_ipaddr':function(v){return cbi_validators.firewall_ipv4(v)||cbi_validators.ip6addr(v);},'neg_ipaddr':function(v){return cbi_validators.ip4addr(v.replace(/^\s*!/,''))||cbi_validators.ip6addr(v.replace(/^\s*!/,''));},'ip4addr':function(v,args){var flag=args;var str=v;var re=/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;if(typeof(flag)=='undefined'||flag==null){flag=ZERO_NO|MASK_NO;}
if(re.test(str)){if((flag&ZERO_OK)&&str=='0.0.0.0'){return true;}
if((flag&LOOPBACK_IP_OK)&&str=='127.0.0.1'){return true;}
if(str!='0.0.0.0'&&(flag&MASK_NO)&&RegExp.$4==0){return false;}
if(RegExp.$1==127){return false;}
if(RegExp.$1>223){return false;}
if(RegExp.$1==0){return false;}
if(RegExp.$2==0&&RegExp.$3==0&&RegExp.$4==0){return false;}
if(RegExp.$2==255&&RegExp.$3==255&&RegExp.$4==255){return false;}
if(RegExp.$1.length>=2){if(RegExp.$1.indexOf('0')==0){return false;}}
if(RegExp.$2.length>=2){if(RegExp.$2.indexOf('0')==0){return false;}}
if(RegExp.$3.length>=2){if(RegExp.$3.indexOf('0')==0){return false;}}
if(RegExp.$4.length>=2){if(RegExp.$4.indexOf('0')==0){return false;}}
if(RegExp.$1<256&&RegExp.$2<256&&RegExp.$3<256&&RegExp.$4<256){return true;}}
return false;},'neg_ip4addr':function(v){return cbi_validators.ip4addr(v.replace(/^\s*!/,''));},'ip6addr':function(v){if(v.match(/^([a-fA-F0-9:.]+)(\/(\d+))?$/)){if(!RegExp.$2||((RegExp.$3>=0)&&(RegExp.$3<=128))){var addr=RegExp.$1;if(addr=='::'){return true;}
if(addr.indexOf('.')>0){var off=addr.lastIndexOf(':');if(!(off&&cbi_validators.ip4addr(addr.substr(off+1)))){return false;}
addr=addr.substr(0,off)+':0:0';}
if(addr.indexOf('::')>=0){var colons=0;var fill='0';for(var i=1;i<(addr.length-1);i++){if(addr.charAt(i)==':'){colons++;}}
if(colons>7){return false;}
for(var i=0;i<(7-colons);i++){fill+=':0';}
if(addr.match(/^(.*?)::(.*?)$/)){addr=(RegExp.$1?RegExp.$1+':':'')+fill+
(RegExp.$2?':'+RegExp.$2:'');}}
return(addr.match(/^(?:[a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}$/)!=null);}}
return false;},'port':function(v){return cbi_validators.integer(v)&&(v>=port_min)&&(v<=port_max);},'netmask':function(netmaskstr){var re=/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;if(re.test(netmaskstr)){var correct_range={128:1,192:1,224:1,240:1,248:1,252:1,254:1,255:1,0:1};var str_sp=netmaskstr.split('.');for(var i=0;i<=3;i++){if(!(str_sp[i]in correct_range)){return false;}}
if((str_sp[0]==='0')||(str_sp[0]!=='255'&&str_sp[1]!=='0')||(str_sp[1]!=='255'&&str_sp[2]!=='0')||(str_sp[2]!=='255'&&str_sp[3]!=='0')){return false;}
var buf=str_sp[0].toString(2)+str_sp[1].toString(2)+
str_sp[2].toString(2)+str_sp[3].toString(2);for(i=0;i<buf.length-2;i++){if(buf.substr(i,2)==='01'){return false;}}
return true;}
return false;},'portrange':function(v){if(v.match(/^(\d+)(?:-|:)(\d+)$/)){var p1=RegExp.$1;var p2=RegExp.$2;return cbi_validators.port(p1)&&cbi_validators.port(p2)&&(parseInt(p1)<=parseInt(p2));}else{return cbi_validators.port(v);}},'macaddr':function(v){return(v.match(/^([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}$/)!=null);},'host':function(v,args){return cbi_validators.isDomain(v)||cbi_validators.ipaddr(v,args);},'isDomain':function(v){var DOMAIN_NAME_REGX=/^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$/;if(v.length<3||v.length>254){return false;}
if(!DOMAIN_NAME_REGX.test(v)){return false;}
return true;},'network':function(v){return cbi_validators.uciname(v)||cbi_validators.host(v);},'username':function(v){return(v.length>=1)&&(v.length<=32)&&v.match(/^[a-zA-Z0-9\-_.]+$/)&&!v.match(/^\-/);},'login_username':function(v){return(v.length>=1)&&(v.length<=32)&&v.match(/^[a-zA-Z0-9\-_.]+$/)&&!v.match(/^\-/)&&!v.match(/^\./);},'wpakey':function(v){if(v.length==64){return(v.match(/^[a-fA-F0-9]{64}$/)!=null);}else{return(v.length>=8)&&(v.length<=63);}},'wepkey':function(v){if(v.substr(0,2)=='s:'){v=v.substr(2);}
if((v.length==10)||(v.length==26)){return(v.match(/^[a-fA-F0-9]{10,26}$/)!=null);}else{return(v.length==5)||(v.length==13);}},'uciname':function(v){return(v.match(/^[a-zA-Z0-9_]+$/)!=null);},'neg_network_ip4addr':function(v){v=v.replace(/^\s*!/,'');return cbi_validators.uciname(v)||cbi_validators.ip4addr(v);},'range':function(v,args){var rangeMin=parseInt(args[0]);var rangeMax=parseInt(args[1]);return cbi_validators.integer(v)&&(v>=rangeMin)&&(v<=rangeMax);},'min':function(v,args){var min=parseInt(args[0]);var val=parseInt(v);if(!isNaN(min)&&!isNaN(val)){return(val>=min);}
return false;},'max':function(v,args){var max=parseInt(args[0]);var val=parseInt(v);if(!isNaN(max)&&!isNaN(val)){return(val<=max);}
return false;},'neg':function(v,args){if(args[0]&&typeof cbi_validators[args[0]]=='function'){return cbi_validators[args[0]](v.replace(/^\s*!\s*/,''));}
return false;},'no_whitespace_str':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);return typeof v=='string'&&v.length>=min&&v.length<=max&&v.indexOf(' ')<0;},'hotspot_simple_pass':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);return typeof v=='string'&&v.length>=min&&v.length<=max&&v.indexOf(':')<0&&v.indexOf(' ')<0;},'limited_len_str':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);var check_bytes=!!args[2];var length;if(typeof v!='string'){return false;}
length=check_bytes?getUtf8Length(v):v.length;return length>=min&&length<=max;},'hostname_str':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);return typeof v=='string'&&v.length>=min&&v.length<=max&&(v.match(/^[a-zA-Z0-9-]+$/)!=null);},'list':function(v,args){var cb=cbi_validators[args[0]||'string'];if(typeof cb=='function'){var cbargs=args.slice(1);var values=v.match(/[^\s]+/g);for(var i=0;i<values.length;i++){if(!cb(values[i],cbargs)){return false;}}
return true;}
return false;},'is_broadcast':function(v,args){var netmask=args;is_not_broadcast_flag=true;if(is_broadcast(v,netmask)){is_not_broadcast_flag=false;return false;}else{return true;}},'is_network':function(v,args){var netmask=args;is_not_network_flag=true;if(is_net(v,netmask)){is_not_network_flag=false;return false;}else{return true;}},'custom_ip':function(v,args){var netmask=args[0];is_ipv4_flag=true;if(!cbi_validators.ip4addr(v)){is_ipv4_flag=false;return false;}
if(!cbi_validators.is_broadcast(v,netmask)){return false;}
if(!cbi_validators.is_network(v,netmask)){return false;}
return true;},'custom_netmask':function(v,args){if(args==undefined){return true;}
var ip_address=args;is_netmask_flag=true;if(!cbi_validators.netmask(v)){is_netmask_flag=false;return false;}
if(!cbi_validators.is_broadcast(ip_address,v)){return false;}
if(!cbi_validators.is_network(ip_address,v)){return false;}
return true;},'custom_dns':function(v){var tmp_arr=v.split(' ');for(var i=0;i<tmp_arr.length;i++){if(!cbi_validators.ipaddr(tmp_arr[i])){return false;}}
if(tmp_arr.length>4){return false;}
return true;},'is_ascii':function(v,args){var str=v;var num_string='0123456789';var ascii=' ~!@$%^*()_+-=[]{}|:;<>?,./'+'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';var valid_string=num_string+ascii;var i;for(i=0;i<str.length;i++){if(!is_contained_char(str.substr(i,1),valid_string)){return false;}}
if(args){return cbi_validators.limited_len_str(v,args);}
return true;},'isURL':function(v,args){var strRegex=/^((https|http)?:\/\/)(([0-9]{1,3}.){3}[0-9]{1,3}|((.[a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9]))(:[0-9]{1,5})?((\/?)|(\/[0-9a-zA-Z_!~*\'().;?:@&=+$,%#-]+)+\/?)$/;return strRegex.test(v)&&(v.indexOf(' ')==-1);},'isBeginningWhiteSpace':function(v){if(v==''){return false;}
return!/^\s/.test(v);},'customHost':function(v){if(v!='127.0.0.1'){return cbi_validators.isDomain(v)||cbi_validators.ipaddr(v);}
return true;},};var cbi_validator_messages={'integer':function(v){if(!v){return _('Not a valid number!');}
return'';},'uinteger':function(v){if(!v){return _('Not a valid positive number!');}
return'';},'float':function(v){if(!v){return _('Not a valid number!');}
return'';},'ufloat':function(v){if(!v){return _('Not a valid positive number!');}
return'';},'ipaddr':function(v){if(!v){return _('Not a valid IP address!');}
return'';},'firewall_ipv4':function(v){if(!v){return _('Not a valid IPv4 address!');}
return'';},'firewall_ipaddr':function(v){if(!v){return _('Not a valid IP address!');}
return'';},'neg_ipaddr':function(v){if(!v){return _('Not a valid IP address!');}
return'';},'ip4addr':function(v){if(!v){return _('Not a valid IPv4 address!');}
return'';},'neg_ip4addr':function(v){if(!v){return _('Not a valid IPv4 address!');}
return'';},'ip6addr':function(v){if(!v){return _('Not a valid IPv6 address!');}
return'';},'port':function(v){if(!v){return _('Not a valid port range! Allowed values are integers between %d and %d, inclusive.').format(port_min,port_max);}
return'';},'netmask':function(v){if(!v){return _('Not a valid netmask!');}
return'';},'portrange':function(v){if(!v){return _('Not a valid port range! Allowed values are integers between %d and %d, inclusive.').format(port_min,port_max);}
return'';},'macaddr':function(v){if(!v){return _('Not a valid MAC address!');}
return'';},'host':function(v){if(!v){return _('Not a valid host or IP address!');}
return'';},'network':function(v){if(!v){return _('Not a valid network.');}
return'';},'username':function(v){if(!v){return _('Must be between 1 and 32 ASCII characters. Only accept A-Z, a-z, 0-9, Period (.), Underscore (_) and Hyphen (-), but NOT allow username that begin with Hyphen (-).');}
return'';},'login_username':function(v){if(!v){return _('Must be between 1 and 32 ASCII characters. Only accept A-Z, a-z, 0-9, Period (.), Underscore (_) and Hyphen (-), but NOT allow username that begins with Hyphen (-) and Period (.).');}
return'';},'no_whitespace_str':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);if(!v){return _('This value must be between %d and %d characters long, and not include whitespace.').format(min,max);}
return'';},'hotspot_simple_pass':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);if(!v){return _('This value must be between %d and %d characters long, and not include colons or whitespace.').format(min,max)}
return'';},'limited_len_str':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);if(!v){return _('This value must be between %d and %d characters long.').format(min,max);}
return'';},'hostname_str':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);if(!v){return _('This value must be between %d and %d characters long.').format(min,max)+
_('The only characters allowed in the device hostname are ASCII letters, numbers, and dashes.');}
return'';},'wpakey':function(v){if(!v){return _('Not a valid WPA key! Value must be between 8 and 63 ASCII (letters and numbers) characters long or 64 Hex characters.');}
return'';},'wepkey':function(v){if(!v){return _('Not a valid WEP key! For 64-bit WEP, length must be 5 ASCII (letters and numbers) characters or 10 hex digits long. For 128-bit, length must be 13 ASCII characters or 26 hex digits.');}
return'';},'uciname':function(v){if(!v){return _('Not a valid config name!');}
return'';},'neg_network_ip4addr':function(v){if(!v){return _('Not a valid network or IPv4 address!');}
return'';},'range':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);if(!v&&!isNaN(min)&&!isNaN(max)){return _('Allowed values are integers between %d and %d, inclusive.').format(min,max);}else if(!v){return _('Value not allowed!');}
return'';},'min':function(v,args){var min=parseInt(args[0]);if(!v&&!isNaN(min)){return _('Value must be greater than or equal to %d.').format(min);}else if(!v){return _('Value not allowed!');}
return'';},'max':function(v,args){var max=parseInt(args[0]);if(!v&&!isNaN(max)){return _('Value must be less than or equal to %d.').format(max);}else if(!v){return _('Value not allowed!');}
return'';},'neg':function(v,args){if(!v){return _('Invalid value!');}
return'';},'list':function(v,args){if(!v){return _('Invalid list!');}
return'';},'is_broadcast':function(v){if(!v){return _('IP address is a broadcast IP.');}
return'';},'is_network':function(v){if(!v){return _('Not a valid network.');}
return'';},'custom_ip':function(v){if(!v){if(!is_ipv4_flag){return _('Not a valid IPv4 address!');}
if(!is_netmask_flag){return _('Not a valid netmask!');}
if(!is_not_broadcast_flag){return _('IP address is a broadcast IP.');}
if(!is_not_network_flag){return _('Not a valid network.');}}
return'';},'custom_netmask':function(v){if(!v){if(!is_netmask_flag){return _('Not a valid netmask!');}
if(!is_not_broadcast_flag){return _('IP address is a broadcast IP.');}
if(!is_not_network_flag){return _('Not a valid network.');}}
return'';},'custom_dns':function(v){if(!v){return _('Not a valid IP address or DNS servers exceed 4.');}
return'';},'is_ascii':function(v,args){var strleng_msg='';if(args&&args[0]&&args[1]){var min=parseInt(args[0]);var max=parseInt(args[1]);strleng_msg='This value must be between '+min+' and '+max+' characters long.';}
if(!v){return strleng_msg+_(' Only accept A-Z, a-z, 0-9, space, and ~!@$%^*()_+-=[]{}|:;<>?,./');}
return'';},'isDomain':function(v,args){if(!v){return _('Not a valid Domain Name.');}
return'';},'isURL':function(v,args){if(!v){return _('The URL format is invalid.');}
return'';},'isBeginningWhiteSpace':function(v){if(!v){return _('Not accept white space character at the beginning.');}
return'';},'customHost':function(v){if(!v){return _('Not a valid host or IP address!');}
return'';},};function cbi_d_add(field,dep,next){var obj=(typeof(field)==='string')?document.getElementById(field):field;if(obj){var entry
for(var i=0;i<cbi_d.length;i++){if(cbi_d[i].id==obj.id){entry=cbi_d[i];break;}}
if(!entry){entry={'node':obj,'id':obj.id,'parent':obj.parentNode.id,'deps':[],'next':next};cbi_d.unshift(entry);}
entry.deps.push(dep)}}
function cbi_d_checkvalue(target,ref){var value=null,query='input[id="'+target+'"], input[name="'+target+'"], '+'select[id="'+target+'"], select[name="'+target+'"]';document.querySelectorAll(query).forEach(function(i){if(value===null&&((i.type!=='radio'&&i.type!=='checkbox')||i.checked===true))
value=i.value;});return(((value!==null)?value:"")==ref);}
function cbi_d_check(deps){var reverse;var def=false;for(var i=0;i<deps.length;i++){var istat=true;reverse=false;for(var j in deps[i]){if(j=="!reverse"){reverse=true;}else if(j=="!default"){def=true;istat=false;}else{istat=(istat&&cbi_d_checkvalue(j,deps[i][j]))}}
if(istat^reverse){return true;}}
return def;}
function cbi_d_update(id){var state=false;for(var i=0;i<cbi_d.length;i++){var entry=cbi_d[i];var node=document.getElementById(entry.id);var next=document.getElementById(entry.next);var parent=document.getElementById(entry.parent);if(parent==null){continue;}
if(node&&node.parentNode&&!cbi_d_check(entry.deps)){node.parentNode.removeChild(node);state=true;if(entry.parent){cbi_c[entry.parent]--;}}else if((!node||!node.parentNode||$(node).hasClass('hidden'))&&cbi_d_check(entry.deps)){if($(node).hasClass('hidden')){$(node).removeClass('hidden');}else if(!next){parent.appendChild(entry.node);}else{$(entry.node).hide();next.parentNode.insertBefore(entry.node,next);$(entry.node).slideDown();var nn=$(entry.node).find('[data-rel=tooltip]').tooltip();}
state=true;if(entry.parent){cbi_c[entry.parent]++;}}}
if(entry&&entry.parent){if(!cbi_t_update()){cbi_tag_last(parent);}}
if(state){cbi_d_update();}}
function cbi_init(){var nodes;document.querySelectorAll('.cbi-dropdown').forEach(function(node){cbi_dropdown_init(node);node.addEventListener('cbi-dropdown-change',cbi_d_update);});nodes=document.querySelectorAll('[data-strings]');for(var i=0,node;(node=nodes[i])!==undefined;i++){var str=JSON.parse(node.getAttribute('data-strings'));for(var key in str){for(var key2 in str[key]){var dst=cbi_strings[key]||(cbi_strings[key]={});dst[key2]=str[key][key2];}}}
nodes=document.querySelectorAll('[data-depends]');for(var i=0,node;(node=nodes[i])!==undefined;i++){var index=parseInt(node.getAttribute('data-index'),10);var depends=JSON.parse(node.getAttribute('data-depends'));if(!isNaN(index)&&depends.length>0){for(var alt=0;alt<depends.length;alt++)
cbi_d_add(node,depends[alt],index);}}
nodes=document.querySelectorAll('[data-update]');for(var i=0,node;(node=nodes[i])!==undefined;i++){var events=node.getAttribute('data-update').split(' ');for(var j=0,event;(event=events[j])!==undefined;j++)
node.addEventListener(event,cbi_d_update);}
nodes=document.querySelectorAll('[data-choices]');for(var i=0,node;(node=nodes[i])!==undefined;i++){var choices=JSON.parse(node.getAttribute('data-choices')),options={};for(var j=0;j<choices[0].length;j++)
options[choices[0][j]]=choices[1][j];var def=(node.getAttribute('data-optional')==='true')?node.placeholder||'':null;var cb=new L.ui.Combobox(node.value,options,{name:node.getAttribute('name'),sort:choices[0],select_placeholder:def||_('-- Please choose --'),custom_placeholder:node.getAttribute('data-manual')||_('-- custom --')});var n=cb.render();n.addEventListener('cbi-dropdown-change',cbi_d_update);node.parentNode.replaceChild(n,node);}
nodes=document.querySelectorAll('[data-dynlist]');for(var i=0,node;(node=nodes[i])!==undefined;i++){var choices=JSON.parse(node.getAttribute('data-dynlist')),values=JSON.parse(node.getAttribute('data-values')||'[]'),options=null;if(choices[0]&&choices[0].length){options={};for(var j=0;j<choices[0].length;j++)
options[choices[0][j]]=choices[1][j];}
var dl=new L.ui.DynamicList(values,options,{name:node.getAttribute('data-prefix'),sort:choices[0],datatype:choices[2],optional:choices[3],placeholder:node.getAttribute('data-placeholder')});var n=dl.render();n.addEventListener('cbi-dynlist-change',cbi_d_update);node.parentNode.replaceChild(n,node);}
nodes=document.querySelectorAll('[data-type]');for(var i=0,node;(node=nodes[i])!==undefined;i++){cbi_validate_field(node,node.getAttribute('data-optional')==='true',node.getAttribute('data-type'));}
document.querySelectorAll('.cbi-tooltip:not(:empty)').forEach(function(s){s.parentNode.classList.add('cbi-tooltip-container');});document.querySelectorAll('.cbi-section-remove > input[name^="cbi.rts"]').forEach(function(i){var handler=function(ev){var bits=this.name.split(/\./),section=document.getElementById('cbi-'+bits[2]+'-'+bits[3]);section.style.opacity=(ev.type==='mouseover')?0.5:'';};i.addEventListener('mouseover',handler);i.addEventListener('mouseout',handler);});var tasks=[];document.querySelectorAll('[data-ui-widget]').forEach(function(node){var args=JSON.parse(node.getAttribute('data-ui-widget')||'[]'),widget=new(Function.prototype.bind.apply(L.ui[args[0]],args)),markup=widget.render();tasks.push(Promise.resolve(markup).then(function(markup){markup.addEventListener('widget-change',cbi_d_update);node.parentNode.replaceChild(markup,node);}));});Promise.all(tasks).then(cbi_d_update);}
function cbi_t_update(){var hl_tabs=[];var updated=false;for(var sid in cbi_t){for(var tid in cbi_t[sid]){if(cbi_c[cbi_t[sid][tid].cid]==0){cbi_t[sid][tid].tab.style.display='none';}else if(cbi_t[sid][tid].tab&&cbi_t[sid][tid].tab.style.display=='none'){cbi_t[sid][tid].tab.style.display='';var t=cbi_t[sid][tid].tab;t.className+=' cbi-tab-highlighted';hl_tabs.push(t);}
cbi_tag_last(cbi_t[sid][tid].container);updated=true;}}
if(hl_tabs.length>0){window.setTimeout(function(){for(var i=0;i<hl_tabs.length;i++){hl_tabs[i].className=hl_tabs[i].className.replace(/ cbi-tab-highlighted/g,'');}},750);}
return updated;}
function cbi_validate_form(form,errmsg,error_placeholder){$('#form_error_msg_placeholder').addClass('hide');if(form.cbi_state=='add-section'||form.cbi_state=='del-section')
return true;var res=true;if(form.cbi_validators){for(var i=0;i<form.cbi_validators.length;i++){var validator=form.cbi_validators[i];if((!validator()&&errmsg)){cbi_show_form_error(error_placeholder,errmsg);res=false;}}}
return res;}
function cbi_show_form_error(error_placeholder,errmsg){if(error_placeholder==null){error_placeholder='form_error_msg_placeholder';}
if(errmsg==null){errmsg=_('Some fields are invalid, please see messages below!');}
var shown=false;var div=$('#'+error_placeholder);if(div.length){var err_span=div.find('span');if(err_span.length){shown=true;err_span.html(errmsg);div.removeClass('hide');window.scrollTo(0,0);}}
if(!shown){alert(errmsg);}}
function cbi_validate_reset(form)
{window.setTimeout(function(){cbi_validate_form(form,null)},100);return true;}
function cbi_validate_field(cbid,f_optional,type){var field=(typeof cbid=='string')?document.getElementById(cbid):cbid;var vargs;if(type.match(/^(\w+)\(([^\(\)]+)\)/)){type=RegExp.$1;vargs=RegExp.$2.split(/\s*,\s*/);}
var vldcb=cbi_validators[type];var msgcb=cbi_validator_messages[type];if(field&&vldcb){var validator=function(){var optional=$.isFunction(f_optional)?f_optional():f_optional;if(field.form){$(field).removeClass('tooltip-error');if($(field).parent().hasClass('controls')){$(field).parents('.cbi-value').removeClass('error');}else{$(field).closest('.cbi-value').removeClass('error');}
$(field).attr('data-original-title','');var value=(field.options&&field.options.selectedIndex>-1)?field.options[field.options.selectedIndex].value:field.value;if($(field).attr('deleted')!='deleted'){if(!(((value.length==0)&&optional)||vldcb(value,vargs))){if(value.length==0&&!optional){$(field).attr('data-original-title',_('This field is required.'));}else{$(field).attr('data-original-title',msgcb(false,vargs));}
if($(field).parent().hasClass('controls')){$(field).parents('.cbi-value').addClass('error');}else{$(field).closest('.cbi-value').addClass('error');}
$(field).addClass('tooltip-error');$(field).attr('data-trigger','focus');$(field).tooltip();return false;}}}
return true;};if(!field.form.cbi_validators){field.form.cbi_validators=[];}
field.form.cbi_validators.push(validator);cbi_bind(field,'blur',validator);cbi_bind(field,'keyup',validator);if(field.nodeName=='SELECT'){cbi_bind(field,'change',validator);cbi_bind(field,'click',validator);}
var optional=$.isFunction(f_optional)?f_optional():f_optional;field.setAttribute('cbi_validate',validator);field.setAttribute('cbi_datatype',type);field.setAttribute('cbi_optional',(!!optional).toString());validator();var fcbox=document.getElementById('cbi.combobox.'+field.id);if(fcbox){cbi_validate_field(fcbox,f_optional,type);}}}
function cbi_row_swap(elem,up,store)
{var tr=findParent(elem.parentNode,'.cbi-section-table-row');if(!tr)
return false;tr.classList.remove('flash');if(up){var prev=tr.previousElementSibling;if(prev&&prev.classList.contains('cbi-section-table-row'))
tr.parentNode.insertBefore(tr,prev);else
return;}
else{var next=tr.nextElementSibling?tr.nextElementSibling.nextElementSibling:null;if(next&&next.classList.contains('cbi-section-table-row'))
tr.parentNode.insertBefore(tr,next);else if(!next)
tr.parentNode.appendChild(tr);else
return;}
var ids=[];for(var i=0,n=0;i<tr.parentNode.childNodes.length;i++){var node=tr.parentNode.childNodes[i];if(node.classList&&node.classList.contains('cbi-section-table-row')){node.classList.remove('cbi-rowstyle-1');node.classList.remove('cbi-rowstyle-2');node.classList.add((n++%2)?'cbi-rowstyle-2':'cbi-rowstyle-1');if(/-([^\-]+)$/.test(node.id))
ids.push(RegExp.$1);}}
var input=document.getElementById(store);if(input)
input.value=ids.join(' ');window.scrollTo(0,tr.offsetTop);void tr.offsetWidth;tr.classList.add('flash');return false;}
function cbi_tag_last(container)
{var last;for(var i=0;i<container.childNodes.length;i++){var c=container.childNodes[i];if(matchesElem(c,'div')){c.classList.remove('cbi-value-last');last=c;}}
if(last)
last.classList.add('cbi-value-last');}
function cbi_submit(elem,name,value,action)
{var form=elem.form||findParent(elem,'form');if(!form)
return false;if(action)
form.action=action;var res=cbi_validate_form(form,'Some fields are invalid, cannot save values!');if(res){if($.isFunction(window.before_submit)){if(!before_submit()){return false}}
if(name){var hidden=form.querySelector('input[type="hidden"][name="%s"]'.format(name))||E('input',{type:'hidden',name:name});hidden.value=value||'1';form.appendChild(hidden);}
form.submit();}
return res;}
String.prototype.format=function()
{if(!RegExp)
return;var html_esc=[/&/g,'&#38;',/"/g,'&#34;',/'/g,'&#39;',/</g,'&#60;',/>/g,'&#62;'];var quot_esc=[/"/g,'&#34;',/'/g,'&#39;'];function esc(s,r){if(typeof(s)!=='string'&&!(s instanceof String))
return'';for(var i=0;i<r.length;i+=2)
s=s.replace(r[i],r[i+1]);return s;}
var str=this;var out='';var re=/^(([^%]*)%('.|0|\x20)?(-)?(\d+)?(\.\d+)?(%|b|c|d|u|f|o|s|x|X|q|h|j|t|m))/;var a=b=[],numSubstitutions=0,numMatches=0;while(a=re.exec(str)){var m=a[1];var leftpart=a[2],pPad=a[3],pJustify=a[4],pMinLength=a[5];var pPrecision=a[6],pType=a[7];numMatches++;if(pType=='%'){subst='%';}
else{if(numSubstitutions<arguments.length){var param=arguments[numSubstitutions++];var pad='';if(pPad&&pPad.substr(0,1)=="'")
pad=leftpart.substr(1,1);else if(pPad)
pad=pPad;else
pad=' ';var justifyRight=true;if(pJustify&&pJustify==="-")
justifyRight=false;var minLength=-1;if(pMinLength)
minLength=+pMinLength;var precision=-1;if(pPrecision&&pType=='f')
precision=+pPrecision.substring(1);var subst=param;switch(pType){case'b':subst=Math.floor(+param||0).toString(2);break;case'c':subst=String.fromCharCode(+param||0);break;case'd':subst=Math.floor(+param||0).toFixed(0);break;case'u':var n=+param||0;subst=Math.floor((n<0)?0x100000000+n:n).toFixed(0);break;case'f':subst=(precision>-1)?((+param||0.0)).toFixed(precision):(+param||0.0);break;case'o':subst=Math.floor(+param||0).toString(8);break;case's':subst=param;break;case'x':subst=Math.floor(+param||0).toString(16).toLowerCase();break;case'X':subst=Math.floor(+param||0).toString(16).toUpperCase();break;case'h':subst=esc(param,html_esc);break;case'q':subst=esc(param,quot_esc);break;case't':var td=0;var th=0;var tm=0;var ts=(param||0);if(ts>60){tm=Math.floor(ts/60);ts=(ts%60);}
if(tm>60){th=Math.floor(tm/60);tm=(tm%60);}
if(th>24){td=Math.floor(th/24);th=(th%24);}
subst=(td>0)?String.format('%dd %dh %dm %ds',td,th,tm,ts):String.format('%dh %dm %ds',th,tm,ts);break;case'm':var mf=pMinLength?+pMinLength:1000;var pr=pPrecision?~~(10* +('0'+pPrecision)):2;var i=0;var val=(+param||0);var units=[' ',' K',' M',' G',' T',' P',' E'];for(i=0;(i<units.length)&&(val>mf);i++)
val/=mf;subst=(i?val.toFixed(pr):val)+units[i];pMinLength=null;break;}}}
if(pMinLength){subst=subst.toString();for(var i=subst.length;i<pMinLength;i++)
if(pJustify=='-')
subst=subst+' ';else
subst=pad+subst;}
out+=leftpart+subst;str=str.substr(m.length);}
return out+str;}
String.prototype.nobr=function()
{return this.replace(/[\s\n]+/g,'&#160;');}
String.format=function()
{var a=[];for(var i=1;i<arguments.length;i++)
a.push(arguments[i]);return''.format.apply(arguments[0],a);}
String.nobr=function()
{var a=[];for(var i=1;i<arguments.length;i++)
a.push(arguments[i]);return''.nobr.apply(arguments[0],a);}
if(window.NodeList&&!NodeList.prototype.forEach){NodeList.prototype.forEach=function(callback,thisArg){thisArg=thisArg||window;for(var i=0;i<this.length;i++){callback.call(thisArg,this[i],i,this);}};}
if(!window.requestAnimationFrame){window.requestAnimationFrame=function(f){window.setTimeout(function(){f(new Date().getTime())},1000/30);};}
function isElem(e){return L.dom.elem(e)}
function toElem(s){return L.dom.parse(s)}
function matchesElem(node,selector){return L.dom.matches(node,selector)}
function findParent(node,selector){return L.dom.parent(node,selector)}
function E(){return L.dom.create.apply(L.dom,arguments)}
if(typeof(window.CustomEvent)!=='function'){function CustomEvent(event,params){params=params||{bubbles:false,cancelable:false,detail:undefined};var evt=document.createEvent('CustomEvent');evt.initCustomEvent(event,params.bubbles,params.cancelable,params.detail);return evt;}
CustomEvent.prototype=window.Event.prototype;window.CustomEvent=CustomEvent;}
function cbi_dropdown_init(sb){if(sb&&L.dom.findClassInstance(sb)instanceof L.ui.Dropdown)
return;var dl=new L.ui.Dropdown(sb,null,{name:sb.getAttribute('name')});return dl.bind(sb);}
function cbi_update_table(table,data,placeholder){var target=isElem(table)?table:document.querySelector(table);if(!isElem(target))
return;target.querySelectorAll('.tr.table-titles, .cbi-section-table-titles').forEach(function(thead){var titles=[];thead.querySelectorAll('.th').forEach(function(th){titles.push(th);});if(Array.isArray(data)){var n=0,rows=target.querySelectorAll('.tr');data.forEach(function(row){var trow=E('div',{'class':'tr'});for(var i=0;i<titles.length;i++){var text=(titles[i].innerText||'').trim();var td=trow.appendChild(E('div',{'class':titles[i].className,'data-title':(text!=='')?text:null},row[i]||''));td.classList.remove('th');td.classList.add('td');}
trow.classList.add('cbi-rowstyle-%d'.format((n++%2)?2:1));if(rows[n])
target.replaceChild(trow,rows[n]);else
target.appendChild(trow);});while(rows[++n])
target.removeChild(rows[n]);if(placeholder&&target.firstElementChild===target.lastElementChild){var trow=target.appendChild(E('div',{'class':'tr placeholder'}));var td=trow.appendChild(E('div',{'class':titles[0].className},placeholder));td.classList.remove('th');td.classList.add('td');}}
else{thead.parentNode.style.display='none';thead.parentNode.querySelectorAll('.tr, .cbi-section-table-row').forEach(function(trow){if(trow!==thead){var n=0;trow.querySelectorAll('.th, .td').forEach(function(td){if(n<titles.length){var text=(titles[n++].innerText||'').trim();if(text!=='')
td.setAttribute('data-title',text);}});}});thead.parentNode.style.display='';}});}
function showModal(title,children)
{return L.showModal(title,children);}
function hideModal()
{return L.hideModal();}
document.addEventListener('DOMContentLoaded',function(){document.addEventListener('validation-failure',function(ev){if(ev.target===document.activeElement)
L.showTooltip(ev);});document.addEventListener('validation-success',function(ev){if(ev.target===document.activeElement)
L.hideTooltip(ev);});document.querySelectorAll('.table').forEach(cbi_update_table);});function cbi_bind(obj,type,callback,mode){if(!obj.addEventListener){obj.attachEvent('on'+type,function(){var e=window.event;if(!e.target&&e.srcElement){e.target=e.srcElement;}
return!!callback(e);});}else{obj.addEventListener(type,callback,!!mode);}
return obj;}
function cbi_combobox(id,values,def,man){var selid='cbi.combobox.'+id;if(document.getElementById(selid)){return;}
var obj=document.getElementById(id);var sel=document.createElement('select');sel.id=selid;sel.className='cbi-input-select';if(obj.nextSibling){obj.parentNode.insertBefore(sel,obj.nextSibling);}else{obj.parentNode.appendChild(sel);}
var dt=obj.getAttribute('cbi_datatype');var op=obj.getAttribute('cbi_optional');if(dt){cbi_validate_field(sel,op=='true',dt);}
if(!values[obj.value]){if(obj.value==''){var optdef=document.createElement('option');optdef.value='';optdef.appendChild(document.createTextNode(def));sel.appendChild(optdef);}else{var opt=document.createElement('option');opt.value=obj.value;opt.selected='selected';opt.appendChild(document.createTextNode(obj.value));sel.appendChild(opt);}}
for(var i in values){var opt=document.createElement('option');opt.value=i;if(obj.value==i){opt.selected='selected';}
opt.appendChild(document.createTextNode(values[i]));sel.appendChild(opt);}
var optman=document.createElement('option');optman.value='';optman.appendChild(document.createTextNode(man));sel.appendChild(optman);obj.style.display='none';cbi_bind(sel,'change',function(){if(sel.selectedIndex==sel.options.length-1){obj.style.display='inline';sel.parentNode.removeChild(sel);obj.focus();}else{obj.value=sel.options[sel.selectedIndex].value;}
try{cbi_d_update();}catch(e){}});}
function cbi_combobox_init(id,values,def,man){var obj=document.getElementById(id);cbi_bind(obj,'blur',function(){cbi_combobox(id,values,def,man);});cbi_combobox(id,values,def,man);}