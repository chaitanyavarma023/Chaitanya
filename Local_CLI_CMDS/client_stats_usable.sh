#!/bin/sh
#|===============================================================================
#|      FILE            :  client info
#|      USAGE           :  Display info regarding instant and periodic client    
#|      ARGUMENTS       :  No arguments required
#|      RETURN VALUE    :  Prints the periodic and instant client status     
#|===============================================================================
                                                                        
# Read the flag value from /etc/STATS                                            
flag=$(cat /etc/STATS)
                                     
# Check if the 'ndpiReader' process is running using ps and grep
if ps | grep ndpiReader >/dev/null 2>&1; then
    app_stat="Enabled"                                          
else                                         
    app_stat="Disabled"
fi  
                       
# Print the output in tabular format
echo -e "|---------------------------------------------------------------"
echo -e "| Status | Instant | Periodic | Application statistics          "
echo -e "|---------------------------------------------------------------"
                                                                          
case $flag in                                                             
    0)
        echo -e "|   ON   |   ON    |   ON     |       $app_stat         "
        ;;
    1)                                                                    
        echo -e "| ON     |   ON    |   Off    |       $app_stat         "
        ;;
    2)                                                                    
        echo -e "| Off    |   Off   |   Off    |       $app_stat         "
        ;;
    *)                                                                    
        echo -e "| Invalid flag value! Please use 0, 1, or 2. "
        ;;
esac                                                           
          
echo -e "|---------------------------------------------------------------"

