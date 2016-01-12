#!/bin/bash
# A multi-line example with a parsed URL

SLACKSTRING="Server: *<https://google.com/|LinkToGoogle>*
User: `whoami`
Task State: Complete" 

echo "Sending Slack Notification"
./send_notification_via_slack.sh -s info -u "Custom Slack Notifier - Update Notification" "$SLACKSTRING"