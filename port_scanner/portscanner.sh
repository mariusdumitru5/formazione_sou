#!/usr/bin/env bash

# colori per l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m' 

# funzione che stampa messaggio di utilizzo dello script 
show_usage(){
	printf "${YELLOW}Usage: $0 -i IP_ADDRESS -p PORT_RANGE\n"
	printf "Options:\n"
    printf "  -i, --ip          Specify the IP address\n"
    printf "  -p          	    Specify a port on the host\n"
    printf "  --port-range      Specify the port range (e.g., 20-80)${RESET}\n"
}

# verifico che non vengano passati troppi argomenti
if [[ "$#" -gt 4 ]]; then
	echo "Too many arguments."
	show_usage
	exit 1
fi

# gestione paramentri con getopt
PARS=$(getopt -o i:p: --long ip:,port-range: -n "$0" -- "$@")

# controllo se getop è andato a buon fine
if [[ "$?" -ne 0 ]]; then
	echo "--------------------------------------------"
	show_usage
	exit 1
fi

# se è andato tutto bene imposto i parametri posizionali 
eval set -- "$PARS"

# variabili globali utilizzate 
IP=""
RANGE=""
PORT=""
IP_VALIDATOR="^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$"

# ora ciclo tra i parametri 
while true; do
	case "$1" in
		-i|--ip)
			IP=$2
			shift 2;;
		--port-range)
			RANGE=$2
			shift 2;;
		-p)
			PORT=$2
			shift 2;;
		--)
			shift
			break;;
		*)
			show_usage;;	
	esac

done

# verifico che siano stati passati gli argomenti
if [[ -z "$IP" ||( -z "$RANGE" && -z "$PORT") ]]; then
	show_usage
	exit 1
fi

# verifico che l'ip sia valido 
if ! [[ "$IP" =~ $IP_VALIDATOR ]]; then
	printf "${RED}Error: Invalid IP${RESET}\n"
	exit 1
fi

# se è definita la variabile PORT
if [[ -n "$PORT" ]]; then
	# controllo che la porta sia un intero positivo
	if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
		printf "${RED}Error: Port must be a positive number.${RESET}\n"
		exit 1
	fi
	# start = end; in questo modo eseguo una sola volta il ciclo for
	START_PORT=$PORT
	END_PORT=$PORT
else
	# verifico se il range è nel formato giusto
	if [[ ! "$RANGE" =~ ^[0-9]+-[0-9]+$ ]]; then
		printf "${RED}Error: Invalid port range format. Use 'START-END' (e.g., 20-80).${RESET}\n"
		exit 1
	fi
	
	# separo inizio e fine range 
	IFS=- read -r START_PORT END_PORT <<< "$RANGE"
fi

# controllo che START_PORT e END_PORT siano interi positivi
if ! [[ "$START_PORT" =~ ^[0-9]+$ && "$END_PORT" =~ ^[0-9]+$ ]]; then
	printf "${RED}Error: Invalid port range${RESET}\n"
	printf "${RED}Ports must be positive numbers${RESET}\n"
	exit 1
fi

# controllo sul numero di porta 
if (( START_PORT < 1 || START_PORT > 65535 || END_PORT < 1 || END_PORT > 65535 )); then
    printf "${RED}Error: Ports must be between 1 and 65535.${RESET}\n"
    exit 1
fi

if ((START_PORT > END_PORT)); then
	printf "${RED}Error: Invalid port range.${RESET}\n"
	printf "${RED}$START_PORT is bigger than $END_PORT${RESET}\n"
	exit 1
fi

printf "%-12s | %-12s\n" "PORTA" "STATO"
echo "----------------------------------------"

# controllo porte sull'host con netcat
for ((i = START_PORT; i <= END_PORT; i++ )); do
	nc -n -w 1 "$IP" "$i" &> /dev/null

	if [[ "$?" -eq  0 ]]; then
		STATUS="${GREEN}OPEN${RESET}"
	else
		STATUS="${RED}CLOSE${RESET}"
	fi
	printf "%-12s | %-12b\n" "$i" "$STATUS"

done
echo "----------------------------------------"