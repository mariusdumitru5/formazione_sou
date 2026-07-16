<h1 align="center">Ansible Practice</h1>

In qusta cartella sono contenuti i tre esercizi bonus su Ansible. Questi esercizi prevedono l'utilizzo di `ansible vault, dizionari, liste e template`. 

#### Concetti chiave

##### `Ansible Vault`

Ansible Vault è una funzionalità nativa di Ansible che permette di crittografare file e variabili sensibili (come password, chiavi SSH, ...) direttamente all'interno del progetto. 

Per creare un file crittografato: 

```bash
ansible-vault create secrets.yaml
```

Per modificare un file esistente:

```bash
ansible-vault edit secrets.yaml
```

Per crittografare un file esistente 

```bash
ansible-vault encrypt secrets.yaml
```

Per decrittografare un file:

```bash
ansible-vault decrypt secrets.yaml
```

Per visualizzare il contenuto in chiaro e basta:

```bash
ansible-vault view secrets.yaml
```

Per integrare i valori contenuti nel vault all'interno di un playbook basta includere il file:

```yaml
vars_files:
    - secrets.yaml 
```

Per eseguire un playbook che contiene valori all'interno del vault è necessario inserire la password creata quando si criptano i dati:

```bash
# chiede la password a terminale in modo interattivo
ansible-playbook playbook.yml --ask-vault-pass

# file di testo locale contenente la password
ansible-playbook playbook.yml --vault-password-file .vault_pass
```

###### Esempio utilizzo

1. Prendo un file che contiene le password di due utenti:

```yaml
# secrets.yaml
user_1_pass: 1234
user_2_pass: 5678
```

2. Cripto il file con `ansible-vault`:

```bash
ansible-vault encrypt secrets.yaml
```

3. Utilizzo le password in un file dove definisco gli utenti:

```yaml
---
# users.yaml
users:
  marius:
    state: present 
    groups: sudo
    append: true
    home: /home/marius 
    shell: /bin/bash
    password: "{{ user_1_pass }}" # variabile che si trova nel vault
    update_password: always
  tom:
    state: present 
    groups: sudo
    append: true
    home: /home/tom
    shell: /bin/bash
    password: "{{ user_2_pass }}" # variabile che si trova nel vault
    update_password: always
```

##### Nota: 

Dato che la sintassi `{{ user_1_pass }}` prende il valore dal vault e lo mette in chiaro, per utilizzare la password come una password criptata devo usare un filtro `jinja2` per criprare il testo!

4. Utilizzo gli utenti in un playbook:

```yaml
---
- name: Gestione utenti
    ansible.builtin.user:
      name: "{{  item.key }}"
      state: "{{ item.value.state }}"
      groups: "{{ item.value.groups }}"
      append: "{{ item.value.append }}"
      home: "{{ item.value.home }}"
      shell: "{{ item.value.shell }}"
      password: "{{ item.value.password | password_hash('sha512')}}"
      update_password: "{{ item.value.update_password }}"
    loop: "{{ users | dict2items }}"
```


##### `Dizionari e Liste`

Dizionari e liste sono due strutture dati complesse che si possono utilizzare con Ansible.

Per definire una `lista`:

```yaml
vars:
  packages:
    - curl
    - ca-certificates
    - git
    - apache2

# alternativa 
vars:
  users: ['mario', 'luigi', 'peach']

```

Per accedere agli elementi della lista si utilizzano le parentesi quadre per fare indexing:

```yaml
- name: Mostra il primo utente e pacchetto delle liste
  ansible.builtin.debug:
    msg: 
      - "Il primo utente è {{ users[0] }}" # mario
      - "Il primo pacchetto è {{ packages[0] }}" #curl
```

Sulle liste funziona anche l'indexing a partire dall'ultimo elemento:

```yaml
- name: Mostra il primo utente e pacchetto delle liste
  ansible.builtin.debug:
    msg: 
      - "L'ultimo utente è {{ users[-1] }}" # peach
      - "L'ultimo pacchetto è {{ packages[-1] }}" # apache2
```

Le liste possono essere utilizzate con i `loop` in un task:

```yaml
- name: Crea tutti gli utenti della lista
  ansible.builtin.user:
    name: "{{ item }}"
    state: present
  loop: "{{ utenti }}"
```

Posso fare anche slicing su una lista

```yaml
- name: Slicing lista
  ansible.builtin.debug:
    msg: "I primi due utenti sono {{ utenti[0:2] }}" # [mario, luigi]
```

Per definire un `dizionario`:

```yaml
vars:
  server_web:
    port: 80
    service: nginx
    state: started
```

Per accedere ai valori del dizionario ci sono due metodi equivalenti:

```yaml
- name: Mostra il servizio 
  ansible.builtin.debug:
    msg: "Il servizio installato è {{ server_web.service }}" # nginx

# alternativa 
- name: Mostra la porta 
  ansible.builtin.debug:
    msg: "La porta è la {{ server_web['port'] }}" # 80
```

Non posso usare un dizionario direttamente con un `loop`, devo prima convertirlo in una lista, per fare questo uso un filtro `jinja2(dict2items)`:

```yaml
- name: Elenca tutta la configurazione del server
  ansible.builtin.debug:
    msg: "Parametro: {{ item.key }} -> Valore: {{ item.value }}"
  loop: "{{ server_web | dict2items }}"
```

##### `Templates`

I Template in Ansible consentono di generare file di configurazione dinamici e personalizzati (es. index.html, vhost.conf, ...) direttamente sulle macchine di destinazione. 

Invece di copiare un file statico identico su tutti i server, un template legge le variabili e le specifiche hardware di ogni singola macchina per creare un file specifici al momento dell'esecuzione. 

Si possono usare i construtti condizionali come `if/else` e quelli per fare cicli `for`. 

##### Esempio

Stampa di un paragrafo diverso in un file html:

```j2
<h1>Benvenuto su {{ ansible_facts['hostname'] }}</h1>

{% if ansible_facts['hostname'] == 'server' %}
  <p>Questo è il server centrale di controllo.</p>
{% else %}
  <p>Questo è un nodo client periferico.</p>
{% endif %}
```

Ciclo per ripetere una stessa azione(stampa) più volte:

```j2
{% for user in users_whitelist %}
+ : {{ user }} : ALL
{% endfor %}
```

Per usare i template:

```yaml
- name: Gestione Template 
    ansible.builtin.template:
      src: templates/index.html.j2
      dest: /var/www/html/index.html
      owner: vagrant
      group: vagrant 
      mode: '0644' 
    notify: "restart-web"
```
