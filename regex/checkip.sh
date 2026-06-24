#!/usr/bin/env bash

### colors for the output
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m' 

### IP classes regex
# class A (0.0.0.0 - 127.255.255.255)
A="^([0-9]|[1-9][0-9]|1[0-2][0-7])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$"
# class B (128.0.0.0 - 191.255.255.255)
B="^(12[8-9]|1[3-8][0-9]|19[0-1])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$"
# class C (192.0.0.0 - 223.255.255.255)
C="^(19[2-9]|2[0-1][0-9]|22[0-3])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$"
# class D (224.0.0.0 - 239.255.255.255)
D="^(22[4-9]|23[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$"
# class E (240.0.0.0 - 255.255.255.255)
E="^(24[0-9]|25[0-5])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$"

### Private IP classes
# class A (10.0.0.0 - 10.255.255.255)
AP="^10(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$"
# class B (172.16.0.0 - 172.31.255.255)
BP="^172\.(1[6-9]|2[0-9]|3[0-1])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){2}$"
# class C (192.168.0.0 - 192.168.255.255)
CP="^192\.168(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){2}$"

### Special IP
# default route (0.0.0.0)
ZERO="^0\.0\.0\.0$"
# loopback IPs (127.0.0.0 - 127.255.255.255)
LOOPBACK="^127(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$"
# limited broadcast (255.255.255.255)
BROADCAST="^255\.255\.255\.255$"

# net mask 
MASK=""
# ip
IP=""
# ip type
TYPE="Public"
# ip class
CLASS=""
# netID
NET_ID=""
# broadcast address
BADDR=""
# first host
FIRST_HOST=""
# last host
LAST_HOST=""

to_dotted(){
    local cidr="$1"
    
    if [[ ! "$cidr" =~ ^[0-9]+$ ]] || [ "$cidr" -lt 0 ] || [ "$cidr" -gt 32 ]; then
        echo "Error: Invalid CIDR subnet mask. Must be a number between 0 and 32."
        exit 1
    fi

    local mask=$(( (0xffffffff << (32 - cidr)) & 0xffffffff ))
    MASK_DECIMAL="$((mask>>24 & 255)).$((mask>>16 & 255)).$((mask>>8 & 255)).$((mask & 255))"
}



# get network info about hosts, netID and broadcast address
get_netInfo(){
	
	# divide the ip and the mask
	to_dotted "$MASK"

	IFS=. read -r i1 i2 i3 i4 <<< "$IP"
    IFS=. read -r m1 m2 m3 m4 <<< "$MASK_DECIMAL"
	
	# logic and between each octet
    net1=$((i1 & m1))
    net2=$((i2 & m2))
    net3=$((i3 & m3))
    net4=$((i4 & m4))
    NET_ID="$net1.$net2.$net3.$net4"

	b1=$(( i1 | (255 - m1) ))
   	b2=$(( i2 | (255 - m2) ))
    b3=$(( i3 | (255 - m3) ))
    b4=$(( i4 | (255 - m4) ))
    BADDR="$b1.$b2.$b3.$b4"

    FIRST_HOST="$net1.$net2.$net3.$((net4 + 1))"
    LAST_HOST="$b1.$b2.$b3.$((b4 - 1))"		

    if ((MASK == 31)); then
        FIRST_HOST="IP"
        LAST_HOST="$IP"
    elif ((MASK == 32))
        FIRST_HOST="0"
        LAST_HOST="0"		
    fi	
}

# 

# get comand line args
PARS=$(getopt -o i:m:h --long ip:,mask:,help -n "$0" -- "$@")

# check if 
if (("$?" != 0)); then
    echo "Error: Wrong input options."
    echo "For help use: $0 --help or -h"
    exit 1
fi

# reorder agrs
eval set -- "$PARS"
while true; do
    case "$1" in
        -i|--ip)
            IP="$2"
            shift 2
            ;;
        -m|--mask)
            MASK="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-i|--ip IP_ADDRESS] [-m|--mask CIDR_SUBNET_MASK(0 - 32)]"
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Error: Unrecognized option!"
            exit 1
            ;;
    esac
done

# check if the ip is empty
if [[ -z "$IP" ]]; then
    echo "Error: The --ip (or -i) option is mandatory."
    echo "Usage: $0 -i <IP_ADDRESS> [-m CIDR_SUBNET_MASK(0 - 32)]"
    exit 1
fi

# get ip type
if [[ "$IP" =~ $AP || "$IP" =~ $BP || "$IP" =~ $CP ]]; then
    TYPE="Private"
elif [[ "$IP" =~ $LOOPBACK ]]; then
    TYPE="Loopback"
elif [[ "$IP" =~ $ZERO ]]; then
    TYPE="Special"
elif [[  "$IP" =~ $BROADCAST ]]; then 
    TYPE="LAN Broadcast"
fi

# get ip class
if [[ "$IP" =~ $A ]]; then
    CLASS="Class A"
elif [[ "$IP" =~ $B ]]; then
    CLASS="Class B"
elif [[ "$IP" =~ $C ]]; then
    CLASS="Class C"
elif [[ "$IP" =~ $D ]]; then
    CLASS="Class D"
elif [[ "$IP" =~ $E ]]; then
    CLASS="Class E"
fi

# print the output
printf "====================IP Checker====================\n"
if [[ -n "$CLASS" ]]; then
    printf "${GREEN}[+] IP         : %s${RESET}\n" "$IP"
    
   #check if the mask is defined
    if [[ -n "$MASK" ]]; then
	get_netInfo
        printf "${GREEN}[+] Netmask    : %s${RESET}\n" "$MASK"
        printf "${GREEN}[+] NetID      : %s${RESET}\n" "$NET_ID"
        printf "${GREEN}[+] Broadcast  : %s${RESET}\n" "$BADDR"
        printf "${GREEN}[+] Host range : from %s to %s${RESET}\n" "$FIRST_HOST" "$LAST_HOST"
	
    fi
   
    printf "${GREEN}[+] IP Class   : %s${RESET}\n" "$CLASS"
    printf "${GREEN}[+] IP Type    : %s${RESET}\n" "$TYPE" 
    printf "==================================================\n"
    exit 0
else
    printf "${RED}[+] Invalid IP  : %s${RESET}\n" "$IP"
    printf "${RED}[+] IP Class    : Unknown${RESET}\n"
    printf "${RED}[+] IP Type     : Unknown${RESET}\n" 
    printf "==================================================\n"
    exit 1
fi
