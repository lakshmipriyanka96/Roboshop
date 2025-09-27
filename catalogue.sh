#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
MONGODB_HOST=mongodb.karela.fun
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

validate(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

####Nodejs Application
dnf module disable nodejs -y
validate $? "Disabling nodejs module"

dnf module enable nodejs:20 -y
validate $? "Enabling nodejs 20 module"

dnf install nodejs -y &>>$LOG_FILE
validate $? "Installing nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
validate $? "Adding roboshop user" &>>$LOG_FILE

mkdir /app &>>$LOG_FILE
validate $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
validate $? "Downloading catalogue code"

cd /app 
validate $? "Changing directory to /app"

unzip /tmp/catalogue.zip &>>$LOG_FILE
validate $? "Extracting catalogue code"

cd /app
validate $? "Changing directory to /app"

npm install &>>$LOG_FILE
validate $? "Installing nodejs dependencies"

cp catalogue.service /etc/systemd/system/catalogue.service
validate $? "Copying catalogue systemd file"

systemctl daemon-reload &>>$LOG_FILE
validate $? "Reloading systemd"

systemctl enable catalogue &>>$LOG_FILE
validate $? "Enabling catalogue service"


systemctl start catalogue &>>$LOG_FILE
validate $? "Starting catalogue service"

systemctl status catalogue &>>$LOG_FILE
validate $? "Checking status of catalogue service"

cp mongo.repo /etc/yum.repos.d/mongo.repo   
validate $? "Adding mongo repo file"

dnf install mongodb-mongosh -y &>>$LOG_FILE 
validate $? "Installing mongo shell"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
validate $? "Loading catalogue schema"

systemctl restart catalogue &>>$LOG_FILE
validate $? "Restarting catalogue service"


