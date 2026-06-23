#!/usr/bin/env bash

### colors for the output
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m' 

### IP classes regex
# class A (0.0.0.0 - 127.255.255.2555)
A="^([0-9]|[1-9][0-9]|1[0-2][0-7])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$"
# class B (128.0.0.0 - 191.255.255.2555)
B="^(1[2-8][0-9]|19[0-1])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$"
# class C (192.0.0.0 - 223.255.255.2555)
C="^(19[2-9]|2[0-1][0-9]|22[0-3])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$"
# class D (224.0.0.0 - 239.255.255.2555)
D="^(22[4-9]|23[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$"
# class E (240.0.0.0 - 255.255.255.2555)
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
            echo "Usage: $0 [-i|--ip IP_ADDRESS] [-m|--mask SUBNET_MASK]"
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
    echo "Usage: $0 -i <IP_ADDRESS> [-m <SUBNET_MASK>]"
    exit 1
fi

# gey ip type
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