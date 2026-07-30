<h1 align="center">Jenkins setup</h1>

Per fare il setup di Jenkins è stato utilizzato `Ansible`. In particolare, per questo setup sono state create due macchine virtuali, una per il `master`(che contiene il container docker del Jenkins Master) e una per `l'agent`(che si trova a sua volta in un container docker). 

Per sfruttare Ansible al massimo sono stati creati `tre ruoli`: 

- `install_docker`: si occupa di installare docker su entrambe le vm(che hanno Rocky Linux 9).
- `jenkins_setup`: si occupa del setup del container docker che contiene il Jenkins master. 
- `worker_setup`: si occupa del setup del container che fa da worker, cioè l'agent. 