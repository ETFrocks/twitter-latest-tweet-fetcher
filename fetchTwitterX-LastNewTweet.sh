#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 [--help]"
    echo
    echo "This script fetches the latest tweet from a specified Twitter account and sends an email notification if there is a new tweet."
    echo "It also checks the reachability of the Twitter API and the functionality of the email before starting."
    echo "The script retries fetching the tweet for a specified number of times if it fails."
    echo "It logs the start and end times, the execution time, the number of failed and successful attempts, and the number of new tweets since the last run."
    echo
    echo "Options:"
    echo "  --help    Display this help and exit"
}

# Check if --help option is given
if [[ $1 == "--help" ]]; then
    usage
    exit 0
fi

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
    if validate_email $email; then
        local count=0
        while [[ $count -lt 5 ]]; do
            if echo "$1" | mail -s "$2" $email; then
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
    else
        echo "Invalid email address. Please check the email address and run the script again." | tee -a $log_file_path
        return 1
    fi
}

# Function to check if the email was sent successfully
check_email_status() {
    if send_email "Test email to check functionality" "Test Email"; then
        echo "Email functionality is working properly." | tee -a $log_file_path
    else
        echo "Failed to send test email. Please check the email address and the mail server." | tee -a $log_file_path
        exit 1
    fi
}

# Function to check if the Twitter API is reachable
check_twitter_api() {
    if ! curl -s "https://api.twitter.com/1.1/" >/dev/null; then
        echo "Twitter API is not reachable. Please check your network and run the script again." | tee -a $log_file_path
        exit 1
    fi
}

# Check if the Twitter API is reachable before starting the script
check_twitter_api

# Check if the email function is working before starting the script
check_email_status

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

# Send start notification
send_email "Script started at $(date)" "Script Start Notification"

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

# Function to send failure notification
send_failure_notification() {
    local count=0
    while [[ $count -lt 5 ]]; do
        if echo "Failed to fetch the latest tweet after all retry attempts." | mail -s "Tweet Fetch Failure Alert" $email; then
            echo "Failure notification sent successfully." | tee -a $log_file_path
            return 0
        else
            ((count++))
            echo "Failed to send failure notification. Attempt $count" | tee -a $log_file_path
            sleep 5
        fi
    done
    echo "Failed to send failure notification after 5 attempts." | tee -a $failure_log_file_path
    return 1
}
# Success count log file
success_log_file="success_count_log.txt"
success_log_file_path="$BASE_DIR/$success_log_file"

# Check if the success count log file exists, if not create it
if [[ ! -f $success_log_file_path ]]; then
    echo 0 > $success_log_file_path
fi

# Function to get the latest tweet and its date
get_latest_tweet() {
    failure_count=0
    success_count=$(cat $success_log_file_path)
    for i in $(seq 1 $retry_count); do
        latest_tweet=$(twurl "/1.1/statuses/user_timeline.json?screen_name=$username&count=1" | jq -r '.[0].text' || echo "")
        latest_tweet_date=$(twurl "/1.1/statuses/user_timeline.json?screen_name=$username&count=1" | jq -r '.[0].created_at' || echo "")
        if [[ -n "$latest_tweet" ]]; then
            ((success_count++))
            echo $success_count > $success_log_file_path
            break
        else
            echo "Attempt $i to fetch the latest tweet failed. Retrying in 60 seconds..." | tee -a $log_file_path
            ((failure_count++))
            sleep 60
        fi
    done
    echo "Number of failed attempts: $failure_count" | tee -a $failure_log_file_path
    echo "Number of successful attempts: $success_count" | tee -a $success_log_file_path
}

get_latest_tweet

if [[ -n "$latest_tweet" ]]; then
    # Check if the latest tweet is different from the stored one
    if [[ "$latest_tweet" != "$(cat $file_path)" ]]; then
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
else
    echo "Failed to fetch the latest tweet after all retry attempts." | tee -a $log_file_path
    if validate_email $email; then
        check_email_status
    else
        echo "Invalid email address. Please check the email address and run the script again." | tee -a $log_file_path
    fi
fi

# File to store the tweet count
tweet_count_file="tweet_count.txt"
tweet_count_file_path="$BASE_DIR/$tweet_count_file"

# Check if the tweet count file exists, if not create it
if [[ ! -f $tweet_count_file_path ]]; then
    echo 0 > $tweet_count_file_path
fi

# Function to get the tweet count
get_tweet_count() {
    tweet_count=$(twurl "/1.1/users/show.json?screen_name=$username" | jq -r '.statuses_count' || echo "")
}

get_tweet_count

if [[ -n "$tweet_count" ]]; then
    # Check if the tweet count is different from the stored one
    if [[ "$tweet_count" != "$(cat $tweet_count_file_path)" ]]; then
        echo "$tweet_count" > $tweet_count_file_path
        new_tweets=$(($tweet_count - $(cat $tweet_count_file_path)))
        echo "Number of new tweets since last run: $new_tweets" | tee -a $log_file_path
    else
        echo "No new tweets since last run." | tee -a $log_file_path
    fi
else
    echo "Failed to fetch the tweet count." | tee -a $log_file_path
fi

# End time
end_time=$(date +%s)

# Send end notification
send_email "Script ended at $(date)" "Script End Notification"

# Calculate execution time
execution_time=$(($end_time - $start_time))

# Log execution time
echo "Execution time: $execution_time seconds" | tee -a $time_log_file_path