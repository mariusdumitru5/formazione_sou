# Reverse Proxy
## Obiettivo
L'obiettivo dell'esercizio è quello di creare un'architettura basata su tre macchine: una macchina che fa da `reverse proxy server`, che dirige il traffico verso altre due macchine che fanno da `server backend`. Lo smistamento del traffico deve avvenire in base ad un filtro(per esempio: `/accounts` va sulla macchina backend 1 e `/login` che va sulla macchina backend 2). E' richiesto inoltre che il client comunichi con il server proxy tramite `https`, mentre la comunicazione server proxy - server backend deve avvenire tramite `http`. Per questo motivo è richiesto anche creare un certificato e autofirmarlo.
## Architettura
![Architettura Reverse Proxy](imgs/architettura_reverse_proxy.png)

In questa architettura il client fa una richiesta `https` al server reverse proxy(`1`). 
- Se il client cerca `https://192.168.1.10:443/accounts/` il server proxy inoltra la richiesta tramite `http `al server backend 1(`2`).
- Se il client cerca `https://192.168.1.10:443/login/` il server proxy inoltra la richiesta tramite `http `al server backend 2.
Una volta che il server backend riceve la richiesta, la elabora e spedisce la risposta al server reverse proxy(`3`) tramite `http`. Ricevuta la risposta, il server reverse proxy la inoltra tramite `https` al client(`4`). In questo modo il client non saprà da quale server backend ha ricevuto la risposta.

## Implementazione
Tutto è realizzato tramite  `Vagrant`. Tutte e tre la macchine sono collegate alla stessa rete virtuale privata: `192.268.1.0/24`. Tutto il sistema risulta portabile grazie al `provisioning` fatto attraverso script bash. 
### Server Reverse Proxy
Sulla macchina che fa da reverse proxy server è in funzione `haproxy`. Questo programma permette di fare load balancing e svolge la funzione di reverse proxy. 
Per installare questo software:
```bash
sudo apt-get install -y haproxy 
```
Una volta installato dovrebbe già essere attivo e in funzione, per una verifica veloce:
```bash
sudo systemctl status haproxy
```
Se non è attivo e/o in funzione:
```bash
sudo systemctl enable haproxy
sudo systemctl start haproxy
```
Una volta fatto questo, la prossima cosa da fare è generare un certificato e autofirmarlo. Per farlo si può usare la libreria `openssl`, una libreria `open-source` che permette di generare certificati `.crt` e chiavi private(tra le varie cose che può fare). 
Per creare un certificato `.pem` sono necessari due passaggi:
1. Creazione chiave privata e certificato `.crt`
2. Unione certificato e chiave privata in un unico file `.pem`(richiesto da `haproxy`). 
Per la creazione della chiave privata e del certificato si utilizza il comando:
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/ssl/private/haproxy.key \
	-out /etc/haproxy/certs/haproxy.crt \
	-subj "/C=IT/ST=Italy/L=Rome/O=MyProxy/CN=localhost"
```
Dove:
- `-x509` è il tipo di certificato creato, in questo caso sarà firmato dalla stessa chiave privata di chi lo ha creato, quindi è autofirmato.
- `-nodes` sta per `No DES`, cioè non voglio proteggere la chiave privata con una password, serve per evitare di inserire la password ogni volta che riavvio il server o la macchina virtuale.
- `-days` è il numero di giorni di validità del certificato.
- `-newkey rsa:2048` crea una chiave privata usando la cifratura `RSA` con lunghezza 2048 bit.
- `-keyout /etc/ssl/private/haproxy.key` è il percorso dove viene salvata la chiave privata.
- `-out /etc/haproxy/certs/haproxy.crt` è il percorso dove viene salvato il certificato pubblico. 
- `-subj "..."` permette di compilare i dati del proprietario del certificato direttamente da linea di comando. Il campo più importante è `CN=localhost` che specifica l'IP o il nome del dominio utilizzo per raggiungere il sito da browser. 

Una volta creata la chiave e il certificato, per unire le due cose:
```bash
mkdir -p /etc/haproxy/certs
sudo bash -c 'cat /etc/ssl/private/haproxy.key /etc/haproxy/certs/haproxy.crt > /etc/haproxy/certs/haproxy.pem'
```
#### Configurazione Haproxy
Il file di configurazione di `Haproxy` si trova in `/etc/haproxy/haproxy.cfg`.
Per configurarlo sono state create due sezioni:
1. Frontend del server reverse proxy
```c
frontend in_traffic
	bind *:80 
	# configurazione per https --> passo il certificato x509
	bind *:443 ssl crt /etc/haproxy/certs/haproxy.pem
	mode http
	http-request redirect scheme https unless { ssl_fc }

	# controll access lists per fare da filtro
	acl accounts_path path_beg /accounts
	acl login_path path_beg /login

	# assegnazione server backend
	use_backend backend_server1 if accounts_path
	use_backend backend_server2 if login_path
	default_backend home_page
```
In questa sezione è stato inserito `bind *:443` per ascoltare il traffico sulla porta `443`, la porta di default del protocollo `htpps`. E' stato poi passato il certificato creato in precedenza. Questo server reverse proxy reindirizza il client sulla porta 443 se prova a collegarsi sulla porta 80, in questo modo tutte le connessioni al frontend sono sicure. Per fare il `content switching` sono state utilizzate le `access control lists`.

2. Server di backend 
```c
backend home_page
	mode http
	balance leastconn
	option httpchk
	http-check send meth HEAD uri / ver HTTP/1.1 hdr Host localhost
	# controllo dello stato di salute dei server
	default-server inter 2s rise 2 fall 3
	# entrambi i server rispondono per la home
	server node1 192.168.1.11:80 check
	server node2 192.168.1.12:80 check

backend backend_server1
	mode http
	option httpchk
	http-check send meth HEAD uri / ver HTTP/1.1 hdr Host localhost
	server node1 192.168.1.11:80 check

backend backend_server2
	mode http
	option httpchk
	http-check send meth HEAD uri / ver HTTP/1.1 hdr Host localhost
	server node2 192.168.1.12:80 check
```
La sezione backend è divisa in tre sottosezioni, una per la pagina home e due per il `content switching`. Per la pagina home è utilizzato anche un metodo di load balancing, viene scelto il server con meno connessioni attive per mostrare la home page. 
Su entrambi i server vengono effettuati check di salute, per vedere se sono spenti o stanno funzionando. Il server reverse proxy invia una richiesta `http` ai server chiedendo l'intestazione del sito. 

Una volta fatto tutto va controllato se il file è scritto bene con:
```bash
sudo haproxy -c -f /etc/haporxy/haproxy.cfc
```
Se va tutto bene, devo riavviare il server con:
```bash
sudo systemctl restart haproxy
```
In questo modo prende le nuove modifiche. 
### Server Backend
Sui server backend è in funzione il `web-server apache`. Per installarlo:
```bash
sudo apt-get install -y apache2
```
Una volta installato basta verificare che sia attivo e in funzione:
```bash
sudo systemctl status apache2
```
Se non è attivo e/o in funzione:
```bash
sudo systemctl enable apache2
sudo systemctl start apache2
```
#### Creazione homepage
Su entrambi i server è stato modificato il file `/var/www/html/index.html`. Questo file contiene la pagina di default che fa vedere il server sulla porta 80. E' stata creata una pagina Home(con l'aiuto di gemini a scopo dimostrativo). 

#### Creazione sottocartelle per il `content switching
Per il content switching è necessario avere una cartella `accounts` per i percorsi `/accounts/`(macchina 1) e una cartella `login` per i percorsi `/login/`(macchina 2).
Ho creato queste cartelle e in ognuna ho caricato un file `ìndex.htlm`(fatto sempre con gemini!). Le cartelle servono perché il server reverse proxy inoltra la richiesta del client al server giusto e questo cercherà proprio quella cartella. Se la cartella non esiste verrà visualizzato l'errore 404. 
#### Traffico porta 80
Per evitare che i client provino a collegarsi direttamente ai server di backend si può gestire il traffico attraverso il firewall. In questo modo mi assicuro che solo il server reverse proxy comunica con i server di backend:
```bash
sudo ufw --force reset
# blocco tutto in ingresso 
sudo ufw default deny incoming
# lascio libere le connessioni in uscita
sudo ufw default allow outgoing

# lascio funzionare ssh
sudo ufw allow 22/tcp
# consento solo al server reverse proxy di usare la porta 80
sudo ufw allow from 192.168.1.10 to any port 80 proto tcp

# attivo il firewall
sudo ufw --force enable
```
