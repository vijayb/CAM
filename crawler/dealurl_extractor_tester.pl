#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
# Provides a way to instrument dealurlextractor.pm for testing purposes.
{
    use strict;
    use warnings;
    use hub;
    use dealproperties;
    use dealurlextractor;

    use Getopt::Long qw(GetOptionsFromArray);

    my %domain_to_id_map;
    
    # In the crawler the company_id() for a hub is obtained from the
    # database. Since dealurl_extractor_tester.pl won't have the hub
    # in offline mode, the way to specify the company_id is by
    # manually mapping the domain of the website to its company_id()
    # To test new dealurlextractors add to the domain map below.  The
    # additions should correspond to the map in dealurlextractor.pm
    $domain_to_id_map{"http://groupon.com"} = 1;
    $domain_to_id_map{"http://www.groupon.com"} = 1;
    $domain_to_id_map{"http://livingsocial.com"} = 2;
    $domain_to_id_map{"http://www.livingsocial.com"} = 2;
    $domain_to_id_map{"http://buywithme.com"} = 3;
    $domain_to_id_map{"http://www.buywithme.com"} = 3;
    $domain_to_id_map{"http://tippr.com"} = 4;
    $domain_to_id_map{"http://www.tippr.com"} = 4;
    $domain_to_id_map{"https://www.tippr.com"} = 4;
    $domain_to_id_map{"https://tippr.com"} = 4;


    my ($hub_directory, $company_id, $hub_file);
    my ($verbose, $skiperrors, $numerrors, $numwarnings, $total_hub_pages);

    my $result = GetOptionsFromArray(\@ARGV,
				     "directory=s" => \$hub_directory,
				     "company_id=i" => \$company_id,
				     "file=s" => \$hub_file,
				     "verbose=i" => \$verbose,
				     "skiperrors=i" => \$skiperrors);

    if (!defined($verbose)) { $verbose = 0; }
    if (!defined($skiperrors)) { $skiperrors = 0; }
    $numerrors = 0;
    $numwarnings = 0;
    $total_hub_pages = 0;

    if (defined($hub_directory)) {
	my $list_cmd = "find ".$hub_directory." -mindepth 1 -maxdepth 1";
	my @hub_files = `$list_cmd`;

	foreach my $hub_file (@hub_files) {
	    extractDealLinks($hub_file);
	}
    } elsif (defined($hub_file)) {
	extractDealLinks($hub_file);
    } else {
	die "Error: you need to specify a directory containing hubs using ".
	    "--directory=... or you need to specify a hub file using ".
	    "--file=...\n";
    }

    print "Total hubs pages : $total_hub_pages\n";
    print "Total errors     : $numerrors\n";
    print "Total warnings   : $numwarnings\n";

    sub extractDealLinks {
	my $file = shift;
	chomp($file);
	my $filehandle;
	    
	if (open($filehandle, $file)) {
	    my $url;
	    my $timestamp;
	    my $content;
	    my $domain;
	    
	    # First line in a cache entry will be a timestamp
	    # and the url for the content that follows in
	    # subsequent lines. They will be comma separated.
	    # E.g., 1310258023,http://tippr.com/seattle/
	    my $line = <$filehandle>;
	    if (defined($line) &&
		$line =~ /^([0-9]+),(.+)$/) {
		$timestamp = $1 + 0;
		$url = $2;

		while ($line=<$filehandle>) {
		    $content = $content.$line;
		}

		if ($url =~ /(http[s]?:\/\/[^\/]+)/ &&
		    defined($domain_to_id_map{$1})) {
		    $domain = $1;
		} else {
		    dieN("Couldn't extract domain from: [$url] or domain ".
			"has no id mapping.\n");
		}

		if (defined($company_id) &&
		    $domain_to_id_map{$domain} != $company_id) {
		    return;
		}

		my $hub = hub->new();
		$hub->url($url);
		$hub->company_id($domain_to_id_map{$domain});
		
		my %deal_properties;

		&dealurlextractor::extractDealURLs(\%deal_properties,
						   \$content, $hub);


		my $num_links_extracted = scalar(keys(%deal_properties));
		if ($num_links_extracted > 0) {
		    printV("$num_links_extracted deal links extracted from ".
			   "[$url]\n", 1);
		} else {
		    dieN("No deal links extracted from [$url]\n");
		}
		
		foreach my $dealurl (keys %deal_properties) {
		    printV("      [".$dealurl."]\n", 2);
		}

		$total_hub_pages++;
	    }
	    close($filehandle);
	}
    }

    sub dieN {
	$numerrors++;
	if (@_) {
	    my ($message) = shift;
	    print $message;

	    if ($numerrors <= $skiperrors) {
		print "Num errors $numerrors, skipping this error\n";
	    } else {
		die;
	    }
	}
    }

    sub warnN {
	$numwarnings++;
	if (@_) {
	    my ($message) = shift;
	    print $message;
	}
    }

    sub printV {
	if ($#_ != 1) { die "Error using printV\n"; }

	my $message = shift;
	my $print_level = 0 + shift;

	if ($print_level <= $verbose) {
	    print $message;
	}
    }

    1;
}


