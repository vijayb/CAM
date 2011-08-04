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

use constant {
    MAX_DAYS => 2,
    YELP_CACHE_DIRECTORY => "./yelp_cache/",
    YELP_ID => "wu6Vp9sa7z62Wpv7H-7GwA"
};

&createCacheDirectory();

my ($webserver, $database, $user, $password);
getargs::get(\$webserver, \$database, \$user, \$password);

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


	    if (defined($deals_successfully_reviewed{$deal_url})) {
		print "Already got yelp review for [$deal_url], skipping.\n\n";
		next;
	    }

	    print "Deal: [$deal_url]\n";
	    my ($yelp_page, %json, @businesses);

	    # First try find yelp review by looking up phone number:
	    #
	    if (defined($phone) && length($phone) >=9) {
		my $yelp_request =
		    "http://api.yelp.com/phone_search?phone=$phone".
		    "&ywsid=".YELP_ID;
    
		$yelp_page = getYelpPage($yelp_request, $deal_url, $name);
		%json = %{$json_coder->decode($yelp_page)};
		@businesses = @{$json{"businesses"}};
		print "".($#businesses+1)." businesses found\n";
		if (checkBusinessesForMatch($name, $deal_url, \@businesses)) {
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
		
		$yelp_page = getYelpPage($yelp_request, $deal_url, $name);
		%json = %{$json_coder->decode($yelp_page)};
		@businesses = @{$json{"businesses"}};

		print "".($#businesses+1)." businesses found\n";
		if (checkBusinessesForMatch($name, $deal_url, \@businesses)) {
		    print "\n\n\n";
		    next;
		}
	    }


	    # If the lat-long didn't work, we may have an area that is
	    # dense with businesses. Since yelp only returns 20 results
	    # we can try combining the lat-long with the business name
	    # to see if that gets a match. When using the business name
	    # we can relax the search radius a bit to 1 mile.
	    #
	    if(defined($latitude) && length($latitude) >0 &&
	       defined($longitude) && length($longitude) >0) {
		my $modified_name = $name;
		$modified_name =~ s/\s+/%20/g;
		$modified_name =~ s/[^A-Za-z'%0-9]//g;
		
		my $yelp_request =
		    "http://api.yelp.com/business_review_search?".
		    "term=$modified_name".
		    "&lat=$latitude&long=$longitude&radius=1&limit=20".
		    "&ywsid=".YELP_ID;
		
		$yelp_page = getYelpPage($yelp_request, $deal_url, $name);
		%json = %{$json_coder->decode($yelp_page)};
		@businesses = @{$json{"businesses"}};
		print "".($#businesses+1)." businesses found\n";
		if (checkBusinessesForMatch($name, $deal_url, \@businesses)) {
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
    my $name = shift;
    my $deal_url = shift;
    my $businesses_ref = shift;

    foreach my $business (@{$businesses_ref}) {
	my $yelp_name = ${$business}{"name"};
	my $yelp_rating = ${$business}{"avg_rating"};
	my $yelp_url = ${$business}{"url"};
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
	if (similarEnough($yelp_name, $name)) {
	    print "[$yelp_name] and [$name] are similar enough\n";
	    my %post_form;
	    
	    $post_form{"url"} = $deal_url;
	    if (defined($yelp_rating)) {
		$post_form{"yelp_rating"} = $yelp_rating;
	    }
	    if (defined($yelp_url)) {
		$post_form{"yelp_url"} = $yelp_url;
	    }
	    if (defined($yelp_categories)) {
		$post_form{"yelp_categories"} = $yelp_categories;
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



sub similarEnough {
    if ($#_ != 1) { die "Incorrect usage of similarEnough\n"; }
    my $s1 = shift;
    my $s2 = shift;
    my $long;
    my $short;

    if (length($s1)> length($s2)) {
	$long = $s1;
	$short = $s2;
    } else {
	$long = $s2;
	$short = $s1;
    }

    my $edit_distance = editDistance($short, $long);

    my $score = (1.0*$edit_distance)/(1.0*length($long));
    my $threshold = 0.1 + length($long)/100.0;

    # If similar enough based on edit distance:
    if ($score <= $threshold) {
	return 1;
    } 

    if (length($short) > 5 && $long =~ $short) {
	return 1;
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



# Return the Levenshtein distance (also called Edit distance) 
# between two strings
#
# The Levenshtein distance (LD) is a measure of similarity between two
# strings, denoted here by s1 and s2. The distance is the number of
# deletions, insertions or substitutions required to transform s1 into
# s2. The greater the distance, the more different the strings are.
#
# The algorithm employs a proximity matrix, which denotes the distances
# between substrings of the two given strings. Read the embedded comments
# for more info. If you want a deep understanding of the algorithm, print
# the matrix for some test strings and study it
#
# The beauty of this system is that nothing is magical - the distance
# is intuitively understandable by humans
#
# The distance is named after the Russian scientist Vladimir
# Levenshtein, who devised the algorithm in 1965
#
sub editDistance
{
    # $s1 and $s2 are the two strings
    # $len1 and $len2 are their respective lengths
    #
    my ($s1, $s2) = @_;
    my ($len1, $len2) = (length $s1, length $s2);

    # If one of the strings is empty, the distance is the length
    # of the other string
    #
    return $len2 if ($len1 == 0);
    return $len1 if ($len2 == 0);

    my %mat;

    # Init the distance matrix
    #
    # The first row to 0..$len1
    # The first column to 0..$len2
    # The rest to 0
    #
    # The first row and column are initialized so to denote distance
    # from the empty string
    #
    for (my $i = 0; $i <= $len1; ++$i)
    {
        for (my $j = 0; $j <= $len2; ++$j)
        {
            $mat{$i}{$j} = 0;
            $mat{0}{$j} = $j;
        }

        $mat{$i}{0} = $i;
    }

    # Some char-by-char processing is ahead, so prepare
    # array of chars from the strings
    #
    my @ar1 = split(//, $s1);
    my @ar2 = split(//, $s2);

    for (my $i = 1; $i <= $len1; ++$i)
    {
        for (my $j = 1; $j <= $len2; ++$j)
        {
            # Set the cost to 1 iff the ith char of $s1
            # equals the jth of $s2
            # 
            # Denotes a substitution cost. When the char are equal
            # there is no need to substitute, so the cost is 0
            #
            my $cost = ($ar1[$i-1] eq $ar2[$j-1]) ? 0 : 1;

            # Cell $mat{$i}{$j} equals the minimum of:
            #
            # - The cell immediately above plus 1
            # - The cell immediately to the left plus 1
            # - The cell diagonally above and to the left plus the cost
            #
            # We can either insert a new char, delete a char or
            # substitute an existing char (with an associated cost)
            #
            $mat{$i}{$j} = min([$mat{$i-1}{$j} + 1,
                                $mat{$i}{$j-1} + 1,
                                $mat{$i-1}{$j-1} + $cost]);
        }
    }

    # Finally, the Levenshtein distance equals the rightmost bottom cell
    # of the matrix
    #
    # Note that $mat{$x}{$y} denotes the distance between the substrings
    # 1..$x and 1..$y
    #
    return $mat{$len1}{$len2};
}


# minimal element of a list
#
sub min
{
    my @list = @{$_[0]};
    my $min = $list[0];

    foreach my $i (@list)
    {
        $min = $i if ($i < $min);
    }

    return $min;
}
