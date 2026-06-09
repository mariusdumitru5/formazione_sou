#!/usr/bin/env bash
# am-i-root.sh: Am I root or not?

# imposto la variabile ROOT_UID a 0, è l'UID dell'utenete root
ROOT_UID=0

# se l'UID attuale dell'utente con il 
# quale sono loggato è uguale a ROOT_UID, cioè a 0
if [ "$UID" -eq "$ROOT_UID" ]; then
	echo "You are root!!"  # stampa sei root
# altrimenti non sei root
else  
	echo "You are just an ordinary user(but mom loves you just the same)!!"
fi

# esco con codice di uscita 0, quindi successo!
exit 0
