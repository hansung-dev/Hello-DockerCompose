"""
Example use of MySql related operators.
"""

from airflow import DAG
from airflow.providers.mysql.operators.mysql import MySqlOperator
from airflow.utils.dates import days_ago

default_args = {
    'owner': 'airflow',
}

dag = DAG(
    'example_mysql',
    default_args=default_args,
    start_date=days_ago(2),
    tags=['example'],
)

# [START howto_operator_mysql]

drop_table_mysql_task = MySqlOperator(
    task_id='create_table_mysql', mysql_conn_id='mysql_conn_id', sql=r"""DROP TABLE table_name;""", dag=dag
)

# [END howto_operator_mysql]

# [START howto_operator_mysql_external_file]

mysql_task = MySqlOperator(
    task_id='create_table_mysql_external_file',
    mysql_conn_id='mysql_conn_id',
    sql='/scripts/drop_table.sql',
    dag=dag,
)

# [END howto_operator_mysql_external_file]

drop_table_mysql_task >> mysql_task
