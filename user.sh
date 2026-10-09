LOGFOLDER="/var/log/roboshop"
mkdir -p $LOGFOLDER
sudo chown ec2-user:ec2-user $LOGFOLDER
sudo chmod 755 $LOGFOLDER
LOGFILE="$LOGFOLDER/$0.log"
SCRIPT_DIR=$PWD

USER_ID=$(id -u)
R="\[31m"
G="\[32m"
Y="\[33m"
N="\[0m"
TIMESTAMP=$(date '+%Y-%m-%s %H:%M:%S')

if [ $USER_ID -ne 0 ]; then
    echo -e "$TIMESTAMP $R please run the script with root acces or sudo user $N" | tee -a $LOGFILE
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $R $2 ... FAILED $N"  | tee -a $LOGFILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $G $2 ... SUCCEED $N" | tee -a $LOGFILE
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

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>> $LOGFILE
cd /app
unzip /tmp/user.zip &>> $LOGFILE
VALIDATE $? "Downloaded and extrated user code"

npm install &>> $LOGFILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Daemon reload is done"

systemctl enable user &>> $LOGFILE
systemctl start user &>> $LOGFILE
VALIDATE $? "Restarting user"