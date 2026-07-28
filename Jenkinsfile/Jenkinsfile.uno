def getDay() {
    def day = new Date().format("u", TimeZone.getTimeZone('Europe/Rome')) as Integer
    return day
}

pipeline {
    agent { label 'rocky-linux-worker' }

    stages {
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
    }
}
