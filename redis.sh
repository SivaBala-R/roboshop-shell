#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"

USER_ID=$(id -u)
R="\[31m"
G="\[32m"
Y="\[33m"
N="\[0m"
TIMESTAMP=$(date '+%Y-%m-%s %H:%M:%S')

if [ $USER_ID -ne 0 ]; then
    echo -e "$TIMESTAMP $R please run the script with root acces or sudo user $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $R $2 ... FAILED $N"  | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $G $2 ... SUCCEED $N" | tee -a $LOGS_FILE
    fi
}

# dnf module disable redis -y &>> $LOGS_FILE
# dnf module enable redis:7 -y &>> $LOGS_FILE
dnf install redis -y &>> $LOGS_FILE
VALIDATE $? "Installing redis package"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connection(update on redis config file)"

systemctl enable redis &>> $LOGS_FILE
systemctl start redis &>> $LOGS_FILE
VALIDATE $? "enabled and stated redis"