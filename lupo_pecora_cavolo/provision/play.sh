#!/usr/bin/env bash

# colori per l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'  
RESET='\033[0m'

# nomi container
CONTADINO="contadino"
LUPO="lupo"
PECORA="pecora"
CAVOLO="cavolo"

# nomi reti docker per rappresentare le due sponde del fiume 
SPONDA_1="sponda_sinistra"
SPONDA_2="sponda_destra"

# variabili di stato 
SPONDA_CORRENTE="$SPONDA_1"

# funzione per stampare le regole di gioco
mostra_regole() {
    clear
    printf "${YELLOW}======================================================================${RESET}\n"
    printf "${GREEN}      IL GIOCO DEL LUPO, DELLA PECORA E DEL CAVOLO (Docker Edition)   ${RESET}\n"
    printf "${YELLOW}======================================================================${RESET}\n\n"
    
    printf "Benvenuto! Il tuo obiettivo è trasportare il contadino e i suoi tre beni\n"
    printf "dalla ${YELLOW}%s${RESET} alla sponda opposta usando una barca.\n\n" "$SPONDA_1"
    
    printf "${RED}ATTENZIONE ALLE REGOLE DI SOPRAVVIVENZA:${RESET}\n"
    printf "1. Se il contadino si allontana, il ${RED}lupo mangia la pecora${RESET}.\n"
    printf "2. Se il contadino si allontana, la ${RED}pecora mangia il cavolo${RESET}.\n"
    printf "3. La barca può portare solo il ${GREEN}contadino e un solo altro elemento${RESET} alla volta.\n\n"
    
    printf "${YELLOW}ELEMENTI ACCETTATI DAL GIOCO:${RESET}\n"
    printf "• ${GREEN}Attori disponibili:${RESET}    contadino, lupo, pecora, cavolo\n"
    printf "• ${GREEN}Direzioni valide:${RESET}      destra, sinistra\n\n"
    
    printf "${YELLOW}COME GIOCARE:${RESET}\n"
    printf "Inserisci i comandi nel formato: ${GREEN}<attore> <direzione>${RESET}\n"
    printf "Esempi validi:\n"
    printf "  - 'contadino destra' (il contadino si sposta da solo)\n"
    printf "  - 'pecora destra'     (il contadino sposta la pecora)\n"
    printf "  - Per arrenderti e uscire dal gioco, digita: ${RED}exit${RESET}\n\n"
    
    printf "${YELLOW}======================================================================${RESET}\n"
}

# funzione per la validazione input 
validate_input(){
        local type=$1
        local input=$2

        if [[ "$type" == "actor" ]]; then
            case "$input" in
                lupo|pecora|cavolo|contadino)
                    return 0 ;; # ritorna successo senza stampare nulla
                *)
                    return 1 ;; # input non valido
            esac
        fi

        if [[ "$type" == "action" ]]; then
            case "$input" in
                destra|sinistra)
                    return 0 ;;
                *)
                    return 1 ;;
            esac
        fi
}

# funzione per trovare la rete alla quale un container è collegato
prendi_sponda() {
    local container_name=$1
    docker inspect "$container_name" --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}' 2> /dev/null
}

# funzione per verificare se il contadino si trova sulla stessa sponda dell'item da spostare
verifica_presenza_contadino() {
    local actor=$1

    # il contadino è sempre con se stesso, quindi nulla da verificare 
    if [[ "$actor" == "$CONTADINO" ]]; then
        return 0
    fi
    
    # predo la sponda dell'attore che voglio spostare 
    local sponda_attore=$(prendi_sponda "$actor")

    if [[ "$sponda_attore" == "$SPONDA_CORRENTE" ]]; then
        return 0 # sono insieme
    else
        return 1 # il contadino è dall'altra parte
    fi
    
}

# funzione per spostare i container da una rete all'altra
sposta_personaggi() {
    local actor=$1
    local direzione=$2  # destra o sinistra
    local origine="$SPONDA_CORRENTE" # l'origine è sempre dove si trova il contadino adesso
    local destinazione=""

    # rete di destinazione
    if [[ "$direzione" == "destra" ]]; then
        destinazione="$SPONDA_2"
    else
        destinazione="$SPONDA_1"
    fi

    # sposto il contadino, lui si sposta sempre anche con gli altri
    docker network disconnect "$origine" "$CONTADINO" 2> /dev/null
    docker network connect "$destinazione" "$CONTADINO" 2> /dev/null

    # sposto un personaggio diverso dal contadino 
    if [[ "$actor" != "$CONTADINO" ]]; then
        docker network disconnect "$origine" "$actor" 2> /dev/null
        docker network connect "$destinazione" "$actor" 2> /dev/null
        printf "${GREEN}Trasportato con successo: %s e %s sulla %s!${RESET}\n" "$CONTADINO" "$actor" "$destinazione"
    else
        printf "${GREEN}Trasportato con successo: %s sulla %s!${RESET}\n" "$CONTADINO" "$destinazione"
    fi
}

# funzione per controllare i vincoli del problema
controlla_vincoli() {
    # prendo la sponda opposta a quella dove sta il contadino, lui non deve esserci 
    local sponda_da_controllare=""
    if [[ "$SPONDA_CORRENTE" == "$SPONDA_1" ]]; then
        sponda_da_controllare="$SPONDA_2"
    else
        sponda_da_controllare="$SPONDA_1"
    fi

    # prendo la lista dei container che stanno sulla stessa rete(sponda)
    local elementi_sponda=$(docker network inspect "$sponda_da_controllare" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)

    # vincolo 1: percora e lupo sulla stessa sponda 
    if echo "$elementi_sponda" | grep -q "$LUPO" && echo "$elementi_sponda" | grep -q "$PECORA"; then
        printf "${RED}\n=================== GAME OVER ===================${RESET}\n"
        printf "${RED}Hai lasciato il lupo e la pecora da soli sulla %s!${RESET}\n" "$sponda_da_controllare"
        printf "${RED}Il lupo ha divorato la pecora.${RESET}\n"
        printf "${RED}=================================================${RESET}\n\n"
        return 1 # sconfitta
    fi

    # vincolo 2: pecora e cavolo sulla stessa sponda 
    if echo "$elementi_sponda" | grep -q "$PECORA" && echo "$elementi_sponda" | grep -q "$CAVOLO"; then
        printf "${RED}\n=================== GAME OVER ===================${RESET}\n"
        printf "${RED}Hai lasciato la pecora e il cavolo da soli sulla %s!${RESET}\n" "$sponda_da_controllare"
        printf "${RED}La pecora ha mangiato il cavolo.${RESET}\n"
        printf "${RED}=================================================${RESET}\n\n"
        return 1 # sconfitta
    fi

    return 0 # 0 indica che tutto è sicuro
}

# funzione per controllare se ho tutti gli attori sulla sponda destra
controlla_vittoria() {
    # se il contadino non è ancora a destra, la vittoria è impossibile
    if [[ "$SPONDA_CORRENTE" != "$SPONDA_2" ]]; then
        return 1
    fi

    # devo contare quanti attori sono sulla sponda_destra
    local conteggio_destra=$(docker network inspect "$SPONDA_2" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | wc -w)

    # se tutti i container sono sulla sponda_destra, allora vittoria!!
    if [[ "$conteggio_destra" -eq 4 ]]; then
        printf "${GREEN}\n=================================================${RESET}\n"
        printf "${GREEN}          CONGRATULAZIONI! HAI VINTO!         ${RESET}\n"
        printf "${GREEN} Sei riuscito a portare tutti in salvo a destra! ${RESET}\n"
        printf "${GREEN}=================================================${RESET}\n\n"
        return 0 # vittoria 
    fi

    return 1 # game still goes on 
}

# funzione per gestire il gioco
game_action(){
    local input=$1

    read -r actor action <<< "$input"
    # echo "attore: $actor, azione: $action"
   
    # verifica validità attore
    if ! validate_input "actor" "$actor"; then
        printf "${RED}Errore: Il personaggio '%s' non esiste!${RESET}\n" "$actor"
        return 1 
    fi 
   
    # verifica validità azione
    if ! validate_input "action" "$action"; then
        printf "${RED}Errore: La direzione '%s' non è valida! Usa 'destra' o 'sinistra'.${RESET}\n" "$action"
        return 1 
    fi

    # verifica presenza contadino
    if ! verifica_presenza_contadino "$actor"; then
        printf "${RED}Errore: Il contadino non può muovere ' %s' perché si trova sull'altra sponda!${RESET}\n" "$actor"
        return 1
    fi

    # verifica che il contadino non si sposti sulla sponda che sta già 
    if [[ "$SPONDA_CORRENTE" == "$SPONDA_1" && "$action" == "sinistra" ]]; then
        printf "${RED}Errore: Ti trovi già sulla sponda sinistra! Puoi andare solo a 'destra'.${RESET}\n"
        return 1
    fi

    if [[ "$SPONDA_CORRENTE" == "$SPONDA_2" && "$action" == "destra" ]]; then
        printf "${RED}Errore: Ti trovi già sulla sponda destra! Puoi andare solo a 'sinistra'.${RESET}\n"
        return 1
    fi

    # sposto i container da un rete all'altra
    sposta_personaggi "$actor" "$action"

    # aggiorno la sponda corrente 
    if [[ "$action" == "destra" ]]; then
        SPONDA_CORRENTE="$SPONDA_2"
    else
        SPONDA_CORRENTE="$SPONDA_1"
    fi
    
    # controllo sui vincoli del problema
    if ! controlla_vincoli; then
        # game over, pulisco i container ed usco dallo script
        printf "${YELLOW}Termino i container e chiudo il gioco...${RESET}\n"
        docker rm -f "$CONTADINO" "$LUPO" "$PECORA" "$CAVOLO" > /dev/null 2>&1 || true
        exit 1 # termino lo script
    fi

    # controllo se ho vinto
    if controlla_vittoria; then
        printf "${YELLOW}Pulizia dei container in corso...${RESET}\n"
        docker rm -f "$CONTADINO" "$LUPO" "$PECORA" "$CAVOLO" > /dev/null 2>&1 || true
        exit 0 # Chiude lo script con successo
    fi
}

# funzione per disegnare graficamente lo stato del fiume
disegna_fiume() {
    # Recupera i nomi dei container sulle due reti
    local elementi_sinistra=$(docker network inspect "$SPONDA_1" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)
    local elementi_destra=$(docker network inspect "$SPONDA_2" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)

    printf "\n${BLUE}=================================================${RESET}\n"
    printf "${YELLOW}               STATO DEL FIUME                   ${RESET}\n"
    printf "${BLUE}=================================================${RESET}\n"
    printf "%-18s ${BLUE}~~~~~~~~~${RESET} %-18s\n" "SINISTRA" "DESTRA"
    printf "${BLUE}-------------------------------------------------${RESET}\n"

    # Array con tutti gli attori
    local attori=("$CONTADINO" "$LUPO" "$PECORA" "$CAVOLO")

    for attore in "${attori[@]}"; do
        local str_sinistra=" "
        local str_destra=" "

        # verifica se l'attore è a sinistra
        if echo "$elementi_sinistra" | grep -qw "$attore"; then
            str_sinistra="$attore"
        fi

        # verifica se l'attore è a destra
        if echo "$elementi_destra" | grep -qw "$attore"; then
            str_destra="$attore"
        fi

        # stampa la riga per l'attore corrente
        printf "%-18s ${BLUE}~~~~~~~~~${RESET} %-18s\n" "$str_sinistra" "$str_destra"
    done
    printf "${BLUE}=================================================${RESET}\n\n"
}

# creazione reti docker 
# controllo se la rete esiste già nell'elenco di docker
if [ -z "$(docker network ls -q -f name=^sponda_sinistra$)" ]; then
    docker network create "$SPONDA_1" 2> /dev/null || true
fi
if [ -z "$(docker network ls -q -f name=^sponda_destra$)" ]; then
    docker network create "$SPONDA_2" 2> /dev/null || true
fi

# elimino cotainer precedenti con lo stesso nome dei container che devo creare
docker rm -f "$CONTADINO" "$LUPO" "$PECORA" "$CAVOLO" > /dev/null 2>&1 || true

# avvio tutti i container: tutti gli attori sono sulla sponda sinistra
# conrainer alpine è un container molto leggero; lo metto in sleep infinity per farlo girare all'infinito 
docker run -d --name "$CONTADINO" --network "$SPONDA_1" alpine sleep infinity
docker run -d --name "$LUPO"      --network "$SPONDA_1" alpine sleep infinity
docker run -d --name "$PECORA"    --network "$SPONDA_1" alpine sleep infinity
docker run -d --name "$CAVOLO"    --network "$SPONDA_1" alpine sleep infinity

# mostro le regole di gioco
mostra_regole
read -p "Premi [INVIO] per iniziare..."

# game loop
while true; do
    clear
    disegna_fiume
    read -p "$(printf "${BLUE}<%s>${RESET}: " "$SPONDA_CORRENTE")" input
    if [[ "$input" == "exit" ]]; then
        break
    fi
    game_action "$input"

    sleep 1
done

printf "${RED}\n=================== GAME OVER ===================${RESET}\n"
printf "${RED}Non hai aiutato il contadino a finire il suo lavoro${RESET}\n" "$sponda_da_controllare"
printf "${RED}La pecora ha mangiato il cavolo poi è stata mangiata dal lupo.${RESET}\n"
printf "${RED}=================================================${RESET}\n\n"