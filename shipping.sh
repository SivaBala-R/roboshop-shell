LOGFOLDER="/var/log/roboshop"
mkdir -p $LOGFOLDER
sudo chown ec2-user:ec2-user $LOGFOLDER
sudo chmod 755 $LOGFOLDER
LOGFILE="$LOGFOLDER/$0.log"
SCRIPT_DIR=$PWD
MYSQL_HOST=<MYSQL-SERVER-IPADDRESS>

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

dnf install maven -y &>> $LOGFILE
VALIDATE $? "Installing maven"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGFILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N" | tee -a $LOGFILE
fi

rm -rf /app
VALIDATE $? "removing existing code"

rm -rf /tmp/shipping.zip
VALIDATE $? "removing shipping zip"

mkdir -p /app &>> $LOGFILE
VALIDATE $? "creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOGFILE
cd /app 
unzip /tmp/shipping.zip &>> $LOGFILE
VALIDATE $? "dowload and extract code"

mvn clean package &>> $LOGFILE
mv target/shipping-1.0.jar shipping.jar &>> $LOGFILE
VALIDATE $? "moving jar file to target directory"

cp $SCRIP_DIR/shippin.service /etc/systemd/system/shipping.service
VALIDATE $? "creating systemctl service"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "daemon-reload"

dnf install mysql -y &>> $LOGFILE
VALIDATE $? "Installing mysql"

mysql -h $MYSQL_HOST -u root -pRoboShop@1 -e "use cities" &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
    VALIDATE $? "Data loaded"
else
    echo -e "Data already loaded ... $Y SKIPPING $N"
fi

# mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/schema.sql
# mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/app-user.sql
# mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/master-data.sql
# VALIDATE $? "loading data"

systemctl enable shipping &>> $LOGFILE
systemctl restart shipping &>> $LOGFILE
VALIDATE $? "enabling and starting the service"
