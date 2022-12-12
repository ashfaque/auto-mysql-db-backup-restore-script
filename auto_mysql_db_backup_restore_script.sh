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


# Generation of ssh key pairs:
# sudo apt-get install openssh-server
# sudo systemctl enable ssh
# sudo systemctl start ssh
# ssh v3@192.168.0.100 -p 22

# In host PC:
# ~$ ssh-keygen -t rsa    or,    ssh-keygen -t ed25519
# ~$ ssh-copy-id -i ~/.ssh/id_rsa.pub v3@192.168.0.100/home/v3/.ssh/authorized_keys
# or,
# ~$ type $env:USERPROFILE\.ssh\id_rsa.pub | ssh v3@192.168.0.100 -p 2200 "cat >> .ssh/authorized_keys"
# or, echo ssh-ed25519 lksdjfHYJKKJKJHJKkj7856JHKHJKee0ojufUrfq+wA5lGsbT+tD/ Ashfaque@ASH > authorized_keys   # in Server
# ~$ ssh -i ~/.ssh/id_rsa v3@192.168.0.100 -p 2200
# Edit ~/.ssh/config file:
#     Host cppvm
#     HostName 192.168.0.100
#     User v3
#     Port 2200
#     IdentityFile ~/.ssh/private_key

# ~$ ssh v3@cppvm

# in ~/.bashrc alias centos='ssh v3@cppvm'


# To convert private key to pem file. Open puttygen, goto Conversion tab and import key, choose RSA, DSA, ECDSA, EdDSA, SSH-1(RSA) and then you can either save `public or private key` by clicking on that button. Or you can go to : Conversions tab and click on `Export OpenSSH key (Force New Format)` and save it as .pem file.

# To extract compatible public key from a private key use: `ssh-keygen -f private.pem -y > private.pub`



# MariaDB installation:
# sudo apt update

# sudo apt install mariadb-server

# systemctl status mariadb

# sudo mysql_secure_installation 

# mysql -u root -p

# SELECT VERSION();

# CREATE USER remoteuser@localhost IDENTIFIED BY '123456';
# CREATE DATABASE dump_db;
# GRANT ALL ON dump_db.* TO remoteuser@'%' IDENTIFIED BY '123456' WITH GRANT OPTION;

# CREATE USER admin@localhost IDENTIFIED BY 'admin';
# GRANT ALL ON *.* TO admin@'localhost' IDENTIFIED BY 'admin' WITH GRANT OPTION;


# FLUSH PRIVILEGES;

# mysql -u test_user -p

# SHOW DATABASES;

# nano /etc/mysql/my.cnf

# 	[mysqld]
# 	bind-address = 0.0.0.0


# systemctl restart mariadb

# netstat -ant | grep 3306
# ps -ef | grep -i mysql


# vi /etc/my.cnf.d/mariadb-server.cnf -> uncomment bind-address = 0.0.0.0    # CentOS 8
# firewall-cmd --add-port=3306/tcp
# firewall-cmd --permanent --add-port=3306/tcp
# systemctl restart mariadb

