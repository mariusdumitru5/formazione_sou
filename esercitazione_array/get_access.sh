#!/usr/bin/env bash

if (("$#" != 1)); then
	echo "Numero argomenti sbagliato"
	echo "Usage: $0 <file_accessi.txt>"
	exit 1
fi	

if ! [[ -f "$1" ]]; then
	echo "File inesistente!!!"
	exit 1
fi

# array associativo per salvare ip come chiave
# e numero di volte che lo trovo come valore 
declare -A ips

# itero sul file leggendo riga per riga
# -r serve a interpretare i caratteri di escape in modo letterale 
# IFS=  imposta il separatore sullo spazio vuoto, 
# quindi gli spazi vuoti vengono ignorati 
while IFS= read -r ip; do
	# se l'ip non è nella lista lo aggiunge come chiave
	# e poi imposta il valore a uno
	# -v guarda se la variabile o la chiave è definita 
	if ! [[ -v ips["$ip"] ]]; then
		((ips["$ip"] = 1))
	else 
		# se l'ip è nella lista e lo incontra fa +1
		((ips["$ip"] += 1))
	fi
done < "$1"  # serve per dire da quale file leggere 

# ciclo per ordinare e stampare i risultati
# l'ordine di stampa ha questa precedenza:
	# prima l'ip che si ripete più volte
	# se ci sono più ip che hanno lo stesso numero di ripetizioni
	# gli ip vengono mostrati in ordine decresente
while IFS='*' read -r valore ip; do
    echo "$valore $ip"  
done < <(
    for ip in "${!ips[@]}"; do
        echo "${ips[$ip]}*$ip"
    done | sort -nr | head -n 3
)
