#!/bin/sh

# Prompt user for input
printf "\e[1;91m%-15s\e[m" "Enter User Name : "
read USERNAME

printf "\e[1;91m%-15s\e[m" "Enter User-Password : "
read -s PASSWORD  # -s hides the input to protect the password

printf "\e[1;91m%-15s\e[m" "Enter RADIUS Server IP : "
read SERVER

printf "\e[1;91m%-15s\e[m" "Enter RADIUS Port : "
read PORT

printf "\e[1;91m%-15s\e[m" "Enter RADIUS Secret : "
read SECRET

# Build the radclient command
echo "User-Name=$USERNAME,User-Password=$PASSWORD" | radclient -x $SERVER:$PORT auth $SECRET




################################################################################################################
################################################################################################################
###########################################################################################################################

#script with error message



#!/bin/sh

# Prompt user for input
printf "\e[1;91m%-15s\e[m" "Enter User Name : "
read USERNAME
if [ -z "$USERNAME" ]; then
    echo -e "\n\e[1;91mError: User Name is required.\e[m"
    exit 1
fi

printf "\e[1;91m%-15s\e[m" "Enter User-Password : "
read -s PASSWORD  # -s hides the input to protect the password
echo # To ensure the cursor moves to the next line
if [ -z "$PASSWORD" ]; then
    echo -e "\n\e[1;91mError: User-Password is required.\e[m"
    exit 1
fi

printf "\e[1;91m%-15s\e[m" "Enter RADIUS Server IP : "
read SERVER
if [ -z "$SERVER" ]; then
    echo -e "\n\e[1;91mError: RADIUS Server IP is required.\e[m"
    exit 1
fi

printf "\e[1;91m%-15s\e[m" "Enter RADIUS Port : "
read PORT
if [ -z "$PORT" ]; then
    echo -e "\n\e[1;91mError: RADIUS Port is required.\e[m"
    exit 1
fi

printf "\e[1;91m%-15s\e[m" "Enter RADIUS Secret : "
read SECRET
if [ -z "$SECRET" ]; then
    echo -e "\n\e[1;91mError: RADIUS Secret is required.\e[m"
    exit 1
fi

# Build and execute the radclient command
echo "User-Name=$USERNAME,User-Password=$PASSWORD" | radclient -x "$SERVER:$PORT" auth "$SECRET"

