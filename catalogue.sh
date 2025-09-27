#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$(pwd)
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

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
    echo "roboshop user already exists....$Y SKIPPING $N"
fi 

mkdir -p /app &>>$LOG_FILE
validate $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
validate $? "Downloading catalogue code"

cd /app 
validate $? "Changing directory to /app"

rm -rf /app/* &>>$LOG_FILE
validate $? "Cleaning up app directory"

unzip /tmp/catalogue.zip &>>$LOG_FILE
validate $? "Extracting catalogue code"

npm install &>>$LOG_FILE
validate $? "Installing nodejs dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
validate $? "Copying catalogue systemd file"

systemctl daemon-reload &>>$LOG_FILE
validate $? "Reloading systemd"

systemctl enable catalogue &>>$LOG_FILE
validate $? "Enabling catalogue service"


cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo   
validate $? "Adding mongo repo file"

dnf install mongodb-mongosh -y &>>$LOG_FILE 
validate $? "Installing mongo shell"

    mongosh --host $MONGODB_HOST </app/db/master-data.js 
    VALIDATE $? "Load catalogue products"


systemctl restart catalogue &>>$LOG_FILE
validate $? "Restarting catalogue service"


