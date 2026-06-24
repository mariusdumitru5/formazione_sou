# IP Checker

Questo script serve a verificare se un indirizzo IP è valido o meno. Se l'IP è valido, lo script mostra una serie di informazioni utili come la `classe di appartenenza`, il `tipo di IP`(privato, publico o speciale). Se viene passata anche la maschera, è possibile visualizzare informazioni extra come indirizzo di rete(`NetID`), indirizzo di `broadcast` e `range di host possibili`.

## Espressioni Regolari 

Per la validazione dell'indirizzo IP sono state utilizzate una serie di `espressioni regolari estese(ERE)` che corrispondono alla varie classi di indirizzi IP. 
Per esempio, per verificare se un IP appartiene alla classe A si utilizza:

```bash
^([0-9]|[1-9][0-9]|1[0-2][0-7])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$
```

Un indirizzo IP appartiene alla classe A se è compresso tra `0.0.0.0` e `127.255.255.255`. Con l'espressione regolare di sopra viene fatto un controllo sul primo dei quattro gruppi che compongono l'IP(deve essere un numero tra 0 e 127) e poi sui restati tre gruppi. In particolare:

```bash
ˆ([0-9]|[1-9][0-9]|1[0-2][0-7])
```

- `^` indica l'inizio della stringa
- `[0-9]` sono le cifre a 0 a 9
- `[1-9][0-9]` copre i numeri da 10 a 99
- `1[0-2][0-7]` copre i numeri da 100 a 127

Le tre espressioni sono ragruppate all'interno di un **gruppo** `()` e messe in **or**(`|`) tra di loro. Questo significa che, partendo da sinistra verso destra, al primo match con un'espressione del gruppo, tutto il resto del gruppo verrà ignorato. 

Il secondo gruppo è molto simile al primo:

```bash
(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$
```

In questo caso, dato che utilizziamo le `ERE` per indicare il punto che separa i vari gruppi dell'IP si utilizza il `\`. In questo modo stiamo cercando di fare match su carattere `.`(punto). 
Quello che distingue questo gruppo dal primo è:

- `?` ciò che lo precede può ripetersi al massimo una volta(può essere anche zero)
- `{3}` indicano qaunte volte si deve ripetere il blocco all'interno della stringa con la quale stiamo cercando di fare match
- `$` indica la fine della stringa

### Note

Esistono due tipi di espressioni regolari: 

- `Basic Regular Expression(BRE)`
- `Extended Regular Expression(ERE)`

Entrambe hanno la stessa potenza espressiva perché possono fare più o meno le stesse cose. Quello che le differenzia è la `sintassi`!

#### Basic Regular Expression(BRE)

Nelle basic regular expression i caratteri come `.`, `?`, `{}`, `+`, `()` vengono interpretati come `testo letterale`. Per poter usare questi caratteri come `caratteri speciali` si deve aggiungere il carattere `\` prima di essi. 

Esempio:

```bash
\([0-9]\|[1-9][0-9]\|1[0-2][0-7]\)
```

#### Extended Regular Expression(ERE)

Nelle extended regular expression la situazione è al contrario. I caratteri come `.`, `?`, `{}`, `+`, `()` hanno un `significato speciale di default`. Per usare questi caratteri come caratteri testuali si utilizza il `\`.

Esempio:

```bash
^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$
```

Questa espressione serve a validare un indirizzo email. 

In Bash, quando si utilizza l'operatore `=~` all'interno delle doppie parentesi quadre `[[ ]]` il motore di Bash valuta la stringa a destra come se fosse un ERE.

## Funzionamento Script

Lo script prende gli argomenti dalla linea di comando attraverso `getopt`, un comando di Bash molto utile per la gestione dei parametri in modo facile. 

```bash
PARS=$(getopt -o i:m:h --long ip:,mask:,help -n "$0" -- "$@")
```

In questo modo sto eseguendo il comando `getopt` con i parametri:

- `-o` che indica i parametri brevi(come `-i` che serve per passare l'IP, `-m` per la maschera e `-h` per help). I parametri `-i e -m` richiedono obbligatoriamente un argomento dopo.
- `--long` che indica i parametri che hanno un nome più lungo di un carattere(`--ip`, `--mask` e `--help`).

Una volta presi i parametri, questi vengono salvati dentro la variabile `PARS`. Per assegnare questi parametri ai `parametri posizionali` di Bash si utilizza 

```bash
eval set -- "$PARS"
```

Esempio:

##### Nota: la maschera va passata nel formato CIDR senza lo slash

```bash
./checkip --ip 192.168.0.12 --mask 24
```

Dentro la variabile `PARS` avrò la lista degli argomenti in questo modo:

```bash
PARS= --ip '192.168.0.12' --mask '24' --
```

I due dash `--` alla fine indicano la fine degli argomenti per `getopt`. Quello che viene dopo sarà interpretato come testo che viene passato in input al comando.

Grazie a `eval set -- "$PARS"` avrò:

```bash
$1=--ip
$2=192.168.0.12
$3=--mask
$4=24
$5=--
```

Per utilizzare questi argomenti si utilizza un ciclo while insieme ad un `case`:

```bash
while true; do
    case "$1" in
        -i|--ip)
            IP="$2"
            shift 2
            ;;
        # ... altri casi (es. -p|--port, -h|--help) ...
        *)
            echo "Error: Unrecognized option!"
            exit 1
            ;;
    esac
done
```

Da notare l'utilizzo di `shift 2` che scarta l'opzione e il valore associato dopo avero usato. In questo caso l'opzione dopo e il suo valore saranno sempre in prima e seconda posizione(`$1` e `$2`). 

#### Funzione `to_dotted()`

Questa funzione si occupa della traduzione della maschera, che viene fornita in formato `CIDR`, nel formato `dotted decimal`.

```bash
to_dotted(){
    local cidr="$1"
    
    if [[ ! "$cidr" =~ ^[0-9]+$ ]] || [ "$cidr" -lt 0 ] || [ "$cidr" -gt 32 ]; then
        echo "Error: Invalid CIDR subnet mask. Must be a number between 0 and 32."
        exit 1
    fi

    local mask=$(( (0xffffffff << (32 - cidr)) & 0xffffffff ))
    # format the output 
    MASK_DECIMAL="$((mask>>24 & 255)).$((mask>>16 & 255)).$((mask>>8 & 255)).$((mask & 255))"
}
```

La parte più interessante è la parte finale.

```bash
  local mask=$(( (0xffffffff << (32 - cidr)) & 0xffffffff ))
```

Si occupa di creare la maschera in formato binario e funziona nel seguente modo:

```text
0xffffffff = 11111111111111111111111111111111
```

Corrisponde ad una stringa formato da 31 uno. 

```bash
(32 - cidr)
```

Rappresenta il numero di zeri alla fine della stringa binaria che rappresenta la maschera. 

```bash
(0xffffffff << (32 - cidr)) 
```

Questo fa `shiftare` i bit verso sinistra di `(32 - cidr)`. I bit che escono dalla stringa rimangono quando si lavora su sistemi a `64 bit`. 

```bash
((0xffffffff << (32 - cidr)) & 0xffffffff )
```

Infine, per azzerare tutti i bit che stanno fuori si fa l'`and`bit a bit. 

Esempio con maschera 24:

```text
(32 - 24) = 8
0xffffffff = 11111111.11111111.11111111.11111111

# devo shiftare di 8 posti a sinistra
0xffffffff << 8 = 11111111.11111111.11111111.00000000

# facendo l'and con 0xff ottengo la stessa cosa nei 32 bit dell'IP
# ma azzero i bit messi a 1 che sono stati shiftati a sinistra (fino a 64 bit)
0xffffffff << (32 - cidr)) & 0xffffffff = 11111111.11111111.11111111.00000000
```

Ora che ho ottenuto la maschera in binario, passo alla costruzione della maschera in formato `dotted decimal`:

```bash
MASK_DECIMAL="$((mask>>24 & 255)).$((mask>>16 & 255)).$((mask>>8 & 255)).$((mask & 255))"
```

In questo caso, per ottenere il numero di ogni blocco che compone la maschera devo portare un blocco (in binario) alla volta in corrispondenza degli ultimi 8 bit. Dopo aver fatto questo, faccio l'and bit a bit con 255. Questo azzera tutti gli altri blocchi e mantine l'ultimo. 
Il `blocco va sempre mandato in ultima posizione` perché il computer sa leggere il valore numerico di un byte solo quando si trova in quella precisa posizione. Se non lo si spostasse, il sistema leggerebbe un numero enorme anziché un valore compreso tra 0 e 255.

Esempio con maschera 24:

```text
mask = 11111111.11111111.11111111.00000000

# primo gruppo in decimale
   1         2        3        4
11111111.11111111.11111111.00000000

# devo shifare il blocco 1 di 24 bit, ottengo:
                               1
00000000.00000000.00000000.11111111

# ora devo fare l'and con 255
                               1
00000000.00000000.00000000.11111111
00000000.00000000.00000000.11111111
------------------------------------
00000000.00000000.00000000.11111111 = 255
```

Ho ottenuto cosi il primo gruppo decimale della maschera. 
Per trovare il secondo si fa:

```text
mask = 11111111.11111111.11111111.00000000

# primo gruppo in decimale
   1         2        3        4
11111111.11111111.11111111.00000000

# devo shifare il blocco 2 di 16 bit, ottengo:
                     1        2
00000000.00000000.11111111.11111111

# ora devo fare l'and con 255
                      1        2
00000000.00000000.11111111.11111111
00000000.00000000.00000000.11111111
------------------------------------
00000000.00000000.00000000.11111111 = 255
```

Per gli utltimi due gruppi si procede allo stesso modo. 

#### Funzione `get_netInfo()`

Questa funzione calcola: `indirizzo di rete`, `indirizzo di broadcast`, `primo host assegnabile` e `ultimo host assegnabile`.
Il cuore di questa funzione è:

```bash
IFS=. read -r i1 i2 i3 i4 <<< "$IP"
IFS=. read -r m1 m2 m3 m4 <<< "$MASK_DECIMAL"
	
net1=$((i1 & m1))
net2=$((i2 & m2))
net3=$((i3 & m3))
net4=$((i4 & m4))
NET_ID="$net1.$net2.$net3.$net4"

b1=$(( i1 | (255 - m1) ))
b2=$(( i2 | (255 - m2) ))
b3=$(( i3 | (255 - m3) ))
b4=$(( i4 | (255 - m4) ))
BADDR="$b1.$b2.$b3.$b4"
```

Prima, sia indirzzo IP che maschera in formato dotted vengono spezzati in gruppi.
Per calcolare l'indirizzo di rete si deve fare un `and bit a bit` tra indirizzo IP e maschera di rete. In Bash esiste l'operatore `&` che fa proprio questo. 
Faccio l'and bit a bit per ogni gruppo e poi costruisco l'indirzzo di rete nella variabile `NET_ID`.

Per quanto riguarda l'indirzzo di broadcast, l'approccio è simile. 
In questo caso devo fare l'`or bit a bit` tra l'indirizzo IP e il `complmentare` della maschera in formato dotted. 
Viene utilizzata l'operazione `(255 - gruppo)` perché in Bash, l'operatore di negazione dei bit(`~`) inverte anche il bit del segno. Questo farà si che tutti i numeri siano negativi.
Per evitare questo si utilizza  `(255 - gruppo)`.

Esempio

```text
valore da invertire: m1 = 255
valore invertito: (255 - m1) = 0

255 : 11111111 
0   : 00000000
```

Oppure

```text
valore da invertire: m1 = 192
valore invertito: (255 - m1) = 63

192 : 11000000 
63  : 00111111
```

Come si può vedere funziona e questa operazione fa esattamente l'operazione di negazione. 
