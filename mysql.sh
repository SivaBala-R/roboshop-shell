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

#In linux we don't have mysql-server repo if need mysql-server then we need add mysql-server repos and install
# dnf install mysql-server -y &>> $LOGS_FILE 
# VALIDATE $? "Installing mysql"

dnf install mariadb105-server -y &>> $LOGS_FILE
VALIDATE $? "Installing mysql-server"

systemctl enable mariadb &>> $LOGS_FILE
systemctl start mariadb &>> $LOGS_FILE
VALIDATE $? "enabled and started mysql-server"

# mysql -u root <<EOF
# ALTER USER 'root'@'localhost' IDENTIFIED BY 'RoboShop@1';
# CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'RoboShop@1';
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
# FLUSH PRIVILEGES;
# EOF

# mysql -u root -pRoboShop@1 <<EOF
# CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'RoboShop@1';
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
# FLUSH PRIVILEGES;
# EOF
# VALIDATE $? "Setting up root password"


# mysql -e "ALTER USER 'root'@'%' IDENTIFIED BY 'RoboShop@1';
# VALIDATE $? "Setting root password"

# mysql_secure_installation --set-root-pass RoboShop@1
# VALIDATE $? "Setting up root password"

# mysql -u root -e "
# ALTER USER 'root'@'localhost' IDENTIFIED BY 'RoboShop@1';
# CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'RoboShop@1';
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
# FLUSH PRIVILEGES;"
# VALIDATE $? "Setting up root password"