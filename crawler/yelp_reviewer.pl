#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) August, 2010
#
#

package main;

use strict;
use warnings;

use LWP::UserAgent;
use LWP::Simple;
use HTTP::Request::Common qw(POST);
use Digest::MD5 qw(md5_hex);
use getargs;
use JSON::XS;

use genericextractor;

use constant {
    MAX_DAYS => 2,
    YELP_CACHE_DIRECTORY => "./yelp_cache/",
    YELP_ID => "wu6Vp9sa7z62Wpv7H-7GwA"
};

&createCacheDirectory();

my ($webserver, $database, $user, $password);
getargs::getBasicArgs(\$webserver, \$database, \$user, \$password);

my $browser = LWP::UserAgent->new();
my $json_coder = JSON::XS->new->utf8->allow_nonref;

my $request = $webserver."get_yelpreviewable_deals.php?"."database=".$database.
    "&user=".$user."&password=".$password."&max_days=".MAX_DAYS;

my $post_request = $webserver."insert_yelp_review.php?"."database=".$database.
    "&user=".$user."&password=".$password;

my %deals_successfully_reviewed = ();



###########################################################################
# Main loop for finding deals which may have yelp reviews, and for finding
# said reviews.
#
while (1) {
    my $deals_page = get $request;

    #print $deals_page;
    if (defined($deals_page)) {
	my @address_lines = split(/^/, $deals_page);

	printf("%d deals from database obtained which may have yelp ".
	       "reviews\n\n",($#address_lines+1)/5);

	sleep(5);
	for (my $i=0; $i+4 <= $#address_lines; $i+=5) {
	    sleep(2);

	    my ($deal_url, $name, $phone, $latitude, $longitude);
	    $deal_url = $address_lines[$i]; chomp($deal_url);
	    $name = $address_lines[$i+1]; chomp($name);
	    $name =~ s/\&amp;/\&/g;
	    $phone = $address_lines[$i+2]; chomp($phone);
	    $phone =~ s/[^0-9]//g;
	    $latitude = $address_lines[$i+3]; chomp($latitude);
	    $longitude = $address_lines[$i+4]; chomp($longitude);

	    if ( (!defined($phone) || length($phone) < 9) &&
		 ((!defined($latitude)  || length($latitude) == 0) ||
		  (!defined($longitude) || length($longitude) == 0))) {
		print "No phone, lat-long information for [$deal_url], ".
		    "skipping... (perhaps geocoder isn't running?)\n\n\n";
		next;
	    }

	    if (defined($deals_successfully_reviewed{$deal_url})) {
		print "Already got yelp review for [$deal_url], skipping.\n\n";
		next;
	    }

	    print "Deal: [$deal_url]\n";

	    # First try find yelp review by looking up phone number:
	    #
	    if (defined($phone) && length($phone) >=9) {
		my $yelp_request =
		    "http://api.yelp.com/phone_search?phone=$phone".
		    "&ywsid=".YELP_ID;
    
		if (checkBusinessesForMatch($yelp_request, $name, $deal_url)) {
		    print "\n\n\n";
		    next;
		}
	    }
	    

	    # If phone number lookup didn't yield a match, then look
	    # up the businesses based on lat/long in a 0.1 mile radius
	    #
	    if(defined($latitude) && length($latitude) >0 &&
	       defined($longitude) && length($longitude) >0) {
		my $yelp_request =
		    "http://api.yelp.com/business_review_search?".
		    "lat=$latitude&long=$longitude&radius=0.1&limit=20".
		    "&ywsid=".YELP_ID;
		
		if (checkBusinessesForMatch($yelp_request, $name, $deal_url)) {
		    print "\n\n\n";
		    next;
		}

		my $modified_name = $name;
		$modified_name =~ s/\s+/%20/g;
		$modified_name =~ s/[^A-Za-z'%0-9]//g;
		
		# If the lat-long didn't work by themselves, we may
		# have an area that is dense with businesses. Since
		# yelp only returns 20 results we can try combining
		# the lat-long with the business name to see if that
		# gets a match. When using the business name we will
		# relax the search radius a bit to 1 mile.
		#
		$yelp_request =
		    "http://api.yelp.com/business_review_search?".
		    "term=$modified_name".
		    "&lat=$latitude&long=$longitude&radius=1&limit=20".
		    "&ywsid=".YELP_ID;
		
		if (checkBusinessesForMatch($yelp_request, $name, $deal_url)) {
		    print "\n\n\n";
		    next;
		}
		
	    }

	    print "No matches.\n\n\n";
	}
    }

    print "Sleeping for a few seconds... ".time()."\n";
    sleep(15);
}



###############################################################################
# Helper functions

sub checkBusinessesForMatch {
    if ($#_ != 2) {
	die "Incorrect usage of checkBusinessesForMatch\n";
    }

    my $yelp_request = shift;
    my $name = shift;
    my $deal_url = shift;

    my ($yelp_page, %json, @businesses);

    $yelp_page = getYelpPage($yelp_request, $deal_url, $name);
    %json = %{$json_coder->decode($yelp_page)};

    # If we go over the yelp query limit the return code will not be
    # 0. We want to check for this code, because continuing processing
    # empty yelp requests is bad, especially since we cache them.
    if (!defined($json{"message"}{"code"}) ||
	$json{"message"}{"code"} eq "4") {
	die "Error in return yelp request [$yelp_request]\n$yelp_page\n";
    }

    if (defined($json{"message"}{"code"}) &&
	$json{"message"}{"code"} ne "0") {
	print "******** Warning: [$yelp_request]\n$yelp_page\n";
    }
    @businesses = @{$json{"businesses"}};
    print "".($#businesses+1)." businesses found\n";



    foreach my $business (@businesses) {
	my $yelp_name = ${$business}{"name"};
	my $yelp_rating = ${$business}{"avg_rating"};
	my $yelp_url = ${$business}{"url"};
	my $yelp_review_count = ${$business}{"review_count"};
	my @reviews = @{${$business}{"reviews"}};


	my @categories = @{${$business}{"categories"}};
	my $yelp_categories;
	foreach my $category (@categories) {
	    if (!defined($yelp_categories)) { 
		$yelp_categories = $category->{"name"};
	    } else {
		$yelp_categories =
		    $yelp_categories.",".$category->{"name"};
	    }
	}
	
	# Insert yelp information into database if the yelp name
	# is similar enough to the business name in the database.
	if (genericextractor::similarEnough($yelp_name, $name)) {
	    print "[$yelp_name] and [$name] are similar enough\n";
	    my %post_form;
	    
	    $post_form{"url"} = $deal_url;
	    if (defined($yelp_rating)) {
		$post_form{"yelp_rating"} = $yelp_rating;
	    }
	    if (defined($yelp_url)) {
		$post_form{"yelp_url"} = $yelp_url;
	    }
	    if (defined($yelp_review_count)) {
		$post_form{"yelp_review_count"} = $yelp_review_count;
	    }
	    if (defined($yelp_categories)) {
		$post_form{"yelp_categories"} = $yelp_categories;
	    }

	    foreach (my $i=0; $i <= $#reviews && $i <= 2; $i++) {
		my $j = $i+1;
		if (defined(${$reviews[$i]}{"text_excerpt"})) {
		    $post_form{"yelp_excerpt$j"} = 
			${$reviews[$i]}{"text_excerpt"};
		}
		if (defined(${$reviews[$i]}{"user_name"})) {
		    $post_form{"yelp_user$j"} = ${$reviews[$i]}{"user_name"};
		}
		if (defined(${$reviews[$i]}{"rating"})) {
		    $post_form{"yelp_rating$j"} = ${$reviews[$i]}{"rating"};
		}
		if (defined(${$reviews[$i]}{"user_url"})) {
		    $post_form{"yelp_user_url$j"} = ${$reviews[$i]}{"user_url"};
		}
		if (defined(${$reviews[$i]}{"user_photo_url"})) {
		    $post_form{"yelp_user_image_url$j"} =
			${$reviews[$i]}{"user_photo_url"};
		}
	    }
	    
	    print "Inserting yelp information... ";
	    my $response = $browser->post($post_request, \%post_form);
	    
	    if (defined($response) &&
		$response->content() =~ /error/i) {
		die "\n",$response->content(),"\n";
	    } else {
		$deals_successfully_reviewed{$deal_url} = 1;
		print "success!\n";
	    }

	    # Since we found the yelp review, we can skip the
	    # rest of @businesses
	    return 1;
	} else {
	    print "[$name] and [$yelp_name] are not similar enough\n";
	}
    }

    return 0;
}



sub getYelpPage {
    my ($deal_url,$name,$phone,$yelp_request);
    if ($#_ == 2) { 
	$yelp_request = shift;
	$deal_url = shift;
	$name = shift;
    } else { die "Incorrect usage of getYelpPage\n"; }

    print "Yelp request: [$yelp_request]\n";
    my $filename = YELP_CACHE_DIRECTORY.md5_hex($yelp_request).".html";
    my $yelp_page;
    if (open(FILE, $filename)) {
	print "Getting from cache: [$filename]\n";
	my $line = <FILE>;
	
	while ($line = <FILE>) {
	    $yelp_page = $yelp_page.$line;
	}
	close(FILE);
    } else {
	print "Not in cache, downloading and inserting into cache: ".
	    "[$filename]\n";
	$yelp_page = get $yelp_request;
	if (defined($yelp_page)) {
	    open(FILE, ">$filename");
	    print FILE "$name,$deal_url,$yelp_request\n";
	    print FILE $yelp_page;
	    close(FILE);
	}
    }

    if (!defined($yelp_page)) {
	die "Couldn't obtain page for [$yelp_request]\n";
    }

    return $yelp_page;
}

sub createCacheDirectory {
    unless (-d YELP_CACHE_DIRECTORY) {
	mkdir(YELP_CACHE_DIRECTORY, 0777) || die "Couldn't create" . 
	    YELP_CACHE_DIRECTORY . "\n";
    }
}
