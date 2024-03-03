# Twitter Latest Tweet Fetcher

This is a bash script that fetches the latest tweet from a specific Twitter user using the Twitter API and stores it in a file for comparison. The script uses `twurl` (a tool like curl but specialized for the Twitter API) and `jq` (a command-line JSON processor).

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

You need to have `twurl` and `jq` installed on your system to run this script. If not installed, you can install them using the following commands:

For twurl:
```
sudo apt-get install ruby-dev
sudo gem install twurl
```

For jq:
```
sudo apt-get install jq
```

### Installing

Clone the repository to your local machine:

```
git clone https://github.com/ETFrocks/twitter-latest-tweet-fetcher.git
```

Navigate to the project directory:

```
cd twitter-latest-tweet-fetcher
```

Make the script executable:

```
chmod +x fetchTwitterX-LatestNewTweet.sh
```

### Configuration

You need to authorize `twurl` with your Twitter API keys:

```
twurl authorize --consumer-key key --consumer-secret secret
```

Replace `key` and `secret` with your actual Twitter API keys.

### Usage

Run the script:

```
./fetchTwitterX-LatestNewTweet.sh
```

To run this script every hour, you can use a cron job. Open the crontab file with `crontab -e` and add the following line:

```
0 * * * * /path/to/your/fetchTwitterX-LatestNewTweet.sh
```

This will run the script at the start of every hour. Replace `/path/to/your/fetchTwitterX-LatestNewTweet.sh` with the actual path to your script.

## Built With

* [Bash](https://www.gnu.org/software/bash/) - The scripting language used
* [twurl](https://github.com/twitter/twurl) - Command line tool for interacting with the Twitter API
* [jq](https://stedolan.github.io/jq/) - Lightweight and flexible command-line JSON processor

## Authors

* **BlackBird** - *Initial work* - [ETFrocks](https://github.com/ETFrocks)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to the creators of `twurl` and `jq` for their excellent command line tools.
* A big thank you to all the creators and contributors of open-source software. Your work has made a significant impact on the world of technology.
