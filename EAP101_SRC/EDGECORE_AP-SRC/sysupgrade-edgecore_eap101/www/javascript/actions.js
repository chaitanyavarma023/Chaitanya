
var checking_time=0;var contact_timeout=60000;var poll_int=2000;function try_contact_device(initial_delay,poll_interval,timeout,wan_ip){poll_int=poll_interval;contact_timeout=timeout;setTimeout(function(){is_device_up(wan_ip);},initial_delay);}
function is_device_up(wan_ip){if(wan_ip==undefined){wan_ip='';}
console.log('Trying to contact device...');var current_protocal=location.protocol;var current_hostname=(wan_ip!=''?wan_ip:location.hostname);var current_port=location.port;var current_pathname=location.pathname;if(current_port!=''){current_port=':'+current_port;}
var tmp_location_href=current_protocal+'//'+current_hostname+current_port+current_pathname;if(wan_ip!=''&&wan_ip!=location.hostname){contact_timeout=15000;}
if(checking_time>contact_timeout){window.location=tmp_location_href;return;}
var url=base_url+'/admin/uci/api/check';$.ajax({timeout:5000,url:url}).success(function(){console.log('up!');$('.icon-spinner').removeClass('icon-spin');$('.icon-spinner').fadeOut(1000).addClass('hidden');window.location=tmp_location_href;}).fail(function(){console.log('not up yet');checking_time+=poll_int;setTimeout(function(){is_device_up(current_hostname);},poll_int);});}