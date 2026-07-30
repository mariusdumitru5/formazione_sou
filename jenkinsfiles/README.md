<h1 align="center"> Jenkins</h1>

### Esercizio 1

Scrivere una pipeline Jenkins che esegua una build solo dal lunedi al venerdì e scriva un messaggio di warning il sabato e la domenica.

##### Soluzione(Jenkinsfile.uno)

Per prendere il giorno corrente ho scritto una piccola funzione che sfrutta l'oggetto `Date` del linguaggio `Groovy`.

```groovy
def getDay() {
    def day = new Date().format("u", TimeZone.getTimeZone('Europe/Rome')) as Integer
    return day
}
```

In questo caso è stato utilizzato il metodo `format` con il parametro `u`(per trasformare il giorno della settimana in un numero da 1 a 7) e il parametro `TimeZone`(per passare la time zone giusta). 

###### Nota: E' importante notare l'utilizzo di ` as Integer`. Questo trasforma la stringa che rappresenta il giorno della settimana in un intero(da "5" a 5).

La pipeline è fatta da due stage. 
Uno stage iniziale nel quale viene verificato il giorno della settimana: 

```groovy
stage('Controllo giorno settimana') {
    steps {
        script {
            def oggi = getDay()
            if (oggi == 6 || oggi == 7) {
                println "Warning: Nel weekend non si avviano le pipeline"
            }
        }   
    }
}
```

Se il giorno è 6 o 7 (sabato o domenica) viene stampato il messaggio di warning. 

Il secondo stage invece attraverso l'utilizzo della direttiva `when` e `expression` viene stabilito se lo stage di `build` verrà eseguito o no:

```groovy
 stage('Build app') {
            
    when {
        expression {
            def oggi = getDay()
            return oggi >= 1 && oggi <= 5
        }
    }
    steps {
        echo 'Sto facendo la build'
    }
}
```

Se il giorno non è compreso tra lunedì e venerdì, allora non verrà eseguito lo step della build. 


### Esercizio 2

Scrivere una pipeline Jenkins dichiarativa che accetti il parametro `ENVIRONMENT` e che abbia due stages `PRODUCTION` e `DEVELOPMENT` che vengano eseguiti in base al valore del parametro. E' sufficiente fare una echo a video del valore del parametro.

##### Soluzione(Jenkinsfile.due)

Per la gestione del parametri ho usato la direttiva `parameters` che permette di definire parametri globali per la pipeline.
Dato che ho due scelte(`PRODUCTION` e `DEVELOPMENT`) ho usato `choice`. 

```groovy
parameters {
    choice (
       name: 'ENVIRONMENT', 
       choices: ['DEVELOPMENT', 'PRODUCTION'], 
       description: 'Seleziona l\'ambiente per la pipeline'
    )
}
```

Per quanto riguarda gli stage, sono due ed entrambi utilizzano `when`, in questo modo si escludono a vicenda:

```groovy
stage('PRODUCTION') {
    when {
         environment name: 'ENVIRONMENT', value: 'PRODUCTION'
    }
    steps {
        echo "Sono nell'ambiente di Produzione"
    }
}
stage('DEVELOPMENT') {
   when {
         environment name: 'ENVIRONMENT', value: 'DEVELOPMENT'
    }
    steps {
        echo "Sono nell'ambiente di DEVELOPMENT"
    }
```