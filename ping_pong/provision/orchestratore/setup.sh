# evita blocchi interattivi con GRUB
export DEBIAN_FRONTEND=noninteractive
apt-mark hold grub-pc grub-pc-bin grub2-common grub-imagebuilder 2>/dev/null

# update and upgrade del sistema 
apt-get update && apt-get upgrade -y
            
# genera la chiave ssh per l'utente vagrant se non esiste
if [ ! -f /home/vagrant/.ssh/id_ed25519 ]; then
    sudo -u vagrant ssh-keygen -t ed25519 -N "" -f /home/vagrant/.ssh/id_ed25519
fi
            
# disabilita StrictHostKeyChecking per evitare prompt interattivi durante la prima connessione SSH
cat <<EOF > /home/vagrant/.ssh/config
Host 192.168.1.*
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null
EOF
# rido i permesi all'utente vagrant per il file di config
chown vagrant:vagrant /home/vagrant/.ssh/config
chmod 600 /home/vagrant/.ssh/config

# copia la chiave nella cartella condivisa di Vagrant (/vagrant) per distribuirla
cp /home/vagrant/.ssh/id_ed25519.pub /vagrant/orchestratore_id_ed25519.pub
chown vagrant:vagrant /vagrant/orchestratore_id_ed25519.pub
echo "Chiave generata e condivisa!"

# script per far avviare il ping-pong
cat <<'EOF' > /home/vagrant/play.sh
#!/usr/bin/env bash
#
# Autore: Marius Dumitru
# Data: June 17 2026
# Versione: 0.0.1
# Descrizione:  Questo script fa da orchestratore per due container docker che si avviano e si spengono
#               in modo alternato ogni 60 secondi. 
########################################################################################################

# controllo input argomenti corretti linea di comando 
PARS=$(getopt -o t:h --long time:,n1:,n2:,help -n "$0" -- "$@")

if (("$?" != 0)); then
    echo "Errore nell'analisi degli argomenti."
    echo "Per maggiori informazioni fare: $0 --help"
    exit 1
fi

# Riorganizzazione dei parametri
eval set -- "$PARS"

# configurazione IP delle macchine virtuali 
USER_VM="vagrant"
IP_VM1="192.168.1.5"
IP_VM2="192.168.1.6"

# configurazione docker
IMG="ealen/echo-server:latest"
CONTAINER_NAME="echo-server" 
PORT="-p 8080:80"
DURATION=30

# nomi delle macchine
NOME_MACCHINA_1="macchina 1"
NOME_MACCHINA_2="macchina 2"

# lettura parametri 
while true; do
    case "$1" in
        -t|--time)
            DURATION="$2"
            shift 2
            ;;
        --n1)
            NOME_MACCHINA_1="$2"
            shift 2
            ;;
        --n2)
            NOME_MACCHINA_2="$2"
            shift 2
            ;;
        -h|--help)
            echo "Uso: $0 [-t|--time secondi] [--n1 nome_macchina1] [--n2 nome_macchina2]"
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Opzione non riconosciuta!"
            exit 1
            ;;
    esac
done

# funzione di countdown
countdown() {
        local s=$1
        local msg=$2
        while ((s >= 0));do
                printf "\r%s: [%2d s] rimanenti..." "$msg" "$s"
                sleep 1
                ((s--))
        done
        printf "\r%s: [Tempo Scaduto!]       \n" "$msg"
 }

 # funzione per fermare il container
 stop_container() {
        local ip=$1
        ssh -q "$USER_VM"@"$ip" "docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME" > /dev/null 2>&1
 }

 # funzione per avviare un container
 start_container() {
        local ip=$1
        local nome_macchina=$2
        local p=$3
        echo "Passaggio palla a $nome_macchina($ip)"
        echo "$nome_macchina: $p"
        ssh -q "$USER_VM"@"$ip" "docker run -d --name $CONTAINER_NAME $PORT $IMG" > /dev/null
        countdown $DURATION "$nome_macchina" 
        echo "Fermo $nome_macchina"
        stop_container "$ip"
}


# pulizia ambiente
echo "Preparazione tavolo da gioco..."
stop_container $IP_VM1
stop_container $IP_VM2

# gioco infinito
while true; do
        # turno della macchina 1
        start_container $IP_VM1 "$NOME_MACCHINA_1" "PING"
        echo " "
        # turno della macchina 2
        start_container $IP_VM2 "$NOME_MACCHINA_2" "PONG"
        echo " "
done
EOF


# assegna il file a vagrant e lo rende eseguibile
chown vagrant:vagrant /home/vagrant/play.sh
chmod +x /home/vagrant/play.sh
echo "Script play.sh pronto in /home/vagrant/play.sh!"
