#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Twitter username
username="username"

# File to store the latest tweet
file="latest_tweet.txt"
file_path="$BASE_DIR/$file"

# Email to send notification
email="your-email@example.com"

# Check if the required applications are installed
if ! command -v twurl &> /dev/null; then
    echo "twurl could not be found. Please install it and run the script again."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq could not be found. Please install it and run the script again."
    exit 1
fi

# Check if the file exists, if not create it
if [[ ! -f $file_path ]]; then
    touch $file_path
fi

# Get the latest tweet
latest_tweet=$(twurl "/1.1/statuses/user_timeline.json?screen_name=$username&count=1" | jq -r '.[0].text' || echo "")

# Check if the latest tweet is different from the stored one
if [[ "$latest_tweet" != "$(cat $file_path)" ]] && [[ -n "$latest_tweet" ]]; then
    echo "$latest_tweet" > $file_path
    echo "New tweet: $latest_tweet"
    echo "New tweet from $username: $latest_tweet" | mail -s "New Tweet Alert" $email
else
    echo "No new tweets."
fi
