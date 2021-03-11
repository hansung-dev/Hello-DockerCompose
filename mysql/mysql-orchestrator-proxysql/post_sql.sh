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

## For ProxySQL
echo "ProxySQL"
${EXEC_MASTER} "CREATE DATABASE testdb DEFAULT CHARACTER SET=utf8" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "CREATE USER appuser@'%' IDENTIFIED BY 'apppass'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "GRANT SELECT, INSERT, UPDATE, DELETE ON testdb.* TO appuser@'%'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "CREATE USER monitor@'%' IDENTIFIED BY 'monitor'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "GRANT REPLICATION CLIENT ON *.* TO monitor@'%'" 2>&1 | grep -v "Using a password"

echo "ProxySQL #2"
EXEC_PROXY="mysql -h127.0.0.1 -P6032 -uradmin -pradmin -e "

${EXEC_PROXY} "INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (10, 'mysql-01', 3306)" 2>&1 | grep -v "Using a password"
${EXEC_PROXY} "INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (20, 'mysql-01', 3306)" 2>&1 | grep -v "Using a password"
${EXEC_PROXY} "INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (20, 'mysql-02', 3306)" 2>&1 | grep -v "Using a password"
${EXEC_PROXY} "INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (20, 'mysql-03', 3306)" 2>&1 | grep -v "Using a password"
${EXEC_PROXY} "INSERT INTO mysql_replication_hostgroups VALUES (10,20,'read_only','')" 2>&1 | grep -v "Using a password"
${EXEC_PROXY} "LOAD MYSQL SERVERS TO RUNTIME" 2>&1 | grep -v "Using a password"
${EXEC_PROXY} "SAVE MYSQL SERVERS TO DISK" 2>&1 | grep -v "Using a password"

${EXEC_PROXY} "INSERT INTO mysql_users(username,password,default_hostgroup,transaction_persistent)
               VALUES ('appuser','apppass',10,0)" 2>&1 | grep -v "Using a password"
${EXEC_PROXY} "LOAD MYSQL USERS TO RUNTIME" 2>&1 | grep -v "Using a password"
${EXEC_PROXY} "SAVE MYSQL USERS TO DISK" 2>&1 | grep -v "Using a password"

${EXEC_PROXY} "INSERT INTO mysql_query_rules(rule_id,active,match_pattern,destination_hostgroup)
               VALUES (1,1,'^SELECT.*FOR UPDATE$',10)" 2>&1 | grep -v "Using a password"
${EXEC_PROXY} "INSERT INTO mysql_query_rules(rule_id,active,match_pattern,destination_hostgroup)
               VALUES (2,1,'^SELECT',20)" 2>&1 | grep -v "Using a password"
${EXEC_PROXY} "LOAD MYSQL QUERY RULES TO RUNTIME" 2>&1 | grep -v "Using a password"
${EXEC_PROXY} "SAVE MYSQL QUERY RULES TO DISK" 2>&1 | grep -v "Using a password"
