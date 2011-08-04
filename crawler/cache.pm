#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package cache;
    use strict;
    use warnings;
    use logger;
    use semaphore;
    use Digest::MD5 qw(md5_hex);

    use constant {
	EXPIRY_DURATION => 0, # 6000 seconds/1 hour
	CACHE_DIRECTORY => "./crawler_cache/",
    };

    my %url_content;
    my %url_timestamps;
    my $last_cache_cleanse = time();

    createCacheDirectory();
    clearOldFilesFromCacheDirectory();
    readCacheFromDisk();

    sub createCacheDirectory {
	unless (-d CACHE_DIRECTORY) {
	    mkdir(CACHE_DIRECTORY, 0777) || die "Couldn't create" . 
		CACHE_DIRECTORY . "\n";
	}
    }

    sub readCacheFromDisk {
	my $list_cmd = "find ".CACHE_DIRECTORY." -mindepth 1";
	my @cache_files = `$list_cmd`;

	my $total_files_successfully_read = 0;
	foreach my $file (@cache_files) {
	    chomp($file);
	    my $filehandle;
	    
	    if (open($filehandle, $file)) {
		my $url;
		my $timestamp;
		my $content;
		
		# First line in a cache entry will be a timestamp
		# and the url for the content that follows in
		# subsequent lines. They will be comma separated.
		# E.g., 1310258023,http://tippr.com/seattle/
		my $line = <$filehandle>;
		if (defined($line) &&
		    $line =~ /^([0-9]+),(.+)$/) {
		    $timestamp = $1 + 0;
		    $url = $2;
		    
		    while ($line = <$filehandle>) {
			$content = $content.$line;
		    }

		    if (defined($content)) {
			$url_content{$url} = $content;
			$url_timestamps{$url} = $timestamp;
			$total_files_successfully_read++;
		    }
		}
	    }
	}

	logger::LOG(($#cache_files+1)." file(s) in cache directory, " .
		    "$total_files_successfully_read successfully read.", 1);
    }

    sub clearOldFilesFromCacheDirectory {
	my $list_cmd = "find ".CACHE_DIRECTORY." -mindepth 1";
	my @cache_files = `$list_cmd`;

	my $total_files_expired = 0;
	my $total_files_expired_and_deleted = 0;
	foreach my $file (@cache_files) {
	    chomp($file);
	    my $file_age = (-M $file)*24*60*60 + 1;
	    
	    if ($file_age > EXPIRY_DURATION) {
		$total_files_expired++;
		if (unlink($file)==1) {
		    $total_files_expired_and_deleted++;
		}
	    }
	}
	
	if ($total_files_expired > 0) {
	    logger::LOG(($#cache_files+1)." file(s) in cache directory, ".
			"$total_files_expired were expired, of which ".
			"$total_files_expired_and_deleted were ".
			"successfully deleted.", 1);
	}
    }


    sub getURLFromCache {
	unless (@_) { die "Incorrect usage of getURLFromCache.\n" }
	my $url = shift;

	my $content;
	
	# Look for the URL in the cache:
	if (defined($url_timestamps{$url})) {
	    if (time() - $url_timestamps{$url} < EXPIRY_DURATION) {
		logger::LOG("Obtaining $url from cache.", 3);
		$content = $url_content{$url};
	    } else {
		logger::LOG("$url has expired in cache, deleting it.", 3);
		delete $url_content{$url};
		delete $url_timestamps{$url};
	    }
	}

	return $content;
    }

    sub getTimestampFromCache {
	unless (@_) { die "Incorrect usage of getTimestampFromCache.\n" }
	my $url = shift;
	my $timestamp;
	if (defined($url_timestamps{$url})) {
	    $timestamp = $url_timestamps{$url};
	}

	return $timestamp;
    }


    sub insertURLIntoCache {
	if (EXPIRY_DURATION == 0) { return; }

	unless ($#_ == 1) { die "Incorrect usage of insertURLIntoCache.\n"; }
	my $url = shift;
	my $content = shift;
	my $now = time();

	if (defined($content)) {
	    # add .html to cache file name for easy browser viewing.
	    my $filename = CACHE_DIRECTORY . md5_hex($url) . ".html";
	    my $file_handle;

	    logger::LOG("Placing $url in cache file: $filename", 2);
	    unless (semaphore::openWriteLockReturnFileHandle($filename,
							     \$file_handle)) {
		die "Couldn't open cache file: $filename may be in use.\n";
	    }
	    print $file_handle "$now,$url\n";
	    print $file_handle $content;
	    semaphore::closeLock($filename);
	    
	    $url_content{$url} = $content;
	    $url_timestamps{$url} = $now;
	}

	# Remove old files so cache directory never gets too big
	if ($now - $last_cache_cleanse > EXPIRY_DURATION) {
	    clearOldFilesFromCacheDirectory();
	    $last_cache_cleanse = $now;
	}
    }

    1;
}
