#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Twitter username
username="username"

# File to store the latest tweet
file="latest_tweet.txt"

# Get the latest tweet
latest_tweet=$(twurl "/1.1/statuses/user_timeline.json?screen_name=$username&count=1" | jq -r '.[0].text')

# Check if the latest tweet is different from the stored one
if [[ "$latest_tweet" != "$(cat $file)" ]]; then
    echo "$latest_tweet" > $BASE_DIR/$file
    echo "New tweet: $latest_tweet"
else
    echo "No new tweets."
fi
