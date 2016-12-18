#!/usr/bin/env python
##########################################################################################
# This script sends a slack notification based on a custom webhook
# Written by Farley <farley@olindata.com> <farley@neonsurge.com>
##########################################################################################

# Libraries, json for parsing JSON, and cli option parser
import json
from pprint import pprint
from optparse import OptionParser
# Imports for reading from stdin
import sys
import select
# Import for calling the slack URL
import urllib2

# Our helper to get STDIN if it exists in a non-blocking fashion
def getBodyFromSTDIN():
    output = ""
    while sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
      line = sys.stdin.readline()
      if line:
        output = output + line + "\n"
      else: # an empty line means stdin has been closed
        return output.strip()
    else:
      return False;

# Convert our severity level into an emoji
def getEmojiFromSeverity(severity):
    severity = severity.lower();
    if (severity == 'info'):        return ':information_source:';
    elif (severity == 'unknown'):   return ':question:';
    elif (severity == 'warning'):   return ':warning:';
    elif (severity == 'error'):     return ':exclamation:';
    else:                           return ':white_check_mark:';

# Default webhook (paste yours here if you want to not have to provide it on the CLI)
# webhook_url = "https://hooks.slack.com/services/123456789/123456789/123456789012345678901234"

# Usage and CLI opts handling
usage = '  \n\
    %prog "Hi from this slack notifier" \n\
or \n\
    echo "Hi from this slack notifier" | %prog \n\
'

parser = OptionParser(usage=usage)
parser.add_option("-v", "--verbose",
                action="store_true",
                dest="verbose",
                default=False,
                help="Make lots of noise")
parser.add_option("-w", "--webhookurl",
                dest="webhookurl",
                help="The webhook URL from Slack, default: " + webhook_url,
                metavar="webhook",
                default=webhook_url)
parser.add_option("-c", "--channel",
                dest="channel",
                help="Channel to sent to, use # prefix for private channels",
                metavar="channel",
                default="")
parser.add_option("-u", "--username",
                dest="username",
                help="The username this message is coming from",
                metavar="username",
                default="Slack Notifier")
parser.add_option("-s", "--severity",
                dest="severity",
                help="The severity of this (info/ok/warning/error/unknown)",
                metavar="severity",
                default="info")
parser.add_option("-e", "--emoji",
                dest="emoji",
                help="The emoji to use (overrides iconurl and severity icon)",
                metavar="emoji",
                default="")
parser.add_option("-i", "--iconurl",
                dest="iconurl",
                help="The URL to a custom icon (overrides severity icon) ",
                metavar="iconurl",
                default="")
(options, args) = parser.parse_args()

# Get the message body
data = getBodyFromSTDIN();
if ((data != False) and (len(data) > 0)):
    body = data
elif len(args) > 0:
    body = ' '.join(args)
else:
    print "ERROR: You MUST pass an argument or pipe STDIN content for the message body"
    parser.print_help()
    exit(1)

# Fix line endings and double line-endings (a shell/python thing)
body = body.replace('\r\n', '\r').replace('\n', '\r').replace('\r\r', '\n')
if options.verbose:     print "VERBOSE: Got body: " + body

# Begin to build our payload
payload = {
    'username': options.username + ' - ' + str(options.severity).lower().title(),
    'text':     body
}

# Set our channel, if set, if not it'll usually use the default (general) channel
if (len(options.channel)):      payload['channel'] = options.channel
# Set our emoji or url if set
if (len(options.emoji)):        payload['icon_emoji'] = options.emoji
elif (len(options.iconurl)):    payload['icon_url'] = options.iconurl
else:                           payload['icon_emoji'] = getEmojiFromSeverity(options.severity);

if options.verbose:             print "VERBOSE: Payload: \n" + json.dumps(payload, sort_keys=True, indent=4, separators=(',', ': '))

# Send the request to Slack
try:
    req = urllib2.Request(webhook_url, json.dumps(payload))
    if options.verbose:
        print "VERBOSE: Sending request to " + webhook_url + "..."
    response = urllib2.urlopen(req)
    result = response.read()
    if (result == 'ok'):
        print "Sent successfully"
        exit(0)
    else:
        print "Error while sending: "
        print result
        exit(1)
except Exception as e:
    print "Error while sending: "
    print(e)
    exit(1)
