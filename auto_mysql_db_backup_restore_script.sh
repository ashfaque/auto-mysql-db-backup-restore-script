#!/bin/sh

# * ######################## * #
# * Author : Ashfaque Alam   * #
# * Date : December 11, 2022 * #
# * ######################## * #

# ! Give executable permission : sudo chmod +x auto_mysql_db_dump_restore.sh

# ? A shell script to which can be run with a crontab. Can take a dump of the entire MySQL database from remote server, then restore in a new database.
# ? If ran will 1st delete databases older than 15 days.



# ? VARIABLES DECLARATION :-
# working_dir="/home/$LOGNAME/Documents/test"    # $LOGNAME or, $(id -n -u) or, $(whoami) can be used in place of $USER if it doesn't work.
ssh_private_key_path="/home/ashfaque/.ssh/centosvm_ed25519"
server_username="v3"
server_host_ip="192.168.0.100"
server_ssh_port="2222"

mysql_username="remoteuser"
mysql_password="123456"
mysql_port="33060"

today_date=$(date +'%d_%m_%Y_%H_%M_%S')    # eg., O/P:- 25_06_2022_23_32_55
backup_date=$(date +'%d-%m-%Y %H:%M:%S')

ssh -i "$ssh_private_key_path" "$server_username"@"$server_host_ip" -p "$server_ssh_port" "mysqldump -u"$mysql_username" -p"$mysql_password" -P"$mysql_port" dump_db" > dump_db.sql




echo "Successfully created DB backup at $backup_date."








# ? https://github.com/ashfaque/auto-mysql-db-backup-script/blob/main/auto_mysql_db_backup.sh



# ssh root@ipaddress "mysqldump -u dbuser -p dbname | gzip -9" > dblocal.sql.gz 
# ssh -l root ipaddress "mysqldump -u dbuser -p dbname | gzip -9" > dblocal.sql.gz
# ssh -i key.pem root@ipaddress "mysqldump -u dbuser -p dbname | gzip -9" > dblocal.sql.gz

# from debian try to connect to centos vm
# dump_db > dump_table,,, py/sh file
# over ssh mysql dump .sql file from centos vm to debian pc
# create new db with todays date in debian pc,,,save in a table the name and creation date
# restore dump from .sql to that db
# if error stop exec .sh
# delete .sql file
# drop db older than 15 days (saving their name and date in a db), just update is_deleted=True,,,after dropping,,,,or have expected_drop_time....on sqlite???

# or, using python loop in each table and dump what ever+


# ? Debian & CentOS8VM(2222, 33060 ports) MariaDB remoteuser:123456

# ssh -i /home/ashfaque/.ssh/centosvm_ed25519 v3@192.168.0.100 -p 2222
# mysql -uremoteuser -p123456 -h192.168.0.100 -P33060
# ssh -i /home/ashfaque/.ssh/centosvm_ed25519 v3@192.168.0.100 -p 2222 "mysqldump -uremoteuser -p123456 -P33060 dump_db" > dump_db.sql


