# evita blocchi interattivi con GRUB
export DEBIAN_FRONTEND=noninteractive
apt-mark hold grub-pc grub-pc-bin grub2-common grub-imagebuilder 2>/dev/null

# update and upgrade del sistema 
apt-get update && apt-get upgrade -y

# install di curl
apt-get install -y curl

# scarica script per installare docker 
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# permette all'utente vagrant di usare docker senza sudo
usermod -aG docker vagrant

 # automazione ssh: accetta la chiave dell'orchestratore non appena viene creata
if [ -f /vagrant/orchestratore_id_ed25519.pub ]; then
    mkdir -p /home/vagrant/.ssh
    touch /home/vagrant/.ssh/authorized_keys
    
    # leggo la chiave pubblica dall cartella condivisa 
    PUB_KEY=$(cat /vagrant/orchestratore_id_ed25519.pub)
    
    # inserisco la chiave solo se non è già presente
    if ! grep -q "$PUB_KEY" /home/vagrant/.ssh/authorized_keys; then
        echo "$PUB_KEY" >> /home/vagrant/.ssh/authorized_keys
        echo "Chiave dell'orchestratore iniettata con successo!"
    fi
    
    # ripristina i permessi corretti per SSH
    chown -R vagrant:vagrant /home/vagrant/.ssh
    chmod 700 /home/vagrant/.ssh
    chmod 600 /home/vagrant/.ssh/authorized_keys
fi