<h1 align="center">PortScanner</h1>

Questo script serve a visualizzare lo stato delle porte `TCP` su una macchina remota. In particolare fa lo scanning di un range di porte e per ogni porta dice se questa è `OPEN` o `CLOSE`. 

## Utilizzo Script 

Per utilizzare lo script è necessario fornire due parametri obbligatori. 

```bash
./portscanner [-i|--ip IP_ADDRESS] [-p|--port-range PORT|START-END]
```

- `i o --ip` serve per passare l'indirizzo IP della macchina sulla quale si vuole fare port scanning.
- `-p PORT` serve per verificare lo stato di una porta nello specifico. 
- `--port-range START-END` serve per passare un range di porte. 

Esempi:

```bash
./portscanner -i 192.168.1.100 -p 22
```

```bash
./portscanner --ip 192.168.1.100 --port-range 18-23
```

## Gestione Parametri

I parametri vengono gestiti con `getopt`, un comando di Bash che facilita il passaggio dei parametri da linea di comando.

```bash
PARS=$(getopt -o i:p: --long ip:,port-range: -n "$0" -- "$@")
```

In questo modo sto eseguendo il comando getopt con i parametri:

- `-o` che indica i parametri brevi(come `-i` che serve per passare l'IP, `-p` per passare la porta). I parametri -i e -p richiedono obbligatoriamente un argomento dopo.
- `--long` che indica i parametri che hanno un nome più lungo di un carattere(`--ip`, `--port-range`).
  
Una volta presi i parametri, questi vengono salvati dentro la variabile `PARS`. Per assegnare questi parametri ai parametri posizionali di Bash si utilizza:

```bash
eval set -- "$PARS"
```

Esempio:

```bash
./portscanner --ip 192.168.1.100 -p 22
```

Dentro la variabile `PARS` avrò la lista degli argomenti in questo modo:

```text
PARS= --ip 192.168.1.100 -p 22--
```

I due dash `--` alla fine indicano la fine degli argomenti per getopt. Quello che viene dopo sarà interpretato come testo che viene passato in input al comando.

Grazie a `eval set -- "$PARS"` avrò:

```text
$1=--ip
$2=192.168.1.100
$3=-p
$4=22
$5=--
```

Per utilizzare questi argomenti si utilizza un ciclo `while` insieme ad un `case`:

```bash
while true; do
    case "$1" in
        -i|--ip)
            IP="$2"
            shift 2
            ;;
        # ... altri casi (es. -p, --port-range) ...
        *)
            show_usage
            ;;
    esac
done
```

Da notare l'utilizzo di `shift 2` che scarta l'opzione e il valore associato dopo avero usato. In questo caso l'opzione dopo e il suo valore saranno sempre in prima e seconda posizione(`$1` e `$2`).

## Validazione Parametri 

Affinché lo script funzioni i parametri in ingresso devono essere validi. 

#### Input non vuoto

```bash
if [[ -z "$IP" ||( -z "$RANGE" && -z "$PORT") ]]; then
   show_usage
   exit 1
fi
```

In questo caso, se le variabili `IP` o `RANGE` e `PORT` sono vuote, allora lo script si ferma perché non ci sono dati da elaborare. 

#### IP Valido

```bash
if ! [[ "$IP" =~ $IP_VALIDATOR ]]; then
    printf "${RED}Error: Invalid IP${RESET}\n"
    exit 1
fi
```

Verifico attraverso un `espressione regex`che l'IP sia valido. L'espressione è la seguente:

```bash
IP_VALIDATOR="^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$"
```

#### Controllo PORT o PORT-RANGE

```bash
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
```

In questo modo controllo se è stato passato il parametro `PORT` tramite `-p` o il parametro `RANGE` tramite `--port-range`. 
Se è stato passato `-p` allora controllo che la porta passata sia un intero positivo.
Se è stato passato `--port-range` controllo che il valore passato abbia il formato `START-END` e che entrambi i numeri siano interi positivi. Infine, in questo secondo caso, suddivido il range in `START_PORT` e `END_PORT` che sono rispettivamente la porta d'inizio e la porte di fine. 

####

```bash
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
```

Verifico che i due estremi del range non superino `65535`, cherappresenta il limite massimo assoluto di porte di rete disponibili su qualsiasi computer o server, e non siano più piccoli di `1`. 
In questa sezione verifico anche se `START_PORT` è più grande di `END_PORT`. 

#### Scanning Porte

```bash
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
```

Lo scanning delle porte viene effettuato attraverso il comando `nc` e un ciclo `for`.
In particolare, al comando vengono passati i parametri:

- `-n` per disattivare il `DNS`. In questo modo posso inserire solo IP numerici e lo scan risulta più veloce.
- `-w` serve per impostare un `timeout`. Quando scade il timeout `nc` finisce con codice di uscita 1, quindi con errore, il che indica che la porta alla quale sta cercando di collegarsi o è `chiusa` o è `bloccata dal firewall`. 
  
Per capire se una porta è aperta o chiusa basta quindi leggere il codice di uscita del comando. Per questo motivo possiamo ignorare il suo output(`&> /dev/null`).

Per il codice di uscita basta leggere la variabile `$?`. 


### Nota Teorica sul UDP

Dato che l'UDP è `stateless` e non utilizza la `three-way handshake` è dificile capire se una porta è `aperta` o `filtrata`(bloccata dal firewall) sull'host. 

#### Porta Chiusa

Quando si invia un pacchetto UDP a una porta chiusa, il server remoto non ha un servizio attivo per gestirlo. Il sistema operativo del server si accorge di questo e risponde inviando indietro un pacchetto speciale di errore tramite un altro protocollo detto l'`ICMP`(Internet Control Message Protocol). 

Il messaggio inviato è `Destination Unreachable (Port Unreachable)`.

A questo punto `nc`  capisce che la porta è chiusa e restituisce un codice di errore `$?` diverso da `0`. Quindi so con certezza che la porta è chiusa. 

#### Porta Aperta/Filtrata

Se la porta UDP è aperta, l'applicazione remota riceve il pacchetto. Se il pacchetto non contiene una richiesta formattata esattamente come l'applicazione si aspetta, l'applicazione semplicemente lo ignora e non risponde. Se la porta UDP è filtrata da un firewall, il firewall scarta il pacchetto (regola `DROP`) e non risponde.

In entrambi i casi `nc` manderà il pacchetto, aspetterà lo scadere del timeout `(-w 1)`, ma non riceverà il messaggio `ICMP` di "Porta non raggiungibile", quindi considererà la porta come potenzialmente aperta. 