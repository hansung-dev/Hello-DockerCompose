MASTER_NODE='mysql-01'
SLAVE01_NODE='mysql-02'
SLAVE02_NODE='mysql-03'

EXEC_MASTER="docker exec ${MASTER_NODE} mysql -uroot -proot -N -e "
EXEC_SLAVE01="docker exec ${SLAVE01_NODE} mysql -uroot -proot -e "
EXEC_SLAVE02="docker exec ${SLAVE02_NODE} mysql -uroot -proot -e "

## For Replication
echo "Replication"
${EXEC_MASTER} "CREATE USER 'repl'@'%' IDENTIFIED BY 'repl'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'" 2>&1 | grep -v "Using a password"

${EXEC_SLAVE01} "reset master" 2>&1 | grep -v "Using a password"
${EXEC_SLAVE01} "CHANGE MASTER TO MASTER_HOST='${MASTER_NODE}', \
MASTER_USER='repl', MASTER_PASSWORD='repl', \
MASTER_AUTO_POSITION=1" 2>&1 | grep -v "Using a password"
${EXEC_SLAVE01} "START SLAVE" 2>&1 | grep -v "Using a password"

${EXEC_SLAVE02} "reset master" 2>&1 | grep -v "Using a password"
${EXEC_SLAVE02} "CHANGE MASTER TO MASTER_HOST='${MASTER_NODE}', \
MASTER_USER='repl', MASTER_PASSWORD='repl', \
MASTER_AUTO_POSITION=1" 2>&1 | grep -v "Using a password"
${EXEC_SLAVE02} "START SLAVE" 2>&1 | grep -v "Using a password"

## For Orchestrator
echo "Orchestrator"
${EXEC_MASTER} "CREATE USER orc_client_user@'%' IDENTIFIED BY 'orc_client_password'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "GRANT SUPER, PROCESS, REPLICATION SLAVE, RELOAD ON *.* TO orc_client_user@'%'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "GRANT SELECT ON mysql.slave_master_info TO orc_client_user@'%'" 2>&1 | grep -v "Using a password"
