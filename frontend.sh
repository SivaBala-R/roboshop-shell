#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(data '+%Y-%m-%d %H:%M:%S')

if [ $UUSER_ID -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR] $R please run the script with root acces $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $R $2 ... FAILED $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $G $2 ... SUCCEED $N" | tee -a $LOGS_FILE
    fi
}

# dnf module disable nginx -y &>> $LOGFILE
# dnf module enable nginx:1.24 -y &>> $LOGFILE
dnf install nginx -y &>> $LOGS_FILE
VALIDATE $? "Installing nodejs"

systemctl enable nginx &>> $LOGS_FILE 
systemctl start nginx &>> $LOGS_FILE
VALIDATE $? "enable and start nodejs"

rm -rf /usr/share/nginx/html/* &>> $LOGS_FILE
VALIDATE $? "default content is removing from html directory"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOGS_FILE
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>> $LOGS_FILE
VALIDATE $? "download and extract of code done"

rm -rf /etc/nginx/nginx.conf
VALIDATE $? "Removed Default conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "config file copied"

systemctl restart nginx
VALIDATE $? "nginx restart"
