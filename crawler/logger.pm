#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package logger;
    
    use strict;
    use warnings;
    use semaphore;
    use IO::Handle;

    use constant {
	DEFAULT_LOG_LEVEL => 2,
	LOG_DIRECTORY => "./crawler_logs/",
	LOG_FILE_PREFIX => "crawler_log_", # Output logs written here
	LOG_LEVEL_FILE => ".crawler_log_level" # Use to specify log level
    };

    my $log_level = DEFAULT_LOG_LEVEL;
    my $log_filename;
    my $log_file_handle;

    createLogFile();
    updateLogLevel();

    sub createLogFilename {
	my @timeData = localtime(time);
	return (LOG_DIRECTORY . LOG_FILE_PREFIX . sprintf("%d%02d%02d",
							  1900+$timeData[5],
							  $timeData[4]+1,
							  $timeData[3]));
    }

    sub createLogMessageTimestamp {
	my @timeData = localtime(time);	
	return sprintf("%d%02d%02d%02d%02d%02d",
		       1900+$timeData[5],
		       $timeData[4]+1,
		       $timeData[3],
		       $timeData[2],
		       $timeData[1],
		       $timeData[0]);
    }

    sub LOG {
	my ($msg, $msg_log_level);
	unless (defined($_[0]) && defined($_[1])) {
	    die "Incorrect use of LOG in logger package\n";
	}

	$msg = $_[0];
	$msg_log_level = $_[1];

	if ($msg_log_level > $log_level) {
	    return;
	}

	if (!(&createLogFilename() eq $log_filename)) {
	    createLogFile();
	}

	print $log_file_handle &createLogMessageTimestamp() . 
	    "($msg_log_level): $msg\n";
	$log_file_handle->autoflush();
    }


    sub createLogFile {
	unless (-d LOG_DIRECTORY) {
	    mkdir(LOG_DIRECTORY, 0777) || die "Couldn't create" . 
		LOG_DIRECTORY . "\n";
	}
	
	if (defined($log_file_handle)) {
	    semaphore::closeLock($log_filename) or
		die "Couldn't close log file: $log_filename\n";
	}

	$log_filename = &createLogFilename();
	
	unless (semaphore::openAppendLockReturnFileHandle($log_filename,
							  \$log_file_handle)) {
	    die "Couldn't open log: $log_filename may be in use.\n";
	}
    }

    sub updateLogLevel {
	my $log_level_filename = "./" . LOG_LEVEL_FILE;
	unless (open(FILE, $log_level_filename)) {
	    LOG("Couldn't open log level file $log_level_filename, " .
		"maintaining current log level: $log_level", 3);   
	    return;
	}
	my $line = <FILE>;
	if (defined($line) && $line =~ /^([0-5])$/) {
	    if ($1 + 0 != $log_level) {
		$log_level = $1 + 0;
		LOG("Changing log level to $log_level.", 0);
	    }
	} else {
	    LOG("Couldn't obtain log level from $log_level_filename, " .
		"maintaining current log level: $log_level", 0);   
	}
	close(FILE);
    }

    1;
}
