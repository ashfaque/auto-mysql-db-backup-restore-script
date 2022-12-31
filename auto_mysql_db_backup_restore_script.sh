#!/bin/sh

# * ######################## * #
# * Author : Ashfaque Alam   * #
# * Date : December 11, 2022 * #
# * ######################## * #



# ! Give executable permission to this file:
# ? sudo chmod +x auto_mysql_db_backup_restore_script.sh
# ? chmod 755 auto_mysql_db_backup_restore_script.sh



# ? A shell script which is able run with a crontab.
# ? Can take a dump of the entire MySQL database from remote server to local server
# ? Then restore in a new database in current server.
# ? Also, will delete databases older than ${expiry_days}.

# ? Runs every day at 2:30AM IST
# 0 21 * * * /usr/bin/sh /home/sftprod/ssil_db_bkup_restore_prod/db_bkup_restore_script.sh >> /home/sftprod/ssil_db_bkup_restore_prod/db_bkup_restore_script.log 2>&1


#####################################
####### VARIABLES DECLARATION #######
#####################################

local_mysql_username="admin"
local_mysql_password="admin"
local_mysql_host="localhost"
local_mysql_port="3306"

ssh_private_key_path="/home/ashfaque/.ssh/centosvm_ed25519"    # ? EOF find the commands to create ssh key pairs.
remote_server_username="v3"
remote_server_host_ip="192.168.0.100"
remote_server_ssh_port="2222"

remote_mysql_username="remoteuser"
remote_mysql_password="123456"
remote_mysql_port="33060"

## If using local time on server.
# today_date=$(date +'%d_%m_%Y_%H_%M_%S')    # eg., O/P:- 25_06_2022_23_32_55
# backup_date=$(date +'%d-%m-%Y %H:%M:%S')

## If using UTC server time and wanted to convert to another timezone.
today_date=$(date -d "+ 330 minutes" +'%d_%m_%Y_%H_%M_%S')
backup_date=$(date -d "+ 330 minutes" +'%d-%m-%Y %H:%M:%S')


from_db_name="dump_db"
to_db_name="${from_db_name}_${today_date}"


current_dir=${PWD}
sqlite_db_path=${current_dir}"/${from_db_name}_backup_restore_records.sqlite3"
log_table_name="logs"    # id INTEGER PRIMARY KEY AUTOINCREMENT, db_name TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')), expiry_time TEXT NOT NULL DEFAULT (datetime('now', '+${expiry_days}', 'localtime')), is_dropped INTEGER(1) NOT NULL DEFAULT 0
expiry_days="15 days"    # ? Only change the integer part, leave the `days` string as it is.





################################################
####### No need to change anything below #######
################################################

echo "##### STARTING DB backup & restore operations : ${backup_date} #####"

# ? Function to check the last command ran is successful. If not then will throw the user defined msg and stops the script execution then and there. 
#  Doesn't work with ||, and conditional statements.
exit_on_error() {    # Call it just below any command: exit_on_error $? "Error message"
    exit_code=$1
    error_msg=$2
    if [ $exit_code -ne 0 ]; then
        # >&2 echo "\"${error_msg}\" ---> $(date +'%d-%m-%Y %H:%M:%S')"    # If using local time on server
        >&2 echo "\"${error_msg}\" ---> $(date -d "+ 330 minutes" +'%d-%m-%Y %H:%M:%S')"    # If using UTC on server and want date in IST.
        exit $exit_code
    fi
}


type mysql >/dev/null 2>&1
exit_on_error $? "MySQL is not installed"

type sqlite3 >/dev/null 2>&1
exit_on_error $? "SQLite3 is not installed"

type ssh >/dev/null 2>&1
exit_on_error $? "openssh-server is not installed"




# ? If sqlite3 db file doesn't exists:
# https://stackoverflow.com/a/26127039    strftime() default value and retrieving with -> datetime(created_at, 'unixepoch', 'localtime') as localtime
# https://www.sqlite.org/lang_datefunc.html    https://www.sqlite.org/datatype3.html
# [ ! -f "${sqlite_db_path}" ] && sqlite3 ${sqlite_db_path} "CREATE TABLE IF NOT EXISTS logs (id INTEGER PRIMARY KEY AUTOINCREMENT, db_name TEXT NOT NULL, created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')), expiry_time INTEGER NOT NULL, is_dropped INTEGER(1) NOT NULL);"
[ ! -f "${sqlite_db_path}" ] && sqlite3 ${sqlite_db_path} "CREATE TABLE IF NOT EXISTS ${log_table_name} (id INTEGER PRIMARY KEY AUTOINCREMENT, db_name TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')), expiry_time TEXT NOT NULL DEFAULT (datetime('now', '+${expiry_days}', 'localtime')), is_dropped INTEGER(1) NOT NULL DEFAULT 0);"


# ? NB: While creating the database in MySQL for backup restoration just to insert db_name.
# ? and while dropping db older than ${expiry_days} update is_dropped to 1 after dropping, rest of the things are auto inserted by SQlite3.



# ? Create database in which our dump will be restored later.
mysql -u${local_mysql_username} -p${local_mysql_password} -h${local_mysql_host} -P${local_mysql_port} -e "CREATE DATABASE IF NOT EXISTS ${to_db_name};"
exit_on_error $? "Not able to create database with name ${to_db_name} in local MySQL server"
# or,
# echo "CREATE DATABASE IF NOT EXISTS ${to_db_name};" | mysql -u${local_mysql_username} -p${local_mysql_password} -h${local_mysql_host} -P${local_mysql_port}
# exit_on_error $? "Not able to create database with name ${to_db_name} in local MySQL server"



# ? Saving newly created empty database name to sqlite3 for log.
sqlite3 ${sqlite_db_path} "INSERT INTO ${log_table_name} (db_name) VALUES ('${to_db_name}');"
exit_on_error $? "sqlite3 is not able to insert in ${log_table_name} the value: ${to_db_name}"



# ? Dumping .sql file from remote server to current server via., ssh.
ssh -i "$ssh_private_key_path" "$remote_server_username"@"$remote_server_host_ip" -p "$remote_server_ssh_port" "mysqldump -u${remote_mysql_username} -p${remote_mysql_password} -P${remote_mysql_port} ${from_db_name}" > "${current_dir}/${to_db_name}.sql"
exit_on_error $? "Unable to dump .sql file over ssh from remote server"


# ? Restoring the .sql file to our generated database.
mysql -u${local_mysql_username} -p${local_mysql_password} -h${local_mysql_host} -P${local_mysql_port} ${to_db_name} < "${current_dir}/${to_db_name}.sql"
exit_on_error $? "Unable to restore .sql file in local database ${to_db_name}"



# ? Deleting the .sql file after restoring in our MySQL database.
rm -rf "${current_dir}/${to_db_name}.sql"
exit_on_error $? "Unable to delete .sql file located at: ${current_dir}/${to_db_name}.sql"



# ? Fetching id and db_name which are older than ${expiry_days} and are not dropped yet.
sqlite_select_query="SELECT id, db_name FROM ${log_table_name} WHERE expiry_time < datetime('now', 'localtime') AND db_name LIKE '${from_db_name}%' AND is_dropped = 0;"
select_query_data=$(sqlite3 ${sqlite_db_path} "${sqlite_select_query}")
exit_on_error $? "Unable to fetch databases name from sqlite3 table ${log_table_name} which are older than ${expiry_days} are are not dropped yet."


# ? Picking each db_name and 
if test ! -z "${select_query_data}"    # If `select_query_data` is not null
then
    for each_drop_data in $select_query_data
    do
        oIFS=$IFS

        IFS='|'

        set -- $each_drop_data    # Works with Bourne(sh) Shell.
        each_drop_id=$1
        each_drop_db_name=$2

        #or,
        #* read -a each_drop_data_array <<< $each_drop_data    # * Need to use #!/bin/bash instead of sh for this line only.
        # or, 
        # each_drop_data_array=(`echo $each_drop_data | tr '|' ' '`)    # * Need to use #!/bin/bash instead of sh for this line only.

        #* each_drop_id=${each_drop_data_array[0]}
        #* each_drop_db_name=${each_drop_data_array[1]}

        # echo $each_drop_id
        # echo $each_drop_db_name


        # ? Dropping database one by one as they are older than ${expiry_days}.
        mysql -u${local_mysql_username} -p${local_mysql_password} -h${local_mysql_host} -P${local_mysql_port} -e "DROP DATABASE IF EXISTS ${each_drop_db_name};"
        exit_on_error $? "Not able to drop database with name ${each_drop_db_name} in local MySQL server"


        # ? Updating is_dropped=1 in SQlite3 database.
        sqlite_update_query="UPDATE ${log_table_name} SET is_dropped=1 WHERE id=${each_drop_id};"
        sqlite3 ${sqlite_db_path} "${sqlite_update_query}"
        exit_on_error $? "sqlite3 is not able to update is_dropped flag in ${log_table_name} table"

        IFS=$oIFS
    done
fi



echo "##### Successfully performed DB backup & restore operations : ${backup_date} #####"

#   ##################################################### END ######################################################










# ---------------------------
# Generation of ssh key pairs:-
# ---------------------------

# sudo apt-get install openssh-server
# sudo systemctl enable ssh
# sudo systemctl start ssh
# ssh <username>@<ip addr> -p <port>

# In host PC:-
# ----------
# ~$ ssh-keygen -t rsa    or,    ssh-keygen -t ed25519

# ~$ ssh-copy-id -i ~/.ssh/id_rsa.pub <username>@<ip addr>/home/<username>/.ssh/authorized_keys
# or,
# ~$ type $env:USERPROFILE\.ssh\id_rsa.pub | ssh <username>@<ip addr> -p <port> "cat >> .ssh/authorized_keys"
# or,
# ~$ echo ssh-ed25519 lksdjkdfHKfg9Khykdfgkj785kljdfjgKKee0ojufUrfq+hsdhfA5lGsbT+tD/ Ashfaque@PC > authorized_keys   # in Server

# ~$ ssh -i ~/.ssh/id_rsa <username>@<ip addr> -p <port>

# Edit ~/.ssh/config file:
#     Host <servername>
#     HostName <remote ip>
#     User <remote username>
#     Port <remote port>
#     IdentityFile ~/.ssh/private_key_currently_generated

# ~$ ssh <username>@<servername>
# in ~/.bashrc alias centos='ssh <username>@<servername>'





# ----------------------------------
# To convert private key to pem file:-
# ----------------------------------
# Open puttygen, 
# goto Conversion tab and import key,
# choose RSA, DSA, ECDSA, EdDSA, SSH-1(RSA)
# then you can either save `public or private key` by clicking on that button.
# Or you can go to : Conversions tab and click on `Export OpenSSH key (Force New Format)`
# and save it as .pem file.


# To extract compatible public key from a private key use: `ssh-keygen -f private.pem -y > private.pub`





# --------------------
# MariaDB installation:-
# --------------------
# sudo apt update
# sudo apt install mariadb-server
# systemctl status mariadb
# sudo mysql_secure_installation 
# mysql -u root -p

# SELECT VERSION();
# CREATE USER remoteuser@localhost IDENTIFIED BY '123456';
# CREATE DATABASE dump_db;
# GRANT ALL ON dump_db.* TO remoteuser@'%' IDENTIFIED BY '123456' WITH GRANT OPTION;
# or,
# CREATE USER admin@localhost IDENTIFIED BY 'admin';
# GRANT ALL ON *.* TO admin@'localhost' IDENTIFIED BY 'admin' WITH GRANT OPTION;
# FLUSH PRIVILEGES;
# mysql -u admin -p
# SHOW DATABASES;


# nano /etc/mysql/my.cnf    # If using debian based distributions.
#    Add these:
#    [mysqld]
#    bind-address = 0.0.0.0

# vi /etc/my.cnf.d/mariadb-server.cnf -> uncomment bind-address = 0.0.0.0    # CentOS 8

# netstat -ant | grep 3306
# ps -ef | grep -i mysql

# firewall-cmd --add-port=3306/tcp
# firewall-cmd --permanent --add-port=3306/tcp
# systemctl restart mariadb



# $ sudo apt-get install sqlite3







# ----------
# Archives:-
# ----------

### Split a variable using positional argument in Bourne(sh) Shell ###
# ------------------------------------------------------
# var="foo|bar|baz"

# oIFS=$IFS

# IFS='|'
# set -- $var
# echo $1 $2 $3    # $var is now split into $1, $2, etc.

# IFS=$oIFS
# -------------------------------------------------------

# ssh root@ipaddress "mysqldump -u dbuser -p dbname | gzip -9" > dblocal.sql.gz
# ssh -l root ipaddress "mysqldump -u dbuser -p dbname | gzip -9" > dblocal.sql.gz
# ssh -i key.pem root@ipaddress "mysqldump -u dbuser -p dbname | gzip -9" > dblocal.sql.gz

# Debian(admin:admin) & CentOS8VM(2222, 33060 ports) MariaDB remoteuser:123456
# ssh -i /home/ashfaque/.ssh/centosvm_ed25519 v3@192.168.0.100 -p 2222
# mysql -uremoteuser -p123456 -h192.168.0.100 -P33060
# ssh -i /home/ashfaque/.ssh/centosvm_ed25519 v3@192.168.0.100 -p 2222 "mysqldump -uremoteuser -p123456 -P33060 dump_db" > dump_db.sql

# working_dir="/home/$LOGNAME/Documents/test"    # $LOGNAME or, $(id -n -u) or, $(whoami) can be used in place of $USER if it doesn't work.
