#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package downloader;
    use strict;
    use warnings;
    use LWP;
    use HTTP::Cookies;
    use logger;

    use constant {
	COOKIE_DURATION => 6000000,
	COOKIE_FILE => "./.crawler_cookie",
    };

    my $browser = LWP::UserAgent->new();
    my $cookie_jar = HTTP::Cookies->new();
    my $cookie_age = 0;
    my %domain_cookies = ();
    
    readCookieFromDisk();



    sub readCookieFromDisk {
	if (-e COOKIE_FILE) {
	    $cookie_jar->load(COOKIE_FILE);
	    my @stats = stat(COOKIE_FILE);
	    $cookie_age = $stats[9];
	}
    }

    sub resetCookieData {
	logger::LOG("Cookie expired, clearing it.", 2);
	$cookie_jar = HTTP::Cookies->new();
	$browser = LWP::UserAgent->new();
	%domain_cookies = ();
	$cookie_age = time();
    }

    sub getURL {
	unless (@_) { die "Incorrect usage of getURL in downloader.\n"; }

	my $url = shift;
	return $browser->get($url);
    }

    sub getURLWithPost {
 	unless ($#_ == 1) {
	    die "Incorrect usage of getURLWithPost in downloader.\n";
	}

	my $url = shift;
	my $post_form_ref = shift;

	return $browser->post($url, \%{$post_form_ref});
    }

    sub getURLWithCookie {
	unless (@_)
	{ die "Incorrect usage of getURLWithCookie in downloader.\n"; }

	my $url = shift; # input url
	my $response; # response is returned

	my $now = time();
	if ($now - $cookie_age > COOKIE_DURATION) {
	    resetCookieData();
	}

	if ($url =~ /(http[s]?:\/\/[^\/]+)/i) {
	    my $domain = $1;
	    if (!defined($domain_cookies{$domain})) {
		logger::LOG("Couldn't find cookie for $domain ".
			    "setting it now", 2);
		$response = $browser->get($url);
		$cookie_jar->extract_cookies($response);  
		$browser->cookie_jar($cookie_jar);
		$response = $browser->get($url);
		$domain_cookies{$domain} = 1;
		$cookie_jar->save(COOKIE_FILE);
		logger::LOG("Set cookie to [".
			    $cookie_jar->as_string()."]", 5);
	    }

	    $response = $browser->get($url);
	}

	return $response;
    }

    1;
}
