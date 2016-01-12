<?php
/**
 * This is a helper function to simplify consumption of the slack notifier script.
 * NOTE: It does not support all of the options that the slack notification script supports
 *       but it basically supports what 99% of the scripts calling it will need.
 */
function notify_via_slack($message, $severity='info', $channel='', $username = '', $imageurl = '') {
    
    // If we didn't pass in a username, get it from the name of the calling script
    if (empty($username) || !is_string($username)) {
        $username = getCallingScriptName();
    }

    // If severity is not set, set it
    if (empty($severity))
        $severity = 'info';

    // If channel is not set, set it to Farley's internal channel
    if (empty($channel))
        $channel = 'farley-only-servers';
    
    // If we want to skip sending to slack (for development mostly)
    if (isset($GLOBALS['PARSER_RESULTS'])) {
        if (isset($GLOBALS['PARSER_RESULTS']->options)) {
            if (isset($GLOBALS['PARSER_RESULTS']->options['noslack'])) {
                if ($GLOBALS['PARSER_RESULTS']->options['noslack'] == TRUE) {
                    debug("Skipping sending slack notification: ($severity) ".$message);
                    return false;
                }
            }
        }
    }
    
    $imagecode = '';
    if (!empty($imageurl)) {
        $imagecode = ' -i '.escapeshellarg($imageurl);
    }

    // Execute our attempt to notify via slack, ignoring the retval
    echo "executing..." . escapeshellarg(__DIR__ . '/send_notification_via_slack.sh').' '.escapeshellarg($message)." --severity ".escapeshellarg($severity)." ".(!empty($channel)?"--channel ".escapeshellarg($channel):"")." --username \"$username - ".gethostname()."\"" . $imagecode;
    exec_get_output(escapeshellarg(__DIR__ . '/send_notification_via_slack.sh').' '.escapeshellarg($message)." --severity ".escapeshellarg($severity)." ".(!empty($channel)?"--channel ".escapeshellarg($channel):"")." --username \"$username - ".gethostname()."\"" . $imagecode);

    return;
}

// A helper to get the name of the script initializer for the slack notifier
function getCallingScriptName() {
    // First, attempt to get from SCRIPT_FILENAME...
    if (!empty($_SERVER["SCRIPT_FILENAME"])) {
        $calling_name = trim(basename($_SERVER["SCRIPT_FILENAME"]));
    }
    
    // Then try PHP backtrace
    if (empty($calling_name)) {
        echo "empty!";
        $trace = debug_backtrace();
        print_r($trace);
        echo "calling file was ".$trace[0]['file']."\n";
        if (!empty($trace) && is_array($trace) && count($trace)) {
            while(1) {
                if (count($trace) > 0) {
                    $temp = array_pop($trace);
                    if (!empty($temp['file'])) {
                        $calling_name = $temp['file'];
                        break;
                    }
                } else {
                    break;
                }
            }
        }
    }

    // Then just use "Unknown Script"
    if (empty($calling_name)) {
        $calling_name = "unknown_script";
    }
    
    // Now remove any suffix (like .sh or .php)
    $test = pathinfo($calling_name);
    if (!empty($test['filename']))
        $calling_name = $test['filename'];
    
    // Now lets sexy this name up a bit...
    $calling_name = str_replace(array('_','-'), ' ', $calling_name);
    $calling_name = ucwords(strtolower($calling_name));
    $calling_name = str_replace(' ', '-', $calling_name);
    
    // And return it
    return $calling_name;
}

function exec_get_output($execute_this, $expect_retvals=array(0)) {
    // debug("Executing: $execute_this");
    
    // If we have debugging enabled, don't redirect error output
    $ignoreme = exec($execute_this . " 2> /tmp/deploy_error_output", $output, $retval);
    $result = implode("\n", $output);
    // debug("Executed, return value (".intval($retval).") result: $result");
    if (is_file('/tmp/deploy_error_output')) {
        // debug("Error Output: ".file_get_contents('/tmp/deploy_error_output'));
        @unlink('/tmp/deploy_error_output');
    }
    
    // Input cleansing (of second param)
    if (!is_array($expect_retvals)) {
        if (is_numeric($expect_retvals)) {
            $expect_retvals = array($expect_retvals);
        } else {
            $expect_retvals = array(0);
        }
    }

    // Make sure we got the right retval, otherwise notify farley
    if (!in_array($retval, $expect_retvals)) {
        // Anti-infinite loop
        /*
        if (stristr($execute_this, 'send_notification_via_slack') !== FALSE) {
            notify_via_slack("Unable to execute: $execute_this", 'warning');
        }
        */
        return false;
    }
    
    if (empty($result))
        return true;
    
    return $result;
}