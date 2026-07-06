<h1 align="center">Problema del Lupo-Pecora-Cavolo</h1>

### Definizione Problema

Un contadino deve attraversare un fiume portando con se una pecora, un cavolo e un lupo. 

### Vincoli Problema 

Questo problema ha tre vincoli importanti:

- se lasciato da solo con la pecora, il lupo la mangia
- se lasciata da sola con il cavolo, la pecora lo mangia
- il contadino può portare solo un item alla volta da un parte all'altra.

### Obiettivo 

L'obiettivo di questo problema è quello di portare la pecora, il cavolo e il lupo dall'altra parte senza violare i vincoli.

### Soluzione Problema 

Per semplificare il modo in cui è presentata la soluzione, possiamo adottare la seguenete notazione:

- `L`: per indicare il lupo
- `P`: per indicare la pecora
- `C`: per indicare il cavolo 
- `X`: per indicare il contadino 

Stabilito questo, si può dudurre facilmente che il problema ha due soluzioni speculari che permettono di arrivare all'obiettivo in un numero minimo di mosse. 

```text
          Soluzione 1           |           Soluzione 2
Situazione iniziale: L C P X    |  Situazione iniziale: L C P X  
1. L C   ---P---> P X           |  1. L C   ---P---> P X 
2. L C X <------- P             |  2. L C X <------- P  
3. L     ---C---> P C X         |  3.   C   ---L---> P L X 
4. L P X <---P---   C           |  4. C P X <---P---   L   
5.   P   ---L--->   C L X       |  5.   P   ---C--->   C L X 
6.   P X <-------   C L         |  6.   P X <-------   C L   
7.       ---P---> P C L X       |  7.       ---P---> P C L X 
```

Il numero di mosse minimo per risolvere il problema è 7. Se proviamo a risolvere il problema spostando il contadino a destra e a sinistra senza che porti con se qualcosa abbiamo soluzioni a mosse infinite.

Le due soluzioni principali si possono rappresentare anche in questo modo:
<p align="center">
   <img src="../imgs/lpc.png" width="270" height="370" alt="Soluzioni Problema">
</p>

### Modelizzazione Problema 

Vogliamo modelizzare questo problema in modo da poterlo rappresentare nel ambito dei sistemi operativi. 
La soluzione proposta è quella di rendere il problema un `gioco interattivo`. 

##### Tecnologie adottate

Le tecnologie adottate per la modelizzazione del problema sono:

- `Vagrant`: per la creazione di una macchina virtuale, sarà il `playground`.
- `Ansible`: per fare il provisioning della macchina virtuale.
- `Docker`: per la creazione di container.
- `Bash`: per lo script che gestisce l'ambiente di gioco e i container.

##### Scelte implementative

Gli elementi caratteristici del problema si possono rappresentare in vari modi all'interno del sistema operativo, una possibile soluzione è la seguente:

- `attori`: posso rappresentare `pecora, cavolo, lupo e contadino` attraverso `container Docker`. 
- `sponde`: le due sponde del fiume possono essere rappresentate da `due reti Docker diverse`.
- `barca`: in questo caso la barca che trasporta il contadino insieme agli animali o al cavolo può essere rappresentata dal `deamon di Docker` che permette di switchare da una rete all'altra.
- `lo spostamento`: lo spostamento da una sponda all'altra del fiume può essere rappresentato tramite il passaggio di un container da una rete Docker ad un'altra.
- `mangiare qualcosa`: la violazione dei vincoli è rappresentata attraverso la distruzione dei container. 

##### Rappresentazione grafica

<img src="../imgs/lpc2.png" width="500"  alt="Sitazione Iniziale"> 
<img src="../imgs/lpc3.png" width="500">

Nella situazione iniziale, i container `Contadino, Pecora, Lupo e Cavolo` si trovano tutti sulla stessa rete, in questo modo si possono vedere tutti tra di loro. Quando il container `Contadino`(blu) si sposta insieme ad un container verde, cioè ad un altro attore, questi passano su un'altra rete Docker. In questo modo, dato che la rete è separata, i container di una sponda non vedranno i container dell'altra. 

Per applicare i vincoli, quando due attori coinvolti nel vincolo si trovano nella stesse rete e il container contadino non è presente, allora il vincolo verrà applicato e in base alla circostanza il cavolo o la pecora veranno mangiati. Essere mangiati corrisponde al fermare i container e a perdere il gioco. 


# Implementazione 

Tutta la logica del gioco si trova all'interno del file `play.sh`. 
Lo script è suddiviso in varie funzioni che hanno lo scopo di rendere tutto modulare e facile da gestire.

### Gestione del Gioco e della Logica

##### `game_action`

È il cuore della logica interattiva. Riceve l'input dell'utente, richiama le funzioni di validazione e orchestra lo spostamento. Gestisce inoltre l'aggiornamento della variabile `SPONDA_CORRENTE` e invoca i controlli per decretare la vittoria o la sconfitta.

##### `sposta_personaggi`

Esegue l'azione fisica sui container. Utilizza i comandi `docker network disconnect` e `docker network connect` per spostare il container del contadino (che si muove sempre) e l'eventuale container dell'attore selezionato dalla rete di origine a quella di destinazione.

##### `controlla_vincoli`

Analizza i container presenti sulla sponda dove il contadino non si trova. Se rileva la combinazione "lupo e pecora" o "pecora e cavolo" sulla stessa rete, allora è Game Over.

##### `controlla_vittoria`

Verifica la condizione di successo. Conta quanti container sono connessi alla rete sponda_destra; se il totale è esattamente 4, stampa il messaggio di vittoria.

### Helper e Validazione

##### `validate_input`

Riceve il tipo di input da controllare (actor o action) e la stringa digitata dall'utente. Assicura che si possano muovere solo i 4 attori previsti e che le uniche direzioni ammesse siano "destra" o "sinistra".

##### `prendi_sponda`

Interroga Docker tramite `docker inspect` per scoprire a quale rete (sponda sinistra o destra) è attualmente collegato un determinato container.

##### `verifica_presenza_contadino`

Controlla che il contadino sia fisicamente sulla stessa sponda dell'oggetto che l'utente vuole spostare. Impeadisce al giocatore di teletrasportare un oggetto dall'altra parte del fiume!

### Interfaccia Utente

##### `mostra_regole`

Pulisce lo schermo e stampa le istruzioni del gioco, le regole di sopravvivenza e la sintassi dei comandi.

##### `disegna_fiume`

Usa docker `network inspect` su entrambe le sponde per recuperare la lista dei container presenti. Stampa poi una tabella visuale aggiornata in tempo reale, mostrando da quale parte del "fiume" si trovano i vari attori.