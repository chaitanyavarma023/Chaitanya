#!/usr/bin/awk -f
BEGIN{
    FS="[,]"
    db_path=ARGV[1]
    if (""==db_path) {
      print "awk -f rad_nas.awk db_path"
      exit
    }
    cmdstr= "cat " db_path "/nas_list_tmp"
    "if [ -f /conf/etc/profile ]; then . /conf/etc/profile; echo $PKG_SZ_WLAN; fi" | getline PKG_SZ_WLAN
    if (PKG_SZ_WLAN == "1")
	cmdstr = "echo 2,127.18.12.0,24,12345678; " cmdstr
    while ( (cmdstr | getline) > 0) {
	if($1 != "" && $1 != "0" && $2 != "" && $3 != "" && $4 != "") {
	    printf("client %s/%s { \n\tsecret\t\t= %s\n\tshortname\t= %s/%s\n}\n",$2,$3,$4,$2,$3)
	}
    }
}
