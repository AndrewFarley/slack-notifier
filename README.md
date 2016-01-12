# slack-notifier
A simple but robust CLI-based slack notifier

Examples below are for Ubuntu

Requires PHP5 CLI
```
sudo apt-get install php5 php5-cli
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

CLI-Based Examples:

# Notify us when a task is complete including a custom logo
```
./send_notification_via_slack.sh --username Notify-When-Task-Complete\ -\ `hostname` --severity ok --iconurl "https://cdn.tutsplus.com/vector/uploads/legacy/articles/linkb_20weirdlogos/3.jpg" --channel "farley-only-servers" "Successfully performed task on `date +"%y-%m-%d"`"
```
![Alt text](/example1.png?raw=true "Example 1")

# Bash-based example, showing URL parsing (see example.sh)
```
#!/bin/bash
SLACKSTRING="Server: *<https://google.com/|LinkToGoogle>*
User: `whoami`
Task State: Complete" 

echo "Sending Slack Notification"
./send_notification_via_slack.sh -s info -u "Custom Slack Notifier - Update Notification" "$SLACKSTRING"
```

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
