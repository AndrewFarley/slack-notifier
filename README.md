# slack-notifier
A simple but robust CLI-based slack notifier written in PHP.  This library handles...
* Parsing URLs and anything else that Slack parses
  * See: https://api.slack.com/docs/formatting
* Severity-levels (unknown, info, warning, error, ok)  with automatic icon selection per-level
* Specifying the body of the message via a CLI parameter or STDIN for piping data to it
* Fully functional/useful help screen and CLI parsing
* Parameter-based changing of the following...  
  * Channel
  * Username
  * Log Level
  * Emoji
  * Icon
* Example code and functions to include and call directly from PHP or from Bash

# Configuration / Setup
Note: apt-get examples below are for Ubuntu, adjust accordingly for your distribution

Requires PHP5 CLI
```
sudo apt-get install php5-cli
```

Requires Console-CommandLine
```
sudo apt-get install php-pear
sudo pear install Console_CommandLine
```

Requires PHP5-Curl
```
sudo apt-get install php5-curl
```

Modify the file "send_notification_via_slack.sh" and insert your subdomain and API key token on line 22 and 23.  You'll need to create a Custom Integration, the type is "Incoming Webhook".  

To do this... go to

https://YOURCOMPANY.slack.com/apps/manage/custom-integrations

After you create an incoming webhook, it will give you a "Webhook URL", take that url, and trim off the last part, that is your API token...

Eg: if the webhook URL is...
https://hooks.slack.com/services/ABC123123/DEF456456/XYZ789789789789
Then your token would be XYZ789789789789

Example:
![Alt text](/resources/setup1.png?raw=true "Setup 1")

Help Screen
```
./send_notification_via_slack.sh --help

This is a fantastical script which sends a notification via Slack.  It can
be configured to customize the senders name, channel name, the emoji used,
etc.  Good for sending reports or notifications to a team.

    Written by Farley <farley@neonsurge.com>

Usage:
  ./send_notification_via_slack.sh [options] [body]

Options:
  -t token, --token=token           This will override the token
                                    (qcbJ4EE3YNqsWxIH0Gi53xE6)
  -c channel, --channel=channel     What channel this will be sent to, by
                                    default (#devops-notifications)
  -s severity, --severity=severity  The severity of the message, which
                                    dictates the icon used.  Must be
                                    (unknown, info, ok, warning, or error).
                                     Default: (info)
  -e emoji, --emoji=emoji           The emoji to use.  NOTE: This overrides
                                    (and is an alternative to) the severity
                                    option above.  Default:
                                    (:information_source:)
  -i iconurl, --iconurl=iconurl     The URL of the icon to use, this
                                    overrides emoji above
  -u username, --username=username  The username to say this message is
                                    from.  Default: (CLI Notification)
  -h, --help                        show this help message and exit
  -v, --version                     show the program version and exit

Arguments:
  body  (optional) The body of the email, which can be sent as stdin or
        here as a parameter
```

CLI-Based Examples:

# Notify us when a task is complete including a custom logo
```
./send_notification_via_slack.sh --username Notify-When-Task-Complete\ -\ `hostname` --severity ok --iconurl "https://cdn.tutsplus.com/vector/uploads/legacy/articles/linkb_20weirdlogos/3.jpg" --channel "farley-only-servers" "Successfully performed task on `date +"%y-%m-%d"`"
```
![Alt text](/resources/example1.png?raw=true "Example 1")

# Bash-based example, showing URL parsing (see example.sh)
```
#!/bin/bash
SLACKSTRING="Server: *<https://google.com/|LinkToGoogle>*
User: `whoami`
Task State: Complete" 

echo "Sending Slack Notification"
./send_notification_via_slack.sh -s info -u "Custom Slack Notifier - Update Notification" "$SLACKSTRING"
```
![Alt text](/resources/example2.png?raw=true "Example 2")


# PHP-based example (see example.php)
```
// Grab our helper functions
require_once('send_notification_via_slack_helper.php');
echo "This is a WARNING slack notification to the channel #general...";
notify_via_slack("There was a possible problem with this script", "warning", "#general");
sleep(1);
echo "This is to a private channel named 'my-private-channel'";
notify_via_slack("There was a possible problem with this script", "warning", "my-private-channel");
```
![Alt text](/resources/example3.png?raw=true "Example 3")

# Please feel free to add examples, documentation, features, etc.  Fork me and send a pull request.
