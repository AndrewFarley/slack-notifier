<?php

// Grab our helper function...
require_once('send_notification_via_slack_helper.php');

echo "This is a WARNING slack notification to the channel #general...";

notify_via_slack("There was a possible problem with this script", "warning", "#general");

sleep(1);

echo "This is an ERROR slack notification to a private channel 'myprivate'";

notify_via_slack("There was a problem with this script", "error", "myprivate");

sleep(1);

// More examples here