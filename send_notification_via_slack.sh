#!/usr/bin/php
<?php

/**
 * Send notification via Slack
 *
 * This script helps easily send a notification via Slack
 *
 * @package     Sysadmin Tools
 * @author      Farley <farley@neonsurge.com>
 * @subpackage  PEAR Console/CommandLine ( see: http://pear.php.net/package/Console_CommandLine )
 * @subpackage  PHP cURL Library ( see: http://php.net/manual/en/book.curl.php )
 * @subpackage  PHP 5.3+
 */

/**
 * Default configuration
 */
$GLOBALS['DEFAULTS'] = array(
    'channel'   => '#farley-only-servers',  // For "public" channels, prefix with #, for private channels, do not prefix
    'username'  => 'CLI Notification',
    'subdomain' => 'PLEASEPURYOURSUBDOMAINHERE',   // Must be your subdomain, eg: put "companyname" in here if your slack URL is "companyname.slack.com"
    'token'     => 'PUTTOKENHERE',                 // Create a "Incoming Webhook" and copy the last part of the Webhook URL here
                                                   //    Eg: if the Webhook URL is https://hooks.slack.com/services/ABC123123/DEF456456/XYZ789789789789
                                                   //    Then your token would be XYZ789789789789
    'severity'  => 'info',                 // must be info, ok, warning, error, or unknown
    'body'      => '',
    'emoji'     => ':information_source:',
    'iconurl'   => '',
);

// Check that we're run on a CLI
if ( php_sapi_name() != 'cli' ) {
    die ('Unsupported SAPI - please use the CLI binary');
}

// First things first, parse the CLI arguments
parseCLIArguments();

// Prepare payload (to be json-ed)
$payload = array(
    'channel' => $GLOBALS['DEFAULTS']['channel'],
    'username' => $GLOBALS['DEFAULTS']['username'] . ' - ' . ucfirst($GLOBALS['DEFAULTS']['severity']),
    'text' => $GLOBALS['DEFAULTS']['body'],
);

if (!empty($GLOBALS['DEFAULTS']['iconurl'])) {
	$payload['icon_url'] = $GLOBALS['DEFAULTS']['iconurl'];
} else {
	$payload['icon_emoji'] = $GLOBALS['DEFAULTS']['emoji'];
}

// Todo, add coloring to text/attachment
$payload = json_encode($payload);

// Send the notification via CURL
verbose("Sending notification... ", false);
$ch = curl_init('https://'.$GLOBALS['DEFAULTS']['subdomain'].'.slack.com/services/hooks/incoming-webhook?token='.$GLOBALS['DEFAULTS']['token'].'&parse=full');
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");
curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_CONNECTTIMEOUT ,5); 
curl_setopt($ch, CURLOPT_TIMEOUT, 5);
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    'Content-Type: application/json',
    'Content-Length: ' . strlen($payload))
);                                                                                                                   
$result = curl_exec($ch);
if (strtolower(trim($result)) == 'ok') {
    verbose('SUCCESS');
    exit(0);
} else {
    verbose('ERROR: '.curl_error($ch));
    exit(1);
}












/***********************
 * CLI ARGUMENT PARSER *
 ***********************/
function parseCLIArguments() {
    // Build our command-line arguments and help /into a usable form
    require_once 'Console/CommandLine.php';
    $GLOBALS['PARSER_RESULTS'] = array();
    $parser = new Console_CommandLine();
    $parser->description = '
This is a fantastical script which sends a notification via Slack.  It can '.
'be configured to customize the senders name, channel name, the '.
'emoji used, etc.  Good for sending reports or notifications to a team.

    Written by Farley <farley@neonsurge.com>';
    $parser->version = '1.0';

    // Add CLI Switches (options)
    $parser->addOption('token', array(
        'short_name'  => '-t',
        'long_name'   => '--token',
        'description' => "This will override the token (".(empty($GLOBALS['DEFAULTS']['token'])?'NOT SPECIFIED':$GLOBALS['DEFAULTS']['token']).")",
        'action'      => 'StoreString',
        'default'     => false,
        'optional'    => (empty($GLOBALS['DEFAULTS']['token'])?false:true)
    ));
    $parser->addOption('channel', array(
        'short_name'  => '-c',
        'long_name'   => '--channel',
        'description' => "What channel this will be sent to, by default (".(empty($GLOBALS['DEFAULTS']['channel'])?'NOT SPECIFIED':$GLOBALS['DEFAULTS']['channel']).")",
        'action'      => 'StoreString',
        'default'     => false,
        'optional'    => (empty($GLOBALS['DEFAULTS']['channel'])?false:true)
    ));
    $parser->addOption('severity', array(
        'short_name'  => '-s',
        'long_name'   => '--severity',
        'description' => "The severity of the message, which dictates the icon used.  Must be (unknown, info, ok, warning, or error).  Default: (".$GLOBALS['DEFAULTS']['severity'].")",
        'action'      => 'StoreString',
        'default'     => false
    ));
    $parser->addOption('emoji', array(
        'short_name'  => '-e',
        'long_name'   => '--emoji',
        'description' => "The emoji to use.  NOTE: This overrides (and is an alternative to) the severity option above.  Default: (".$GLOBALS['DEFAULTS']['emoji'].")",
        'action'      => 'StoreString',
        'default'     => false
    ));
    $parser->addOption('iconurl', array(
        'short_name'  => '-i',
        'long_name'   => '--iconurl',
        'description' => "The URL of the icon to use, this overrides emoji above",
        'action'      => 'StoreString',
        'default'     => false
    ));
    $parser->addOption('username', array(
        'short_name'  => '-u',
        'long_name'   => '--username',
        'description' => "The username to say this message is from.  Default: (".$GLOBALS['DEFAULTS']['username'].")",
        'action'      => 'StoreString',
        'default'     => false
    ));
    

    // TODO: One day
    // $parser->addOption('attach', array(
    //     'short_name'  => '-a', 
    //     'long_name'   => '--attach',
    //     'description' => "This will attach a file from a path specified to this message",
    //     'action'      => 'StoreString',
    //     'default'     => false
    // ));

    // Add CLI Arguments / Parameters
    $parser->addArgument('body', array(
        'description' => '(optional) The body of the email, which can be sent as stdin or here as a parameter',
        'optional'    => true
    ));

    try {
        // Parse our CLI results...
        $result = $parser->parse();
        // Throw it into a superglobal
        $GLOBALS['PARSER_RESULTS'] = $result;
        // Move CLI args into config
        moveCLIArgumentsIntoConfig();
        
    } catch (Exception $exc) {
        verbose();
        $parser->displayError("\n    ".$exc->getMessage()."\n", false);
        $parser->displayUsage();
        exit(1);
    }
}

/**
 * Move CLI arguments into config structure
 */

function moveCLIArgumentsIntoConfig() {
    // Move arguments into configuration where possible
    
    // Move token
    if (!empty($GLOBALS['PARSER_RESULTS']->options['token'])) {
        $GLOBALS['DEFAULTS']['token'] = $GLOBALS['PARSER_RESULTS']->options['token'];
    }

    // Move channel
    if (!empty($GLOBALS['PARSER_RESULTS']->options['channel'])) {
        $GLOBALS['DEFAULTS']['channel'] = $GLOBALS['PARSER_RESULTS']->options['channel'];
    }

    // Move username
    if (!empty($GLOBALS['PARSER_RESULTS']->options['username'])) {
        $GLOBALS['DEFAULTS']['username'] = $GLOBALS['PARSER_RESULTS']->options['username'];
    }

    // Move severity
    if (!empty($GLOBALS['PARSER_RESULTS']->options['severity'])) {
        $emoji = getEmojiFromSeverity($GLOBALS['PARSER_RESULTS']->options['severity']);
        
        if (!empty($emoji)) {
            $GLOBALS['DEFAULTS']['emoji'] = $emoji;
            $GLOBALS['DEFAULTS']['severity'] = $GLOBALS['PARSER_RESULTS']->options['severity'];
        }
    }

    // Move emoji, which overrides severity if specified
    if (!empty($GLOBALS['PARSER_RESULTS']->options['emoji'])) {
        $GLOBALS['DEFAULTS']['emoji'] = $GLOBALS['PARSER_RESULTS']->options['emoji'];
    }

    // Move iconurl
    if (!empty($GLOBALS['PARSER_RESULTS']->options['iconurl'])) {
        $GLOBALS['DEFAULTS']['iconurl'] = $GLOBALS['PARSER_RESULTS']->options['iconurl'];
    }

    // Move attach
    if (!empty($GLOBALS['PARSER_RESULTS']->options['attach'])) {
        if (!is_file($GLOBALS['PARSER_RESULTS']->options['attach'])) {
            throw new Exception('"'.$GLOBALS['PARSER_RESULTS']->options['attach'].'" is not a valid path to a file to attach');
        }
        $GLOBALS['DEFAULTS']['attach'] = $GLOBALS['PARSER_RESULTS']->options['attach'];
    }

    
    // Move body
    if (!empty($GLOBALS['PARSER_RESULTS']->args['body'])) {
        $GLOBALS['DEFAULTS']['body'] = $GLOBALS['PARSER_RESULTS']->args['body'];
    } else {
        // Get data from STDIN
        $GLOBALS['DEFAULTS']['body'] = trim(getDataFromSTDIN());
        
        // Check for no body
        if (empty($GLOBALS['DEFAULTS']['body'])) {
            throw new Exception('No body specified as stdin or as an argument');
        }
    }
    
    // If we have an "error", alert the channel...
    if (strtolower($GLOBALS['PARSER_RESULTS']->options['severity']) == 'error') {
        $GLOBALS['DEFAULTS']['body'] .= ' <!channel>';
    }
}

// Verbose output if enabled
function verbose($message = '', $return = TRUE) {
    echo $message.($return?"\n":"");
}
    
/**
 * Convert our severity level into an emoji
 */
function getEmojiFromSeverity($severity) {
    $severity = strtolower($severity);
    if (empty($severity))
        return false;
    switch($severity) {
        case 'info':
            return ':information_source:';
        case 'unknown':
            return ':question:';
        case 'warning':
            return ':warning:';
        case 'error':
            return ':exclamation:';
        case 'ok':
        default:
            return ':white_check_mark:';
    }
}

/**
 * Milliseconds in-between reads from STDIN before it times out 1000 milliseconds = 1 second
 */
function getDataFromSTDIN($maximum_sleep_in_ms = 100) {
    // Open STDIN
    $stream = fopen('php://stdin','r');
    stream_set_blocking($stream, false);

    // Get from STDIN
    $content = '';
    $lastGotDataTime = microtime(TRUE);
    while($stream AND ! feof($stream)) {

        // If we haven't gotten data in a while
        if(((microtime(TRUE) - $lastGotDataTime) * 1000) > $maximum_sleep_in_ms) {
            // verbose("Taking too long");
            break;
        }
        
        // If we got NO data from stdin
    	if(($line = fgets($stream, 8192)) === false) {
            // verbose("Failed to get data");
            // echo sprintf('%.4f ms ',((microtime(TRUE) - $lastGotDataTime) * 1000));
    		usleep(50000);
    		continue;
    	}
        
        $lastGotDataTime = microtime(TRUE);
        // verbose("Got line: $line");
        $content .= $line;
 
    	usleep(500);
    }
    fclose($stream);
    return $content;
}
