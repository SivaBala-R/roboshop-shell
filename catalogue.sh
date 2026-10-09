LOGFOLDER = "/var/log/roboshop"
sudo mkdir -p $LOGFOLDER
sudo chown ec2-user:ec2-user $LOGFOLDER
sudo chmod 755 $LOGFOLDER
LOGFILE="$LOGFOLDER/$0.log"
SCRIPT_DIR=$PWD

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ $USER_ID -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR] $R please run the script with root access $N" | tee -a $LOGFILE
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $R $2 .... failed $N" | tee -a $LOGFILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $G $2 .... success $N" | tee -a $LOGFILE
    fi
}

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "disabling nodejs module"

dnf module enable nodejs:20 -y &>> $LOGFILe
VALIDATE $? "Enabling nodejs module"

dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "Installing nodejs"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGFILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

rm -rf /app
VALIDATE $? "removing existing code"

rm -rf /tmp/catalogue.zip
VALIDATE $? "removing catalogue zip"

mkdir -p /app &>> $LOGFILE
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOGFILE
cd /app
unzip /tmp/catalogue-v3.zip &>> $LOGFILE
VALIDATE $? "Downloaded and extrated catalogue code"

npm install &>> $LOGFILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Daemon reload is done"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Added mongo repo"

dnf install mongodb-mongosh -y &>> $LOGFILE
VALIDATE $? "Installing mongodb client"

INDEX=$(mongosh --host mongodb.daws90s.shop --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -lt 0 ]; then
    mongosh --host MONGODB-SERVER-IPADDRESS </app/db/master-data.js &>> $LOGFILE
    VALIDATE $? "Load Products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi


systemctl enable catalogue &>> $LOGFILE
systemctl start catalogue &>> $LOGFILE
VALIDATE $? "Restarting catalogue"