LOG_FILE=./logs/$(date "+%Y-%m-%d")-test-log.txt

echo "[ TIMESTAMP: $(date "+%H:%M-%S")" ]>>$LOG_FILE
npx hardhat test | tee -a $LOG_FILE
echo "----------------------------------------------------------------------------------------------------------" >> $LOG_FILE
