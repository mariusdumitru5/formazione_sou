# IP Checker

Questo script serve a verificare su un indirizzo IP è valido o meno. Se l'IP è valido, lo script mostra una serie di informazioni utili come la `classe di appartenenza`, il `tipo di IP`(privato, publico o speciale). Se viene passata anche la maschera, è possibile visualizzare informazioni extra come indirizzo di rete(`NetID`), indirizzo di `broadcast` e `range di host possibili`.

## Espressioni Regolari 

Per la validazione dell'indirizzo IP sono state utilizzate una serie di `espressioni regolari` che corrispondono alla varie classi di indirizzi IP. 
Per esempio, per verificare su un IP appartiene alla classe A si utilizza:

```bash
^([0-9]|[1-9][0-9]|1[0-2][0-7])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$
```

Questa espressione controlla che il primo gruppo dell'IP sia compresso tra 0 e 127. Per i restanti tre gruppi viene controllato se sono compressi tra 0 e 255. 
Si procede nello stesso modo anche per le altre classi. 
Per quanto riguarda gli indirizzi privati si procede allo stesso modo:

```bash
^10(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$
```

In questo caso controllo se l'indirizzo IP sia un indirizzo privato della classe A. 

## Funzionamento Script

Lo script prende gli argomenti dalla linea di comando attraverso `getopt`, un comando di bash molto utile per la gestione dei parametri da linea di comando in modo intelligente. 

```bash
PARS=$(getopt -o i:m:h --long ip:,mask:,help -n "$0" -- "$@")
```

In questo modo sto eseguendo il comando `getopt` con i parametri:

- `-o` che indica i parametri brevi(come `-i` che serve per passare l'IP, `-m` per la maschera e `-h` per help). I parametri `-i e -m` richiedono obbligatoriamente un argomento dopo.
- `--long` che serve per i parametri che hanno un nome più lungo di un carattere(`--ip`, `--mask` e `--help`).

Si utilizza `eval set -- "$PARS"` per ordinare i parametri e assegnarli a `$1, $2, ...$n`.


