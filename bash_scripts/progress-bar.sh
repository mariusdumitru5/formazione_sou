#!/usr/bin/env bash
# progress-bar2.sh
# Author: Graham Ewart (with reformatting by ABS Guide author).
# Used in ABS Guide with permission (thanks!).

# Invoke this script with bash. It doesn't work with sh.

interval=1
long_interval=10

# con l'utilizzo delle {} si crea un blocco di comandi
# il & alla fine crea una subshell che esegue i comandi in bg

{
     # se arriva il segnale SIGUSR1 fai exit e chiudi il sottoprocesso
     trap "exit" SIGUSR1
     sleep $interval; sleep $interval
     # continua a stampare puntini ogni secondo 
     while true
     do
       echo -n '.'     # Use dots.
       sleep $interval
     done; } &         # Start a progress bar as a background process.

# salvo il PID del sottoprocesso
pid=$!
# uso questo per gestire il ^C: se lo premo
# viene inviato il SIGUSR1 al sotto processo e quello si chiude
trap "echo !; kill -USR1 $pid; wait $pid"  EXIT        # To handle ^C.
# qaundo finisce il "long-running process" mando 
# il SIGUSR1 e chiudo anche il sottoprocesso
echo -n 'Long-running process '
sleep $long_interval
echo ' Finished!'

kill -USR1 $pid
wait $pid              # Stop the progress bar.
trap EXIT	       # reset del segnale EXIT
# controllo lo stato d'uscita dello script
exit $?
