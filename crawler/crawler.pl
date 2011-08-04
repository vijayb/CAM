#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
# 
# 

package main;

use strict;
use warnings;

use semaphore;
use hub;
use deal;
use dealproperties;
use databasehandler;
use dealextractor;
use dealurlextractor;
use failedextractions;
use ratelimiter;
use logger;
use cache;
use downloader;
use crawlerutils;

use constant {
    HUB_RELOAD_DURATION => 1800, # 1800 seconds/30 minutes.
    MAX_RECRAWLABLE_DEAL_DAYS => 7 # Expire recrawlable deals after 7 days
};


# Main data structures of crawler. %hub_properties contains the hubs
# we wish to extract deal links from. %deal_properties contains those
# extracted deal links, which we used to download deal pages so that
# we can extract information from them and put this information in
# the deals database.
my %hub_properties;
my %deal_properties;

# The amount of time since we last rescanned the database for new hubs
my $hub_reload_time=0;

# Setup handler for manual abort of crawler:
$SIG{'INT'} = "cleanupCrawler";

# Do not remove this line unless you're running crawler on a test
# database. It prevents crawlers from stepping on each other.
#&databasehandler::getDatabaseLock();

databasehandler::getRecrawlableDealUrls(
    \%deal_properties, MAX_RECRAWLABLE_DEAL_DAYS);

while (1) { # Main crawler loop
    if (time() - $hub_reload_time > HUB_RELOAD_DURATION) {
	print "Reloading hubs\n";
	$hub_reload_time = time();
	%hub_properties = ();
	databasehandler::getHubProperties(\%hub_properties);
    }

    # For each hub, gather it (either from the cache or by crawling it)
    # then extract the deal links from it and add those links to
    # %deal_properties for later crawling of deal pages.
    # We sort hubs by the last time they were crawled so we don't
    # keep crawling the same hubs over and over again.
    foreach my $hub_url (sort {$hub_properties{$a}->last_crawled() <=>
				   $hub_properties{$b}->last_crawled()}
			 (keys %hub_properties)) {
	my $hub_content;
	$hub_content = cache::getURLFromCache($hub_url);
	if (!defined($hub_content) && # Hub isn't in cache
	    !ratelimiter::rateLimitedHub($hub_url))
	{
	    print "Crawling hub: $hub_url\n";
	    my $response;
	    if ($hub_properties{$hub_url}->use_cookie()) {
		print "$hub_url needs cookie\n";
		$response = downloader::getURLWithCookie($hub_url);
	    } else {
		$response = downloader::getURL($hub_url);
	    }
	    # Once we attempted a download on a hub url, let the
	    # ratelimiter know.
	    ratelimiter::crawledHub($hub_url);
	    if ($response->is_success && defined($response->content())) {
		$hub_content = $response->content();
		cache::insertURLIntoCache($hub_url, $hub_content);
		
		# Certain sites have deals on their hub page (annoying!).
		# For these sites, we want to put the deal page into
		# the cache too, using its deal url (which should be
		# a redirect). We also want to add the deal to the
		# collection of deals to crawl and extract (see below).
		# I.e., put it in the %deal_properties hash.
		my $redirect_url = normalizeURL($response->base());
		if ($hub_properties{$hub_url}->hub_contains_deal() &&
		    defined($redirect_url) &&
		    !($redirect_url eq $hub_url)) # I.e., actually redirected.
		{
		    cache::insertURLIntoCache($redirect_url, $hub_content);
		    
		    if (!defined($deal_properties{$redirect_url})) {
			$deal_properties{$redirect_url} = dealproperties->new();
		    }
		    
		    $deal_properties{$redirect_url}->
			inherit_properties_from_hub($redirect_url,
						    $hub_properties{$hub_url});
		}
	    } else {
		logger::LOG("Error crawling $hub_url, code:".
			    $response->code().", message: ".
			    $response->message(), 2);
	    }
	}

	my $num_deals_extracted = 0;
	if (defined($hub_content) && length($hub_content) > 0) {
	    $num_deals_extracted =
		# pass hub_content by reference to save time.
		# don't want to copy webpages around in memory
		&dealurlextractor::extractDealURLs(\%deal_properties,
						   \$hub_content,
						   $hub_properties{$hub_url});
	}

	$hub_properties{$hub_url}->last_crawled(time());
    }

    # The above section completes the crawling and extracting of hubs.
    # Below we process the deal urls that were extracted above.
    #
    # -----------------------------------------------------------------
    #
    # For each deal, crawl it (or grab it from the cache if it's there),
    # then extract contents of the deal and insert the extracted deal
    # into the database.
    # We sort deals by the last time they were crawled, so that
    # don't keep recrawling the same deals.
    foreach my $deal_url (sort {$deal_properties{$a}->last_crawled() <=>
				    $deal_properties{$b}->last_crawled()}
			  (keys %deal_properties))
    {
	my $properties = $deal_properties{$deal_url};

	# Expire any properties which have been sitting in the
	# %deal_properties hash for MAX_RECRAWLABLE_DEAL_DAYS.
	# This ensures %deal_properties doesn't grow indefinitely.
	if (defined($properties->discovered()) &&
	    crawlerutils::diffDatetimesInSeconds(
		crawlerutils::gmtNow(), $properties->discovered()) >
	    MAX_RECRAWLABLE_DEAL_DAYS*24*60*60) {
	    $properties->expired(1);
	}


	# We only attempt to recrawl deals for non-recrawlable
	# sites if we haven't successfully inserted the deal into
	# the database.
	if (!$properties->recrawl() &&
	    $properties->last_inserted() != 0) { next; }


	my $deal_content;
	# Try grab url from cache:
	$deal_content = cache::getURLFromCache($properties->url());
	if (!defined($deal_content) && # If url isn't in cache, download it
	    !ratelimiter::rateLimitedDealPage($properties->url())) {
	    print "Crawling  ",$properties->url(),"\n";
	    my $response;

	    if ($properties->use_cookie()) {
		$response = downloader::getURLWithCookie($properties->url());
	    } else {
		$response = downloader::getURL($properties->url());
	    }
	    # Once we attempted a download on a deal url, let the
	    # ratelimiter know.
	    ratelimiter::crawledDealPage($properties->url());	    

	    if ($response->is_success) {
		$deal_content = $response->content();
		cache::insertURLIntoCache($properties->url(), $deal_content);
	    } else {
		logger::LOG("Error crawling ".$properties->url()." code:".
			    $response->code().", message: ".
			    $response->message(), 3);
	    }
	}

	# Now that we've crawled the deal page, we need to extract its
	# contents then put those contents into the Deals table in the
	# database.
	if (defined($deal_content)) {
	    my $deal = deal->new();
	    $deal->inherit_from_deal_properties($properties);
	    dealextractor::extractDeal($deal, \$deal_content);

	    my $error = $deal->check_for_extraction_error();
	    if (defined($error)) {
		failedextractions::store($deal->url(), $deal_content, $error);
	    }

	    # We insert the extracted deal in the database, even if there
	    # was an extraction error. It may only be an error in one
	    # field, that can easily be manually corrected in later deal
	    # verification of the database.
	    print "Inserting...\n";
	    my $success = databasehandler::insertDealIntoDatabase($deal);

	    # Only download/insert image if we haven't done so before
	    # (reduces bandwidth on deal websites).
	    if (defined($deal->image_url()) &&
		$properties->last_inserted() == 0) {
		print "Inserting image...\n";
		$success = $success &&
		    databasehandler::getAndInsertImageIntoDatabase(
			$deal->image_url());
	    }

	    # If we successfully inserted the deal, we want to insert
	    # the cities associated with the deal.
	    if ($success) {
		# Only update cities if we discovered some new city
		# since the last time we inserted them into the database.
		if ($properties->city_ids_updated()) {
		    print "Inserting deal cities\n";
		    $success = $success &&
			databasehandler::insertDealCitiesIntoDatabase(
			    $deal_url, $properties->city_ids());

		    if ($success) {
			$properties->city_ids_updated(0);
		    }
		}
	    }


	    if ($success) {
		print "Succeeded in extracting and inserting!\n";
		$properties->last_inserted(time());
	    } else {
		print "Failed in extracting or inserting!\n";
	    }

	    if (defined($deal->expired()) && $deal->expired()) {
		$properties->expired(1);
	    }

	    # If we're past the deadline by a day, then expire
	    # the deal, so that we don't keep recrawling it.
	    if (defined($deal->deadline()) &&
		crawlerutils::diffDatetimesInSeconds(
		    $deal->deadline(), crawlerutils::gmtNow(-24*60*60)) < 0) {
		$properties->expired(1);
	    }


	    if (defined($deal->deadline())) {
		my $seconds_left = crawlerutils::diffDatetimesInSeconds(
		    $deal->deadline(), crawlerutils::gmtNow());
		print $seconds_left, " seconds left. Days: ",
		$seconds_left/(24.0*60*60),"\n";
	    }

	    sleep(1);
	}

	$properties->last_crawled(time());
    }

    print crawlerutils::crawlerstats(\%deal_properties);
    
    # Remove entries in the properties hash for deals that have expired.
    # We do this to save memory, otherwise over time the crawler would
    # maintain information for every deal every discovered.
    foreach my $deal_url (keys %deal_properties) {
	my $properties = $deal_properties{$deal_url};
	if ($properties->expired()) {
	    delete $deal_properties{$deal_url};
	}
    }
    

    print "Heartbeat...",time(),"\n";
    sleep(1);
    logger::updateLogLevel();

}

sub normalizeURL {
    my $normalizedURL;
    if (@_) { 
	$normalizedURL = shift; 
	$normalizedURL =~  s/\?[^\?]*$//;
    }

    return $normalizedURL;
}

sub cleanupCrawler {
    print "Caught One!\n";
    databasehandler::releaseDatabaseLock();
    exit();
}
