# Evita blocchi interattivi con GRUB
export DEBIAN_FRONTEND=noninteractive
apt-mark hold grub-pc grub-pc-bin grub2-common grub-imagebuilder 2>/dev/null

# update and upgrade del sistema 
sudo apt-get update && sudo apt-get upgrade -y 

# install di haproxy per il reverse proxy server
sudo apt-get install -y haproxy

# creazione cartella certificati
sudo mkdir -p /etc/haproxy/certs

# creazione certificato con openssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/haproxy.key \
        -out /etc/haproxy/certs/haproxy.crt \
        -subj "/C=IT/ST=Italy/L=Rome/O=MyProxy/CN=localhost"

# unione certificate e chiave in un unico file .pem
sudo bash -c 'cat /etc/ssl/private/haproxy.key /etc/haproxy/certs/haproxy.crt > /etc/haproxy/certs/haproxy.pem'

# configurazione server /etc/haproxy/haproxy.cfg
sudo tee -a /etc/haproxy/haproxy.cfg <<EOF
# traffico in ingresso al reverse proxy server
frontend in_traffic
	bind *:80
	# configurazione per https --> passo il certificato x509
	bind *:443 ssl crt /etc/haproxy/certs/haproxy.pem
	mode http
	# redirect su https se il client fa la richiesta con http
	http-request redirect scheme https unless { ssl_fc }
	# definisco le acl per fare smistamento del traffico 
	acl accounts_path path_beg /accounts
	acl login_path path_beg /login
	# smisto il traffico in base alle acl
	use_backend backend_server1 if accounts_path 
	use_backend backend_server2 if login_path
	# backend di default 
	default_backend home_page

backend home_page
	mode http
	balance leastconn # algoritmo di load balancing                          
	option httpchk
	http-check send meth HEAD uri / ver HTTP/1.1 hdr Host localhost
	# controllo dello stato di salute dei server
	default-server inter 2s rise 2 fall 3
	
	# entrambi i server rispondono per la home
	server node1 192.168.1.11:80 check
	server node2 192.168.1.12:80 check

# backend server 1: accetta le richeste con /accounts
backend backend_server1
	mode http
	option httpchk
	http-check send meth HEAD uri / ver HTTP/1.1 hdr Host localhost
	server node1 192.168.1.11:80 check
		
# backend server 2: accetta le richeste con /login
backend backend_server2
	mode http
	option httpchk 
	http-check send meth HEAD uri / ver HTTP/1.1 hdr Host localhost
	server node2 192.168.1.12:80 check
EOF

# restart di haproxy per applicare la nuova configurazione
sudo systemctl restart haproxy
