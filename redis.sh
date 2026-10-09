LOGFOLDER="/var/log/roboshop"
mkdir -p $LOGFOLDER
sudo chown ec2-user:ec2-user $LOGFOLDER
sudo chmod 755 $LOGFOLDER
LOGFILE="$LOGFOLDER/$0.log"

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

dnf module disable redis -y &>> $LOGFILE
dnf module enable redis:7 -y &>> $LOGFILE
dnf install redis -y &>> $LOGFILE
VALIDATE $? "Installing redis package"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connection(update on redis config file)"

systemctl enable redis &>> $LOGFILE
systemctl start redis &>> $LOGFILE
VALIDATE $? "enabled and stated redis"