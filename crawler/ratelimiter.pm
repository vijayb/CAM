#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    # Provides policy for polite crawling. How often we permit
    # crawling of deal pages, hub pages and their underlying domain.
    package ratelimiter;
    
    use strict;
    use warnings;
    
    # Careful how you set these constants. Setting DOMAIN_SECONDS >
    # HUB_SECONDS for example will severely throttle hub crawling.
    use constant {
	FLUSH_DURATION => 24*60*60, # flush rate limiter once a day
	HUB_SECONDS => 3600,
	DEAL_PAGE_SECONDS => 3600,
	DOMAIN_SECONDS => 15,
	DEAL_PREFIX => "deal",
	HUB_PREFIX => "hub"
    };
    
    
    my (%crawl_dates);
    my $last_flushed = time();
    
    
    # Input: URL, output: whether crawler should rateLimit deal page (i.e., not
    # crawl it.) 1 means don't crawl it. 0 means crawling permitted.
    sub rateLimitedDealPage {
	return rateLimitedPage($_[0], DEAL_PAGE_SECONDS, DEAL_PREFIX);
    }

    # Input: URL, output: whether crawler should rateLimit hub page (i.e., not
    # crawl it.) 1 means don't crawl it. 0 means crawling permitted.
    sub rateLimitedHub {
	return rateLimitedPage($_[0], HUB_SECONDS, HUB_PREFIX);
    }


    sub crawledDealPage {
	crawledPage($_[0], DEAL_PREFIX);
    }

    sub crawledHub {
	crawledPage($_[0], HUB_PREFIX);
    }

    # Input: URL, output: none. Lets ratelimited know that a given page
    # was crawled. This allows it to answer ratelimiting questions.
    sub crawledPage {
	if ($#_ != 1) { die "Incorrect usage of crawledPage.\n"; }

	my ($url, $domain);
	$url = lc($_[0]);
	if ($_[0] =~ /^([hH][tT][tT][pP][sS]?:\/\/[^\/]+)/) {
	    $domain = $_[1].lc($1);
	} else {
	    die "Couldn't obtain domain from URL: [$_[0]]\n";
	}

	$crawl_dates{$url} = time();
	$crawl_dates{$domain} = time();
    }


    sub rateLimitedPage {
	if ($#_ != 2) { die "Incorrect usage of rateLimitedPage.\n"; }

	if (time() - $last_flushed > FLUSH_DURATION) {
	    flush();
	    $last_flushed = time();
	}

	my ($url, $domain);
	$url = lc($_[0]);
	if ($_[0] =~ /^([hH][tT][tT][pP][sS]?:\/\/[^\/]+)/) {
	    $domain = $_[2].lc($1);
	} else {
	    die "Couldn't obtain domain from URL: [$_[0]]\n";
	}
	
	# Don't use rateLimitedDomain when the supplied URL
	# is just a domain: e.g., http://groupon.com/
	if (!($_[2].lc($_[0]) eq $domain) && rateLimitedDomain($domain)) {
	    return 1;
	}

	if (!defined($crawl_dates{$url}) ||
	    time() - $crawl_dates{$url} > $_[1]) {
	    return 0;
	}

	return 1;
    }

    sub rateLimitedDomain {
	if (!defined($crawl_dates{$_[0]}) ||
	    time() - $crawl_dates{$_[0]} > DOMAIN_SECONDS) {
	    return 0;
	}

	return 1;
    }


    sub flush {
	my ($key);
	foreach $key (keys %crawl_dates) {
	    delete $crawl_dates{$key};
	}
    }


    1;
}
