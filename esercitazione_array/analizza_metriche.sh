#!/usr/bin/env bash
# Marius Dumitru

# controllo sugli argomenti da linea di comando 
if (("$#" != 1)); then
	echo "Numero argomenti sbagliato"
	echo "Usage: $0 <file_metriche.txt>"
	exit 1
fi	

# controllo esistenza file in ingresso
if ! [[ -f "$1" ]]; then
	echo "File inesistente!!!"
	exit 1
fi

# dichiarazione array associativi 
declare -A sum_cpu
declare -A ser_occ

# lettura file riga per riga
while read -r server utilizzo; do

	# se la chiave non c'è nell'array la inserisco e la metto uguale a 1
	if ! [[ -v ser_occ["$server"] ]]; then
		(( ser_occ["$server"] = 1 ))
	else 
		# se la chiave c'è già, basta fare +1
		(( ser_occ["$server"] += 1 ))
	fi
	# stesso ragionamento di sopra solo che faccio la somma sull'utilizzo della cpu
	if ! [[ -v sum_cpu["$server"] ]]; then
		(( sum_cpu["$server"] = utilizzo ))
	else
		(( sum_cpu["$server"] += utilizzo ))
	fi
done < "$1"

echo "=== REPORT UTILIZZO MEDIO CPU ==="
# faccio un ciclo sulle chiavi 
for i in "${!sum_cpu[@]}";do
	# calcolo la media 
	media=$((sum_cpu["$i"] / ser_occ["$i"]))
	
	# stampa risultato finale 
	echo "$i: $media%"

done
