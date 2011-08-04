#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package dealurlextractor;
    
    use strict;
    use warnings;
    use hub;
    use dealproperties;
    use logger;

    my %company_to_extractor_map;

    $company_to_extractor_map{1} = \&GrouponURLExtractor;
    $company_to_extractor_map{2} = \&LivingSocialURLExtractor;
    $company_to_extractor_map{3} = \&BuyWithMeURLExtractor;
    $company_to_extractor_map{4} = \&TipprURLExtractor;

    sub extractDealURLs {
	if ($#_ != 2) { die "Incorrect usage of extractDealURLs, need 3 ".
			    "arguments\n"; }

	my $deal_properties_ref = shift;
	my $hub_content_ref = shift;
	my $hub_properties = shift;

	my @array = keys %{$deal_properties_ref};
	my $tmp_deal_properties_size = $#array;

	if (!defined($$hub_content_ref) || length($$hub_content_ref) == 0) {
	    die "Problem with ".$hub_properties->url()."\n";
	}


	if (defined($company_to_extractor_map{$hub_properties->company_id()}))
	{
	    &{$company_to_extractor_map{$hub_properties->company_id()}}
		($deal_properties_ref, $hub_content_ref, $hub_properties);
	} else {
	    logger::LOG("No deal url extractor registered for company_id : ".
			$hub_properties->company_id(), 0);
	}

	@array = keys %{$deal_properties_ref};
	my $num_deals_extracted = $#array - $tmp_deal_properties_size;

	if ($num_deals_extracted == 0) {
	    logger::LOG("No new deal urls extracted from hub : " .
			$hub_properties->url(), 1);
	} else {
	    logger::LOG("$num_deals_extracted deal links extracted from hub: ".
			$hub_properties->url(), 3);
	}

	return $num_deals_extracted;
    }


    sub GenericRegexURLExtactor {
	my $deal_properties_ref = shift;
	my $content_ref = shift;
	my $hub_properties = shift;
	my $pattern = shift;
	my $negative_pattern = shift;
	my $prepend_string = "";
	if (@_) { $prepend_string = shift; }
	
	my $regex = eval { qr/$pattern/ };
	if (!defined($regex)) {
	    die "Error in regular expression: $pattern\n$@\n";
	}

	my @matches;
	my %uniq_matches;

	push (@matches, ($$content_ref =~ /$regex/g));

	# Normalize and filter negative matches
	foreach my $match (@matches) {
	    $match =~ s/\?[^\?]*$//;

	    if (length($negative_pattern) > 0) {
		if ($match !~ $negative_pattern) {
		    $uniq_matches{$match} = 1;
		}
	    } else {
		$uniq_matches{$match} = 1;
	    }
	}

	foreach my $match (keys %uniq_matches) {
	    my $deal_properties;
	    my $url = $prepend_string.$match;
	    if (!defined($$deal_properties_ref{$url})) {
		$$deal_properties_ref{$url} = dealproperties->new();
	    }

	    ${$deal_properties_ref}{$url}->inherit_properties_from_hub(
		$url, $hub_properties);
	}
    }


    sub GrouponURLExtractor {
	&GenericRegexURLExtactor($_[0], $_[1], $_[2],
				 "href=[\'\"](\/deals\/[^\'\"]+)[\'\" title=[\'\"[^\'\"]+[\'\"]",
				 "categories", "http://groupon.com");

	&GenericRegexURLExtactor($_[0], $_[1], $_[2],
				 "href=[\'\"](\/ch\/[^\'\"]+)[\'\" title=[\'\"[^\'\"]+[\'\"]",
				 "categories", "http://groupon.com");
    }

    sub LivingSocialURLExtractor {
	# Must double escape the ? character!!
	&GenericRegexURLExtactor($_[0], $_[1], $_[2],
				 "href=[\'\"](\/deals\/[0-9]+[^\\?]+)\\?msdc_id=[0-9]+[\'\"]",
				 "", "http://livingsocial.com");
    }

    sub BuyWithMeURLExtractor {
	&GenericRegexURLExtactor($_[0], $_[1], $_[2],
				 "href=[\'\"](\/[A-Za-z]+\/deals\/[0-9]+[^\"\']+)[\"\']",
				 "", "http://www.buywithme.com");
    }

    sub TipprURLExtractor {
	&GenericRegexURLExtactor($_[0], $_[1], $_[2],
				 "href=[\'\"](\/offer[^\"\']+)[\"\']",
				 "", "http://tippr.com");
    }

    1;
}
