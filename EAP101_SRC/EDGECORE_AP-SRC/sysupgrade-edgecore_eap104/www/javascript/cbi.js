
var test_num=-1;var cbi_d=[];var cbi_t=[];var cbi_c=[];var port_min=0;var port_max=65535;var is_ipv4_flag=true;var is_netmask_flag=true;var is_not_broadcast_flag=true;var is_not_network_flag=true;var ZERO_NO=1;var ZERO_OK=2;var MASK_NO=4;var MASK_OK=8;var LOOPBACK_IP_OK=16;function getUtf8Length(s){return~-encodeURI(s).split(/%..|./).length;}
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
return true;},'network':function(v){return cbi_validators.uciname(v)||cbi_validators.host(v);},'username':function(v){return(v.length>=1)&&(v.length<=32)&&v.match(/^[a-zA-Z0-9\-_.]+$/)&&!v.match(/^\-/);},'wpakey':function(v){if(v.length==64){return(v.match(/^[a-fA-F0-9]{64}$/)!=null);}else{return(v.length>=8)&&(v.length<=63);}},'wepkey':function(v){if(v.substr(0,2)=='s:'){v=v.substr(2);}
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
return true;},};var cbi_validator_messages={'integer':function(v){if(!v){return'Not a valid number!';}
return'';},'uinteger':function(v){if(!v){return'Not a valid positive number!';}
return'';},'float':function(v){if(!v){return'Not a valid number!';}
return'';},'ufloat':function(v){if(!v){return'Not a valid positive number!';}
return'';},'ipaddr':function(v){if(!v){return'Not a valid IP address!';}
return'';},'firewall_ipv4':function(v){if(!v){return'Not a valid IPv4 address!';}
return'';},'firewall_ipaddr':function(v){if(!v){return'Not a valid IP address!';}
return'';},'neg_ipaddr':function(v){if(!v){return'Not a valid IP address!';}
return'';},'ip4addr':function(v){if(!v){return'Not a valid IPv4 address!';}
return'';},'neg_ip4addr':function(v){if(!v){return'Not a valid IPv4 address!';}
return'';},'ip6addr':function(v){if(!v){return'Not a valid IPv6 address!';}
return'';},'port':function(v){if(!v){return'Not a valid port range! Allowed values are integers between '+port_min+' and '+port_max+', inclusive.';}
return'';},'netmask':function(v){if(!v){return'Not a valid netmask!';}
return'';},'portrange':function(v){if(!v){return'Not a valid port range! Allowed values are integers between '+port_min+' and '+port_max+', inclusive.';}
return'';},'macaddr':function(v){if(!v){return'Not a valid MAC address!';}
return'';},'host':function(v){if(!v){return'Not a valid host or IP address!';}
return'';},'network':function(v){if(!v){return'Not a valid network!';}
return'';},'username':function(v){if(!v){return'Must be between 1 and 32 ASCII characters. Only accept A-Z, a-z, 0-9, Period (.), Underscore (_) and Hyphen (-), but NOT allow username that begin with Hyphen (-).';}
return'';},'no_whitespace_str':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);if(!v){return'This value must be between '+min+' and '+max+' characters long, and not include whitespace.';}
return'';},'hotspot_simple_pass':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);if(!v){return'This value must be between '+min+' and '+max+' characters long, and not include colons or whitespace.';}
return'';},'limited_len_str':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);if(!v){return'This value must be between '+min+' and '+max+' characters long.';}
return'';},'hostname_str':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);if(!v){return'This value must be between '+min+' and '+max+' characters long.'+'The only characters allowed in the device hostname are ASCII letters, numbers, and dashes.';}
return'';},'wpakey':function(v){if(!v){return'Not a valid WPA key! Value must be between 8 and 63 ASCII (letters and numbers) characters long or 64 Hex characters.';}
return'';},'wepkey':function(v){if(!v){return'Not a valid WEP key! For 64-bit WEP, length must be 5 ASCII (letters and numbers) characters or 10 hex digits long. For 128-bit, length must be 13 ASCII characters or 26 hex digits.';}
return'';},'uciname':function(v){if(!v){return'Not a valid config name!';}
return'';},'neg_network_ip4addr':function(v){if(!v){return'Not a valid network or IPV4 value!';}
return'';},'range':function(v,args){var min=parseInt(args[0]);var max=parseInt(args[1]);if(!v&&!isNaN(min)&&!isNaN(max)){return'Allowed values are integers between '+min+' and '+max+', inclusive.';}else if(!v){return'Value not allowed!';}
return'';},'min':function(v,args){var min=parseInt(args[0]);if(!v&&!isNaN(min)){return'Value must be greater than or equal to '+min;}else if(!v){return'Value not allowed!';}
return'';},'max':function(v,args){var max=parseInt(args[0]);if(!v&&!isNaN(max)){return'Value must be less than or equal to '+max;}else if(!v){return'Value not allowed!';}
return'';},'neg':function(v,args){if(!v){return'Invalid value!';}
return'';},'list':function(v,args){if(!v){return'Invalid list!';}
return'';},'is_broadcast':function(v){if(!v){return'IP address is a broadcast IP.';}
return'';},'is_network':function(v){if(!v){return'Not a valid network.';}
return'';},'custom_ip':function(v){if(!v){if(!is_ipv4_flag){return'Not a valid IPv4 address!';}
if(!is_netmask_flag){return'Not a valid netmask!';}
if(!is_not_broadcast_flag){return'IP address is a broadcast IP.';}
if(!is_not_network_flag){return'Not a valid network.';}}
return'';},'custom_netmask':function(v){if(!v){if(!is_netmask_flag){return'Not a valid netmask!';}
if(!is_not_broadcast_flag){return'IP address is a broadcast IP.';}
if(!is_not_network_flag){return'Not a valid network.';}}
return'';},'custom_dns':function(v){if(!v){return'Not a valid IP address or DNS servers exceed 4.';}
return'';},'is_ascii':function(v,args){var strleng_msg='';if(args&&args[0]&&args[1]){var min=parseInt(args[0]);var max=parseInt(args[1]);strleng_msg='This value must be between '+min+' and '+max+' characters long.';}
if(!v){return strleng_msg+' Only accept A-Z, a-z, 0-9, space, and ~!@$%^*()_+-=[]{}|:;<>?,./';}
return'';},'isDomain':function(v,args){if(!v){return'Not a valid Domain Name.';}
return'';},'isURL':function(v,args){if(!v){return'The URL format is invalid.';}
return'';},'isBeginningWhiteSpace':function(v){if(!v){return'Not accept white space character at the beginning.';}
return'';},'customHost':function(v){if(!v){return'Not a valid host or IP address!';}
return'';},};function cbi_d_add(field,dep,next){var obj=document.getElementById(field);if(obj){var entry;for(var i=0;i<cbi_d.length;i++){if(cbi_d[i].id==field){entry=cbi_d[i];break;}}
if(!entry){entry={'node':obj,'id':field,'parent':obj.parentNode.id,'next':next,'deps':[]};cbi_d.unshift(entry);}
entry.deps.push(dep);}}
function cbi_d_checkvalue(target,ref){var t=document.getElementById(target);var value;if(!t){var tl=document.getElementsByName(target);if(tl.length>0&&tl[0].type=='radio'){for(var i=0;i<tl.length;i++){if(tl[i].checked){value=tl[i].value;break;}}}
value=value?value:'';}else if(!t.value){value='';}else{value=t.value;if(t.type=='checkbox'){value=t.checked?value:'';}}
return(value==ref);}
function cbi_d_check(deps){var reverse;var def=false;for(var i=0;i<deps.length;i++){var istat=true;reverse=false;for(var j in deps[i]){if(j=='!reverse'){reverse=true;}else if(j=='!default'){def=true;istat=false;}else{istat=(istat&&cbi_d_checkvalue(j,deps[i][j]));}}
if(istat){return!reverse;}}
return def;}
function cbi_d_update(id){var state=false;for(var i=0;i<cbi_d.length;i++){var entry=cbi_d[i];var next=document.getElementById(entry.next);var node=document.getElementById(entry.id);var parent=document.getElementById(entry.parent);if(node&&node.parentNode&&!cbi_d_check(entry.deps)){node.parentNode.removeChild(node);state=true;if(entry.parent){cbi_c[entry.parent]--;}}else if((!node||!node.parentNode||$(node).hasClass('hidden'))&&cbi_d_check(entry.deps)){if($(node).hasClass('hidden')){$(node).removeClass('hidden');}else if(!next){parent.appendChild(entry.node);}else{$(entry.node).hide();next.parentNode.insertBefore(entry.node,next);$(entry.node).slideDown();var nn=$(entry.node).find('[data-rel=tooltip]').tooltip();}
state=true;if(entry.parent){cbi_c[entry.parent]++;}}}
if(entry&&entry.parent){if(!cbi_t_update()){cbi_tag_last(parent);}}
if(state){cbi_d_update();}}
function cbi_bind(obj,type,callback,mode){if(!obj.addEventListener){obj.attachEvent('on'+type,function(){var e=window.event;if(!e.target&&e.srcElement){e.target=e.srcElement;}
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
function cbi_filebrowser(id,url,defpath){var field=document.getElementById(id);var browser=window.open(url+(field.value||defpath||'')+'?field='+id,'luci_filebrowser','width=300,height=400,left=100,top=200,scrollbars=yes');browser.focus();}
function cbi_browser_init(id,respath,url,defpath){function cbi_browser_btnclick(e){cbi_filebrowser(id,url,defpath);return false;}
var field=document.getElementById(id);var btn=document.createElement('img');btn.className='cbi-image-button';btn.src=respath+'/cbi/folder.gif';field.parentNode.insertBefore(btn,field.nextSibling);cbi_bind(btn,'click',cbi_browser_btnclick);}
function cbi_dynlist_init(name,respath){function cbi_dynlist_renumber(e){var inputs=[];for(var i=0;i<e.parentNode.childNodes.length;i++){if(e.parentNode.childNodes[i].name==name){inputs.push(e.parentNode.childNodes[i]);}}
for(var i=0;i<inputs.length;i++){inputs[i].id=name+'.'+(i+1);inputs[i].nextSibling.innerHTML='<i class="'
+((i+1)<inputs.length?'icon-remove':'icon-plus')+'"></i>';}
e.focus();}
function cbi_dynlist_keypress(ev){ev=ev?ev:window.event;var se=ev.target?ev.target:ev.srcElement;if(se.nodeType==3){se=se.parentNode;}
switch(ev.keyCode){case 8:case 46:if(se.value.length==0){if(ev.preventDefault){ev.preventDefault();}
return false;}
return true;case 13:case 38:case 40:if(ev.preventDefault){ev.preventDefault();}
return false;}
return true;}
function cbi_dynlist_keydown(ev){ev=ev?ev:window.event;var se=ev.target?ev.target:ev.srcElement;if(se.nodeType==3){se=se.parentNode;}
var prev=se.previousSibling;while(prev&&prev.name!=name){prev=prev.previousSibling;}
var next=se.nextSibling;while(next&&next.name!=name){next=next.nextSibling;}
switch(ev.keyCode){case 8:case 46:var jump=(ev.keyCode==8)?(prev||next):(next||prev);if(se.value.length==0&&jump){se.parentNode.removeChild(se.nextSibling.nextSibling);se.parentNode.removeChild(se.nextSibling);se.parentNode.removeChild(se);cbi_dynlist_renumber(jump);if(ev.preventDefault){ev.preventDefault();}
jump.focus();return false;}
break;case 13:var n=document.createElement('input');n.name=se.name;n.type=se.type;var b=document.createElement('button');b.type='button';b.className='btn btn-mini btn-dynamic';b.innerHTML='<i class="'+((i+1)<inputs.length?'icon-remove':'icon-plus')
+'"></i>';cbi_bind(n,'keydown',cbi_dynlist_keydown);cbi_bind(n,'keypress',cbi_dynlist_keypress);cbi_bind(b,'click',cbi_dynlist_btnclick);if(next){se.parentNode.insertBefore(n,next);se.parentNode.insertBefore(b,next);se.parentNode.insertBefore(document.createElement('br'),next);}else{se.parentNode.appendChild(n);se.parentNode.appendChild(b);se.parentNode.appendChild(document.createElement('br'));}
var dt=se.getAttribute('cbi_datatype');var op=se.getAttribute('cbi_optional')=='true';if(dt){cbi_validate_field(n,op,dt);}
cbi_dynlist_renumber(n);break;case 38:if(prev){prev.focus();}
break;case 40:if(next){next.focus();}
break;}
return true;}
function cbi_dynlist_btnclick(ev){ev=ev?ev:window.event;var se=ev.currentTarget?ev.currentTarget:ev.srcElement;if(se.childNodes[0].className.indexOf('remove')>-1){se.previousSibling.value='';cbi_dynlist_keydown({target:se.previousSibling,keyCode:8});}else{cbi_dynlist_keydown({target:se.previousSibling,keyCode:13});}
return false;}
var inputs=document.getElementsByName(name);for(var i=0;i<inputs.length;i++){var btn=document.createElement('button');btn.type='button';btn.className='btn btn-mini btn-dynamic';btn.innerHTML='<i class="'+((i+1)<inputs.length?'icon-remove':'icon-plus')
+'"></i>';inputs[i].parentNode.insertBefore(btn,inputs[i].nextSibling);cbi_bind(inputs[i],'keydown',cbi_dynlist_keydown);cbi_bind(inputs[i],'keypress',cbi_dynlist_keypress);cbi_bind(btn,'click',cbi_dynlist_btnclick);}}
function cbi_hijack_forms(layer,win,fail,load){var forms=layer.getElementsByTagName('form');for(var i=0;i<forms.length;i++){$(forms[i]).observe('submit',function(event){event.stop();event.element().request({onSuccess:win,onFailure:fail});if(load){load();}});}}
function cbi_t_add(section,tab){var t=document.getElementById('tab.'+section+'.'+tab);var c=document.getElementById('container.'+section+'.'+tab);if(t&&c){cbi_t[section]=(cbi_t[section]||[]);cbi_t[section][tab]={'tab':t,'container':c,'cid':c.id};}}
function cbi_t_switch(section,tab){if(cbi_t[section]&&cbi_t[section][tab]){var o=cbi_t[section][tab];var h=document.getElementById('tab.'+section);for(var tid in cbi_t[section]){var o2=cbi_t[section][tid];if(o.tab.id!=o2.tab.id){o2.tab.className=o2.tab.className.replace(/(^| )cbi-tab( |$)/,' cbi-tab-disabled ');o2.container.style.display='none';}else{if(h){h.value=tab;}
o2.tab.className=o2.tab.className.replace(/(^| )cbi-tab-disabled( |$)/,' cbi-tab ');o2.container.style.display='block';}}}
return false;}
function cbi_t_update(){var hl_tabs=[];var updated=false;for(var sid in cbi_t){for(var tid in cbi_t[sid]){if(cbi_c[cbi_t[sid][tid].cid]==0){cbi_t[sid][tid].tab.style.display='none';}else if(cbi_t[sid][tid].tab&&cbi_t[sid][tid].tab.style.display=='none'){cbi_t[sid][tid].tab.style.display='';var t=cbi_t[sid][tid].tab;t.className+=' cbi-tab-highlighted';hl_tabs.push(t);}
cbi_tag_last(cbi_t[sid][tid].container);updated=true;}}
if(hl_tabs.length>0){window.setTimeout(function(){for(var i=0;i<hl_tabs.length;i++){hl_tabs[i].className=hl_tabs[i].className.replace(/ cbi-tab-highlighted/g,'');}},750);}
return updated;}
function cbi_validate_form(form,errmsg,error_placeholder){$('#form_error_msg_placeholder').addClass('hide');if(form.cbi_state=='add-section'||form.cbi_state=='del-section'){return true;}
var res=true;if(form.cbi_validators){for(var i=0;i<form.cbi_validators.length;i++){var validator=form.cbi_validators[i];if((!validator()&&errmsg)){cbi_show_form_error(error_placeholder,errmsg);res=false;}}}
return res;}
function cbi_show_form_error(error_placeholder,errmsg){if(error_placeholder==null){error_placeholder='form_error_msg_placeholder';}
if(errmsg==null){errmsg='Some fields are invalid, please see messages below!';}
var shown=false;var div=$('#'+error_placeholder);if(div.length){var err_span=div.find('span');if(err_span.length){shown=true;err_span.html(errmsg);div.removeClass('hide');window.scrollTo(0,0);}}
if(!shown){alert(errmsg);}}
function cbi_validate_reset(form){window.setTimeout(function(){cbi_validate_form(form,null);},100);return true;}
function cbi_validate_field(cbid,f_optional,type){var field=(typeof cbid=='string')?document.getElementById(cbid):cbid;var vargs;if(type.match(/^(\w+)\(([^\(\)]+)\)/)){type=RegExp.$1;vargs=RegExp.$2.split(/\s*,\s*/);}
var vldcb=cbi_validators[type];var msgcb=cbi_validator_messages[type];if(field&&vldcb){var validator=function(){var optional=$.isFunction(f_optional)?f_optional():f_optional;if(field.form){$(field).removeClass('tooltip-error');if($(field).parent().hasClass('controls')){$(field).parents('.control-group').removeClass('error');}else{$(field).parent('.control-group').removeClass('error');}
$(field).attr('data-original-title','');var value=(field.options&&field.options.selectedIndex>-1)?field.options[field.options.selectedIndex].value:field.value;if($(field).attr('deleted')!='deleted'){if(!(((value.length==0)&&optional)||vldcb(value,vargs))){if(value.length==0&&!optional){$(field).attr('data-original-title','This field is required.');}else{$(field).attr('data-original-title',msgcb(false,vargs));}
if($(field).parent().hasClass('controls')){$(field).parents('.control-group').addClass('error');}else{$(field).parent('.control-group').addClass('error');}
$(field).addClass('tooltip-error');$(field).attr('data-trigger','focus');$(field).tooltip();return false;}}}
return true;};if(!field.form.cbi_validators){field.form.cbi_validators=[];}
field.form.cbi_validators.push(validator);cbi_bind(field,'blur',validator);cbi_bind(field,'keyup',validator);if(field.nodeName=='SELECT'){cbi_bind(field,'change',validator);cbi_bind(field,'click',validator);}
var optional=$.isFunction(f_optional)?f_optional():f_optional;field.setAttribute('cbi_validate',validator);field.setAttribute('cbi_datatype',type);field.setAttribute('cbi_optional',(!!optional).toString());validator();var fcbox=document.getElementById('cbi.combobox.'+field.id);if(fcbox){cbi_validate_field(fcbox,f_optional,type);}}}
function cbi_row_swap(elem,up,store){var tr=elem.parentNode;while(tr&&tr.nodeName.toLowerCase()!='tr'){tr=tr.parentNode;}
if(!tr){return false;}
var table=tr.parentNode;while(table&&table.nodeName.toLowerCase()!='table'){table=table.parentNode;}
if(!table){return false;}
var s=up?3:2;var e=up?table.rows.length:table.rows.length-1;for(var idx=s;idx<e;idx++){if(table.rows[idx]==tr){if(up){tr.parentNode.insertBefore(table.rows[idx],table.rows[idx-1]);}else{tr.parentNode.insertBefore(table.rows[idx+1],table.rows[idx]);}
break;}}
var ids=[];for(idx=2;idx<table.rows.length;idx++){table.rows[idx].className=table.rows[idx].className.replace(/cbi-rowstyle-[12]/,'cbi-rowstyle-'+(1+(idx%2)));if(table.rows[idx].id&&table.rows[idx].id.match(/-([^\-]+)$/)){ids.push(RegExp.$1);}}
var input=document.getElementById(store);if(input){input.value=ids.join(' ');}
return false;}
function cbi_tag_last(container){var last;for(var i=0;i<container.childNodes.length;i++){var c=container.childNodes[i];if(c.nodeType==1&&c.nodeName.toLowerCase()=='div'){c.className=c.className.replace(/ cbi-value-last$/,'');last=c;}}
if(last){last.className+=' cbi-value-last';}}
if(!String.serialize){String.serialize=function(o){switch(typeof(o)){case'object':if(o==null){return'null';}else if(o.length){var i,s='';for(var i=0;i<o.length;i++){s+=(s?', ':'')+String.serialize(o[i]);}
return'[ '+s+' ]';}else{var k,s='';for(k in o){s+=(s?', ':'')+k+': '+String.serialize(o[k]);}
return'{ '+s+' }';}
break;case'string':if(o.match(/[^a-zA-Z0-9_,.: -]/)){return'decodeURIComponent("'+encodeURIComponent(o)+'")';}else{return'"'+o+'"';}
break;default:return o.toString();}};}
if(!String.format){String.format=function(){if(!arguments||arguments.length<1||!RegExp){return;}
var html_esc=[/&/g,'&#38;',/"/g,'&#34;',/'/g,'&#39;',/</g,'&#60;',/>/g,'&#62;'];var quot_esc=[/"/g,'&#34;',/'/g,'&#39;'];function esc(s,r){for(var i=0;i<r.length;i+=2){s=s.replace(r[i],r[i+1]);}
return s;}
var str=arguments[0];var out='';var re=/^(([^%]*)%('.|0|\x20)?(-)?(\d+)?(\.\d+)?(%|b|c|d|u|f|o|s|x|X|q|h|j|t|m))/;var a=b=[],numSubstitutions=0,numMatches=0;while(a=re.exec(str)){var m=a[1];var leftpart=a[2],pPad=a[3],pJustify=a[4],pMinLength=a[5];var pPrecision=a[6],pType=a[7];numMatches++;if(pType=='%'){subst='%';}else{if(numSubstitutions++<arguments.length){var param=arguments[numSubstitutions];var pad='';if(pPad&&pPad.substr(0,1)=='\''){pad=leftpart.substr(1,1);}else if(pPad){pad=pPad;}
var justifyRight=true;if(pJustify&&pJustify==='-'){justifyRight=false;}
var minLength=-1;if(pMinLength){minLength=parseInt(pMinLength);}
var precision=-1;if(pPrecision&&pType=='f'){precision=parseInt(pPrecision.substring(1));}
var subst=param;switch(pType){case'b':subst=(parseInt(param)||0).toString(2);break;case'c':subst=String.fromCharCode(parseInt(param)||0);break;case'd':subst=(parseInt(param)||0);break;case'u':subst=Math.abs(parseInt(param)||0);break;case'f':subst=(precision>-1)?((parseFloat(param)||0.0)).toFixed(precision):(parseFloat(param)||0.0);break;case'o':subst=(parseInt(param)||0).toString(8);break;case's':subst=param;break;case'x':subst=(''+(parseInt(param)||0).toString(16)).toLowerCase();break;case'X':subst=(''+(parseInt(param)||0).toString(16)).toUpperCase();break;case'h':subst=esc(param,html_esc);break;case'q':subst=esc(param,quot_esc);break;case'j':subst=String.serialize(param);break;case't':var td=0;var th=0;var tm=0;var ts=(param||0);if(ts>60){tm=Math.floor(ts/60);ts=(ts%60);}
if(tm>60){th=Math.floor(tm/60);tm=(tm%60);}
if(th>24){td=Math.floor(th/24);th=(th%24);}
subst=(td>0)?String.format('%dd %dh %dm %ds',td,th,tm,ts):String.format('%dh %dm %ds',th,tm,ts);break;case'm':var mf=pMinLength?parseInt(pMinLength):1000;var pr=pPrecision?Math.floor(10*parseFloat('0'+pPrecision)):2;var i=0;var val=parseFloat(param||0);var units=['','K','M','G','T','P','E'];for(i=0;(i<units.length)&&(val>mf);i++){val/=mf;}
subst=val.toFixed(pr)+' '+units[i];break;}}}
out+=leftpart+subst;str=str.substr(m.length);}
return out+str;};}