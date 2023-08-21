# sudo apt-get install msmtp ca-certificates

# After that run this
cat - <<EOF > ~/.msmtprc
# Default settings
defaults
auth    on
tls    on
tls_trust_file    /etc/ssl/certs/ca-certificates.crt
logfile ~/.msmtp.log
account outlook
host smtp.office365.com
port 587
from support@shyamfuture.com
user support@shyamfuture.com
password Cav77154
tls_starttls on

account default : outlook
EOF

# Then run this
chmod 600 ~/.msmtprc



# Make a file -> nano ~/low_disk_space_auto_mail.sh
#!/bin/sh
CURRENT_OCCUPIED_PERCENT=$(df / | grep / | awk '{print $5}' | sed 's/%//g')
THRESHOLD_PERCENT=90

if [ "$CURRENT_OCCUPIED_PERCENT" -gt "$THRESHOLD_PERCENT" ] ; then
        (echo "Subject: WARNING! Server Disk Space Running Out."; echo "\n${CURRENT_OCCUPIED_PERCENT}% disk space occupied for SSIL Prod DB Backup Server.") | msmtp -a outlook ashfaque.alam@shyamfuture.com
        current_date=$(date -d "+ 330 minutes" +'%d-%m-%Y %H:%M:%S')
        echo "Email fired at : ${current_date} IST"
fi
