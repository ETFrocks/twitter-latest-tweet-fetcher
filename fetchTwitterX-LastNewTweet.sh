#!/bin/bash

# Function to validate email
validate_email() {
    if [[ $1 =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to send email with retry
send_email() {
    local count=0
    while [[ $count -lt 5 ]]; do
        if echo "New tweet from $username: $latest_tweet on $latest_tweet_date" | mail -s "New Tweet Alert" $email; then
            echo "Email sent successfully." | tee -a $log_file_path
            return 0
        else
            ((count++))
            echo "Failed to send email. Attempt $count" | tee -a $log_file_path
            sleep 5
        fi
    done
    echo "Failed to send email after 5 attempts." | tee -a $failure_log_file_path
    return 1
}

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Twitter username
username="username"

# File to store the latest tweet
file="latest_tweet.txt"
file_path="$BASE_DIR/$file"

# File to store the date and time of the latest tweet
date_file="latest_tweet_date.txt"
date_file_path="$BASE_DIR/$date_file"

# Log file
log_file="tweet_fetch_log.txt"
log_file_path="$BASE_DIR/$log_file"

# Execution time log file
time_log_file="execution_time_log.txt"
time_log_file_path="$BASE_DIR/$time_log_file"

# Failure count log file
failure_log_file="failure_count_log.txt"
failure_log_file_path="$BASE_DIR/$failure_log_file"

# Email to send notification
email="your-email@example.com"

# Retry count
retry_count=5

# Start time
start_time=$(date +%s)

# Check internet connectivity
if ! ping -c 1 google.com &> /dev/null; then
    echo "No internet connection. Please check your network and run the script again." | tee -a $log_file_path
    exit 1
fi

# Check if the required applications are installed
if ! command -v twurl &> /dev/null; then
    echo "twurl could not be found. Please install it and run the script again." | tee -a $log_file_path
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq could not be found. Please install it and run the script again." | tee -a $log_file_path
    exit 1
fi

if ! command -v mail &> /dev/null; then
    echo "mail could not be found. Please install it and run the script again." | tee -a $log_file_path
    exit 1
fi

# Check if the files exist, if not create them
if [[ ! -f $file_path ]]; then
    touch $file_path
fi

if [[ ! -f $date_file_path ]]; then
    touch $date_file_path
fi

if [[ ! -f $log_file_path ]]; then
    touch $log_file_path
fi

if [[ ! -f $failure_log_file_path ]]; then
    touch $failure_log_file_path
fi

# Function to get the latest tweet and its date
get_latest_tweet() {
    failure_count=0
    for i in $(seq 1 $retry_count); do
        latest_tweet=$(twurl "/1.1/statuses/user_timeline.json?screen_name=$username&count=1" | jq -r '.[0].text' || echo "")
        latest_tweet_date=$(twurl "/1.1/statuses/user_timeline.json?screen_name=$username&count=1" | jq -r '.[0].created_at' || echo "")
        if [[ -n "$latest_tweet" ]]; then
            break
        else
            echo "Attempt $i to fetch the latest tweet failed. Retrying in 60 seconds..." | tee -a $log_file_path
            ((failure_count++))
            sleep 60
        fi
    done
    echo "Number of failed attempts: $failure_count" | tee -a $failure_log_file_path
}

get_latest_tweet


# Check if the latest tweet is different from the stored one
if [[ "$latest_tweet" != "$(cat $file_path)" ]] && [[ -n "$latest_tweet" ]]; then
    echo "$latest_tweet" > $file_path
    echo "$latest_tweet_date" > $date_file_path
    echo "New tweet: $latest_tweet" | tee -a $log_file_path
    echo "Date: $latest_tweet_date" | tee -a $log_file_path
        if validate_email $email; then
            send_email
        else
            echo "Invalid email address. Please check the email address and run the script again." | tee -a $log_file_path
        fi
else
    echo "No new tweets." | tee -a $log_file_path
fi

# End time
end_time=$(date +%s)

# Calculate execution time
execution_time=$(($end_time - $start_time))

# Log execution time
echo "Execution time: $execution_time seconds" | tee -a $time_log_file_path