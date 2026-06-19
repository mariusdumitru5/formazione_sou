# Evita blocchi interattivi con GRUB
export DEBIAN_FRONTEND=noninteractive
apt-mark hold grub-pc grub-pc-bin grub2-common grub-imagebuilder 2>/dev/null

# update and upgrade del sistema 
sudo apt-get update && sudo apt-get upgrade -y 

# install di apache2 per il web server
sudo apt-get install -y apache2 ufw

# creazione home page
cat <<EOF >  /var/www/html/index.html
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Benvenuto sulla Piattaforma</title>
    <style>
        /* Reset e stili di base identici alle altre pagine */
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body, html {
            width: 100%;
            height: 100%;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: #f3f4f6; /* Grigio chiaro moderno */
            display: flex;
            flex-direction: column;
        }

        /* Barra di navigazione superiore */
        header {
            background-color: #ffffff;
            padding: 20px 40px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.02);
        }

        .logo {
            font-size: 20px;
            font-weight: 700;
            color: #2563eb; /* Blu moderno principale */
        }

        nav a {
            text-decoration: none;
            color: #4b5563;
            margin-left: 24px;
            font-size: 15px;
            font-weight: 500;
            transition: color 0.2s;
        }

        nav a:hover {
            color: #2563eb;
        }

        /* Contenitore centrale della Hero */
        main {
            flex: 1;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }

        .hero-container {
            background-color: #ffffff;
            padding: 50px 40px;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
            width: 100%;
            max-width: 550px;
            text-align: center;
        }

        h1 {
            font-size: 28px;
            color: #1f2937;
            margin-bottom: 16px;
            font-weight: 700;
        }

        p {
            color: #6b7280;
            font-size: 15px;
            line-height: 1.6;
            margin-bottom: 32px;
        }

        /* Gruppo pulsanti di azione (CTA) */
        .cta-group {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .btn {
            display: block;
            width: 100%;
            padding: 12px;
            border-radius: 6px;
            font-size: 16px;
            font-weight: 600;
            text-decoration: none;
            text-align: center;
            transition: background-color 0.2s, transform 0.1s;
        }

        .btn:active {
            transform: scale(0.99);
        }

        .btn-primary {
            background-color: #2563eb;
            color: #ffffff;
        }

        .btn-primary:hover {
            background-color: #1d4ed8;
        }

        .btn-outline {
            background-color: transparent;
            color: #2563eb;
            border: 1px solid #d1d5db;
        }

        .btn-outline:hover {
            background-color: #f9fafb;
            border-color: #caf0f8;
        }

        /* Testo informativo per il debug dei nodi (utile per il Load Balancing) */
        .footer-info {
            margin-top: 32px;
            font-size: 13px;
            color: #9ca3af;
            font-family: monospace;
        }
    </style>
</head>
<body>

    <header>
        <div class="logo">PiattaformaWeb</div>
        <nav>
            <a href="/login">Accedi</a>
            <a href="/accounts">Registrati</a>
        </nav>
    </header>

    <main>
        <div class="hero-container">
            <h1>Benvenuto nel Sistema</h1>
            <p>Accedi alla tua area riservata per gestire i tuoi servizi oppure crea un nuovo profilo utente in pochi passaggi.</p>
            
            <div class="cta-group">
                <a href="/login" class="btn btn-primary">Accedi al Profilo</a>
                <a href="/accounts" class="btn btn-outline">Crea un Account</a>
            </div>

            <!-- Il provisioning cambierà automaticamente questa etichetta con l'hostname della macchina -->
            <div class="footer-info">Distribuito da: SERVER-HOME</div>
        </div>
    </main>

</body>
</html>

EOF

# controllo dell'hostname per creare la cartella e il file corretti
if [[ "$HOSTNAME" == "backend-srv-1" ]]; then

    # creazione cartella per il nuovi path 
    sudo mkdir -p /var/www/html/accounts

    # scrivo  il file index.html 
    cat <<EOF > /var/www/html/accounts/index.html
    <!DOCTYPE html>
    <html lang="it">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Registrazione Nuovo Utente</title>
        <style>
            /* Reset e stili di base per centrare il modulo */
            * {
                box-sizing: border-box;
                margin: 0;
                padding: 0;
            }

            body, html {
                width: 100%;
                height: 100%;
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                background-color: #f3f4f6; /* Grigio chiaro moderno */
                display: flex;
                justify-content: center;
                align-items: center;
            }

            /* Contenitore del modulo di registrazione */
            .register-container {
                background-color: #ffffff;
                padding: 40px;
                border-radius: 12px;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
                width: 100%;
                max-width: 400px;
            }

            h2 {
                margin-bottom: 24px;
                color: #1f2937;
                text-align: center;
                font-size: 24px;
            }

            /* Gruppi di input */
            .form-group {
                margin-bottom: 20px;
            }

            label {
                display: block;
                margin-bottom: 8px;
                color: #4b5563;
                font-size: 14px;
                font-weight: 500;
            }

            input {
                width: 100%;
                padding: 12px;
                border: 1px solid #d1d5db;
                border-radius: 6px;
                font-size: 15px;
                transition: border-color 0.2s, box-shadow 0.2s;
                outline: none;
            }

            /* Effetto quando l'utente clicca sui campi */
            input:focus {
                border-color: #2563eb; /* Blu moderno */
                box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
            }

            /* Pulsante di invio */
            .btn-submit {
                width: 100%;
                padding: 12px;
                background-color: #2563eb;
                color: #ffffff;
                border: none;
                border-radius: 6px;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                transition: background-color 0.2s;
                margin-top: 10px;
            }

            .btn-submit:hover {
                background-color: #1d4ed8;
            }

            /* Testo in fondo per il login */
            .footer-text {
                text-align: center;
                margin-top: 20px;
                font-size: 14px;
                color: #6b7280;
            }

            .footer-text a {
                color: #2563eb;
                text-decoration: none;
            }

            .footer-text a:hover {
                text-decoration: underline;
            }
        </style>
    </head>
    <body>

        <div class="register-container">
            <h2>Crea un account</h2>
            
            <!-- Il form punta a se stesso o a un file di backend in futuro -->
            <form action="#" method="POST">
                
                <div class="form-group">
                    <label for="username">Nome Utente</label>
                    <input type="text" id="username" name="username" placeholder="Inserisci il tuo username" required autocomplete="username">
                </div>

                <div class="form-group">
                    <label for="email">Indirizzo Email</label>
                    <input type="email" id="email" name="email" placeholder="esempio@email.com" required autocomplete="email">
                </div>

                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" placeholder="Scegli una password sicura" required autocomplete="new-password">
                </div>

                <button type="submit" class="btn-submit">Registrati</button>
            </form>

            <p class="footer-text">
                Hai già un account? <a href="#">Accedi qui</a>
            </p>
        </div>

    </body>
    </html>
EOF
elif [[ "$HOSTNAME" == "backend-srv-2" ]]; then

    sudo mkdir -p /var/www/html/login

    cat <<EOF > /var/www/html/login/index.html
    <!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Accedi al Sistema</title>
    <style>
        /* Reset e stili di base per centrare il modulo */
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body, html {
            width: 100%;
            height: 100%;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: #f3f4f6; /* Grigio chiaro moderno identico alla registrazione */
            display: flex;
            justify-content: center;
            align-items: center;
        }

        /* Contenitore del modulo di login */
        .login-container {
            background-color: #ffffff;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
            width: 100%;
            max-width: 400px;
        }

        h2 {
            margin-bottom: 24px;
            color: #1f2937;
            text-align: center;
            font-size: 24px;
        }

        /* Gruppi di input */
        .form-group {
            margin-bottom: 20px;
        }

        label {
            display: block;
            margin-bottom: 8px;
            color: #4b5563;
            font-size: 14px;
            font-weight: 500;
        }

        input {
            width: 100%;
            padding: 12px;
            border: 1px solid #d1d5db;
            border-radius: 6px;
            font-size: 15px;
            transition: border-color 0.2s, box-shadow 0.2s;
            outline: none;
        }

        /* Effetto quando l'utente clicca sui campi */
        input:focus {
            border-color: #2563eb; /* Blu moderno identico alla registrazione */
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
        }

        /* Opzioni extra tipiche del login (Ricordami / Password dimenticata) */
        .form-options {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
            font-size: 14px;
        }

        .remember-me {
            display: flex;
            align-items: center;
            gap: 8px;
            color: #4b5563;
            cursor: pointer;
        }

        .remember-me input {
            width: auto;
            cursor: pointer;
        }

        .forgot-password {
            color: #2563eb;
            text-decoration: none;
        }

        .forgot-password:hover {
            text-decoration: underline;
        }

        /* Pulsante di invio */
        .btn-submit {
            width: 100%;
            padding: 12px;
            background-color: #2563eb;
            color: #ffffff;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: background-color 0.2s;
            margin-top: 10px;
        }

        .btn-submit:hover {
            background-color: #1d4ed8;
        }

        /* Testo in fondo per passare alla registrazione */
        .footer-text {
            text-align: center;
            margin-top: 20px;
            font-size: 14px;
            color: #6b7280;
        }

        .footer-text a {
            color: #2563eb;
            text-decoration: none;
        }

        .footer-text a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>

    <div class="login-container">
        <h2>Bentornato</h2>
        
        <!-- Il form punta a se stesso o a un file di backend in futuro -->
        <form action="#" method="POST">
            
            <div class="form-group">
                <label for="email">Indirizzo Email</label>
                <input type="email" id="email" name="email" placeholder="esempio@email.com" required autocomplete="email">
            </div>

            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" placeholder="Inserisci la tua password" required autocomplete="current-password">
            </div>

            <div class="form-options">
                <label class="remember-me">
                    <input type="checkbox" name="remember"> Ricordami
                </label>
                <a href="#" class="forgot-password">Password dimenticata?</a>
            </div>

            <button type="submit" class="btn-submit">Accedi</button>
        </form>

        <p class="footer-text">
            Non hai ancora un account? <a href="/accounts">Registrati qui</a>
        </p>
    </div>

</body>
</html>
EOF
else
    echo "Hostname ($HOSTNAME) sconosciuto. Nessuna cartella specifica creata."
fi

# abilito e riavvio apache per sicurezza
systemctl enable apache2
systemctl restart apache2

### configurazione firewall per bloccare tutti i client sulla porta 80 che non siano il server reverse proxy
# reset delle regole e imposta il blocco di default in ingresso
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# lascio funzionare ssh 
sudo ufw allow 22/tcp

# consento solo al server reverse proxy di usare la porta 80
sudo ufw allow from 192.168.1.10 to any port 80 proto tcp

# attivo il firewall
sudo ufw --force enable