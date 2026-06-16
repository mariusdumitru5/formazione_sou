#!/usr/bin/env bash

# funzione che calcola se il numero è pari o dispari 
odd_even(){
	local n=$1
	if ((n % 2 == 0)); then
		echo "$n è pari"
	else
		echo "$n è dispari"
	fi
}

# controllo il numero degli argomenti
if (("$#" != 1)); then
	echo "Utilizzo sbagliato dello script"
	echo "Utilizzo: $0 <numero>"
	exit 1
fi

# controllo che sia un numero(anche negativo)
if ! [[ "$1" =~ ^-?[0-9]+$ ]]; then
	echo "L'input non è un numero! Inserisci un numero!!!"
	exit 1	
fi

# se il numero è positivo stampo i numeri da 0 a $1 
if [[ "$1" =~ ^[0-9]+$ ]]; then
	for((i = 0; i <= "$1"; i++));do
		odd_even "$i"
	done
else
	# se il numero è negativo stampo i numeri da 0 a -$1
	for ((i = 0; i >= $1; i--));do
		odd_even "$i"
	done
fi
