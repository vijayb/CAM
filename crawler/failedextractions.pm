#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package failedextractions;
    use strict;
    use warnings;
    use logger;
    use semaphore;
    use Digest::MD5 qw(md5_hex);

    use constant {
	FAILED_EXTRACTIONS_DIRECTORY => "./failed_extractions/",
    };

    createFailedExtractionsDirectory();

    sub createFailedExtractionsDirectory {
	unless (-d FAILED_EXTRACTIONS_DIRECTORY) {
	    mkdir(FAILED_EXTRACTIONS_DIRECTORY, 0777) ||
		die "Couldn't create".FAILED_EXTRACTIONS_DIRECTORY."\n";
	}
    }

    sub store {
	unless ($#_ == 2) { die "Incorrect usage of store.\n"; }
	my $url = shift;
	my $content = shift;
	my $error = shift;
	$error =~ s/\s+/_/g;
	my $now = time();

	if (defined($content)) {
	    my @timeData = localtime(time);	
	    my $date = sprintf("%d%02d%02d",
			       1900+$timeData[5],
			       $timeData[4]+1,
			       $timeData[3]);
	    unless (-d FAILED_EXTRACTIONS_DIRECTORY."$date/") {
		mkdir(FAILED_EXTRACTIONS_DIRECTORY."$date/", 0777) ||
		    die
		    "Couldn't create".FAILED_EXTRACTIONS_DIRECTORY."$date/\n";
	    }


	    # add .html to filename for easy browser viewing.
	    my $filename = FAILED_EXTRACTIONS_DIRECTORY."$date/".
		$error."_".md5_hex($url).".html";
	    my $file_handle;

	    unless (semaphore::openWriteLockReturnFileHandle($filename,
							     \$file_handle)) {
		die "Couldn't open $filename may be in use.\n";
	    }
	    print $file_handle "$now,$url\n";
	    print $file_handle $content;
	    semaphore::closeLock($filename);
	}
    }

    1;
}
