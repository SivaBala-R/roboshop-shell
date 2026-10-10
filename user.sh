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

# dnf module disable nodejs -y &>> $LOGS_FILE
# VALIDATE $? "disabling nodejs module"

# dnf module enable nodejs:20 -y &>> $LOGS_FILE
# VALIDATE $? "Enabling nodejs module"

dnf install nodejs20 -y &>> $LOGS_FILE
VALIDATE $? "Installing nodejs"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

rm -rf /app
VALIDATE $? "removing existing code"

rm -rf /tmp/user.zip
VALIDATE $? "removing user zip"

mkdir -p /app &>> $LOGS_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>> $LOGS_FILE
cd /app
unzip /tmp/user.zip &>> $LOGS_FILE
VALIDATE $? "Downloaded and extrated user code"

npm install &>> $LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload &>> $LOGS_FILE
VALIDATE $? "Daemon reload is done"

systemctl enable user &>> $LOGS_FILE
systemctl start user &>> $LOGS_FILE
VALIDATE $? "Restarting user"