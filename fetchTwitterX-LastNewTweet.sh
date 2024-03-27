#!/bin/bash

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

# Email to send notification
email="your-email@example.com"

# Retry count
retry_count=5

# Check if the required applications are installed
if ! command -v twurl &> /dev/null; then
    echo "twurl could not be found. Please install it and run the script again." | tee -a $log_file_path
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq could not be found. Please install it and run the script again." | tee -a $log_file_path
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

# Function to get the latest tweet and its date
get_latest_tweet() {
    for i in $(seq 1 $retry_count); do
        latest_tweet=$(twurl "/1.1/statuses/user_timeline.json?screen_name=$username&count=1" | jq -r '.[0].text' || echo "")
        latest_tweet_date=$(twurl "/1.1/statuses/user_timeline.json?screen_name=$username&count=1" | jq -r '.[0].created_at' || echo "")
        if [[ -n "$latest_tweet" ]]; then
            break
        else
            sleep 60
        fi
    done
}

get_latest_tweet

# Check if the latest tweet is different from the stored one
if [[ "$latest_tweet" != "$(cat $file_path)" ]] && [[ -n "$latest_tweet" ]]; then
    echo "$latest_tweet" > $file_path
    echo "$latest_tweet_date" > $date_file_path
    echo "New tweet: $latest_tweet" | tee -a $log_file_path
    echo "Date: $latest_tweet_date" | tee -a $log_file_path
    if echo "New tweet from $username: $latest_tweet on $latest_tweet_date" | mail -s "New Tweet Alert" $email; then
        echo "Email sent successfully." | tee -a $log_file_path
    else
        echo "Failed to send email." | tee -a $log_file_path
    fi
else
    echo "No new tweets." | tee -a $log_file_path
fi
