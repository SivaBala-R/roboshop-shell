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

cp $SCRIP_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding rabbitmq repo"

dnf install rabbitmq-server -y &>> $LOGS_FILE
VALIDATE $? "Installing rabbitmq server"

systemctl enable rabbitmq-server &>> $LOGS_FILE
systemctl start rabbitmq-server &>> $LOGS_FILE
VALIDATE $? "Enabling and starting rabbitmq server"

rabbitmqctl add_user roboshop roboshop123 &>> $LOGS_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOGS_FILE
VALIDATE $? "setting up username and password"