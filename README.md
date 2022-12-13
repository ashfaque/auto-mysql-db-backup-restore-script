# auto-mysql-db-backup-restore-script

All the echo outputs can be saved in a file if ran with >> while running this script or in crontab.
Connects from one server to another server.
Over ssh mysqldump .sql file from remote server to present server
Creates new database with todays date in present server where this script is being ran and save db name in a SQlite3 table along with its creation and expiry date as specified by the user.
Restore dump from .sql to the newly created DB.
If error occurs in execution of any of the command, the script will stop executing.
Deletes .sql file
Drops DB older than the number of days specified by the user and updates is_deleted=1 in SQlite3 database for log purpose.
