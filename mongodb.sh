#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ $USER_ID -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR] $R please run the script with root user access $N" | tee -a $LOG_FILE
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $R $2 .... failed $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $G $2 .... success $N" | tee -a $LOG_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongo.repo file"

dnf install mongodb-org -y &>> $LOG_FILE
VALIDATE $? "installing mongodb-org"

systemctl enable mongod
VALIDATE $? "enabling mongod service"

systemctl start mongod
VALIDATE $? "starting mongod service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "updating mongod.conf file"

systemctl restart mongod
VALIDATE $? "restarting mongod service"