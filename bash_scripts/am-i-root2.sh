#!/usr/bin/env bash
# am-i-root.sh: Am I root or not?

# imposto la variabile ROOTUSER_NAME a root
ROOTUSER_NAME=root

# eseguo il comando id -nu e salvo il risultato in username
# id -nu restituisce il nome dell'utente  
username=`id -nu`

# se username è uguale a root
if [ "$username" = "$ROOTUSER_NAME" ] ; then
	# stampa sei root
	echo "Rooty, toot, toot. You are root!!"
# altrimenti 
else	
	# stampa non sei root
	echo "You are just a regular fella!!"
fi
