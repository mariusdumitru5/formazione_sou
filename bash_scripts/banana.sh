#!/usr/bin/env bash

# controllo se il numero di argomenti è esatamente 1
if (("$#" != 1)); then
	echo "Numero di argomenti sbagliati"
	echo "Utilizzo: $0 <file.csv>"
	exit 1
fi

# controllo che il file esista
if ! [[ -f "$1" ]]; then
	echo "Il file $1 non esiste!"
	exit 1
fi


# imposta il Field Separator su "," e poi stampa solo la terza colonna
# delle righe che contengono la stringa banana
awk 'BEGIN { FS="," } /banana/ { print $3 }' "$1"
