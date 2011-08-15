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
    use HTML::TreeBuilder;
    use Encode;

    my %company_to_extractor_map;

    $company_to_extractor_map{1} = \&GrouponURLExtractor;
    $company_to_extractor_map{2} = \&LivingSocialURLExtractor;
    $company_to_extractor_map{3} = \&BuyWithMeURLExtractor;
    $company_to_extractor_map{4} = \&TipprURLExtractor;
    $company_to_extractor_map{5} = \&TravelZooURLExtractor;
    $company_to_extractor_map{6} = \&AngiesListURLExtractor;
    $company_to_extractor_map{7} = \&GiltCityURLExtractor;
    $company_to_extractor_map{8} = \&YollarURLExtractor;
    $company_to_extractor_map{9} = \&ZoziURLExtractor;
    $company_to_extractor_map{10} = \&BloomspotURLExtractor;
    $company_to_extractor_map{11} = \&ScoutMobURLExtractor;
    $company_to_extractor_map{12} = \&AmazonLocalURLExtractor;

    sub extractDealURLs {
	if ($#_ != 2) { die "Incorrect usage of extractDealURLs, need 3 ".
			    "arguments\n"; }

	my $deal_properties_ref = shift;
	my $hub_content_ref = shift;
	my $hub_properties = shift;

	my $tree = HTML::TreeBuilder->new;
	$tree->parse(decode_utf8 $$hub_content_ref);
	$tree->eof();

	my @array = keys %{$deal_properties_ref};
	my $tmp_deal_properties_size = $#array;

	if (!defined($$hub_content_ref) || length($$hub_content_ref) == 0) {
	    die "Problem with ".$hub_properties->url()."\n";
	}


	if (defined($company_to_extractor_map{$hub_properties->company_id()}))
	{
	    &{$company_to_extractor_map{$hub_properties->company_id()}}
		($deal_properties_ref, $hub_content_ref, $hub_properties,
		 \$tree);
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

	$tree->delete();
	return $num_deals_extracted;
    }


    sub GenericRegexURLExtactor {
	my $deal_properties_ref = shift;
	my $content_ref = shift;
	my $hub_properties = shift;
	my $filter_url_params = shift;

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
	    if ($filter_url_params) {
		$match =~ s/\?[^\?]*$//;
	    }

	    if (length($negative_pattern) > 0) {
		if ($match !~ $negative_pattern) {
		    $uniq_matches{$match} = 1;
		}
	    } else {
		$uniq_matches{$match} = 1;
	    }
	}

	foreach my $match (keys %uniq_matches) {
	    my $url = $prepend_string.$match;
	    if (!defined($$deal_properties_ref{$url})) {
		$$deal_properties_ref{$url} = dealproperties->new();
	    }

	    ${$deal_properties_ref}{$url}->inherit_properties_from_hub(
		$url, $hub_properties);
	}
    }

    sub addToDealProperties {
	my $deal_properties_ref = shift;
	my $hub_properties = shift;
	my $url = shift;
	if (!defined($$deal_properties_ref{$url})) {
	    $$deal_properties_ref{$url} = dealproperties->new();
	}
	
	${$deal_properties_ref}{$url}->inherit_properties_from_hub(
	    $url, $hub_properties);
    }


    sub GrouponURLExtractor {
	&GenericRegexURLExtactor($_[0], $_[1], $_[2], 1,
				 "href=[\'\"](\/deals\/[^\'\"]+)[\'\" title=[\'\"[^\'\"]+[\'\"]",
				 "categories|set_location_sort",
				 "http://groupon.com");

	&GenericRegexURLExtactor($_[0], $_[1], $_[2], 1,
				 "href=[\'\"](\/ch\/[^\'\"]+)[\'\" title=[\'\"[^\'\"]+[\'\"]",
				 "categories|set_location_sort",
				 "http://groupon.com");
    }

    sub LivingSocialURLExtractor {
	# Must double escape the ? character!!
	&GenericRegexURLExtactor($_[0], $_[1], $_[2], 1,
				 "href=[\'\"](\/deals\/[0-9]+[^\\?]+)\\?msdc_id=[0-9]+[\'\"]",
				 "more_deals", "http://livingsocial.com");
    }

    sub BuyWithMeURLExtractor {
	&GenericRegexURLExtactor($_[0], $_[1], $_[2], 1,
				 "href=[\'\"](\/[A-Za-z]+\/deals\/[0-9]+[^\"\']+)[\"\']",
				 "", "http://www.buywithme.com");
    }

    sub TipprURLExtractor {
	&GenericRegexURLExtactor($_[0], $_[1], $_[2], 1,
				 "href=[\'\"](\/offer[^\"\']+)[\"\']",
				 "", "http://tippr.com");
    }

    sub TravelZooURLExtractor {
	&GenericRegexURLExtactor($_[0], $_[1], $_[2], 1,
				 "(http:\/\/www.travelzoo.com\/local-deals\/deal\/[0-9]+)",
				 "", "");
    }

    sub AngiesListURLExtractor {
	&GenericRegexURLExtactor($_[0], $_[1], $_[2], 0,
				 "href=[\'\"](http[s]?:\/\/my.angieslist.com\/thebigdeal\/default.aspx\\?itemid=[^\"\']+)",
				 "", "");
    }

    sub GiltCityURLExtractor {
	if (!$#_ == 3) { die "Incorrect usage of GiltCityURLExtractor.\n"; }
	my $deal_properties_ref = $_[0];
	my $hub_properties = $_[2];
	my $tree_ref = $_[3];
	
	my @deal_urls = ${$tree_ref}->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') =~ /^offer/)});
	foreach my $deal_url (@deal_urls) {
	    if ($deal_url->as_HTML() !~ /national=1/ &&
		$deal_url->as_HTML() =~ /href=[\'\"]([^\'\"]+)/) {
		my $url = "$1";
		if ($url !~ /^http/) {
		    $url = "http://www.giltcity.com".$url;
		}
		if (!defined($$deal_properties_ref{$url})) {
		    $$deal_properties_ref{$url} = dealproperties->new();
		}

		${$deal_properties_ref}{$url}->inherit_properties_from_hub(
		    $url, $hub_properties);
	    }
	}
    }


    sub YollarURLExtractor {
	if (!$#_ == 3) { die "Incorrect usage of GiltCityURLExtractor.\n"; }
	my $tree_ref = $_[3];
	
	my @deal_urls = ${$tree_ref}->look_down(
	    sub{$_[0]->tag() eq 'meta' && defined($_[0]->attr('property')) &&
		    ($_[0]->attr('property') eq "og:url")});

	if (@deal_urls && defined($deal_urls[0]->attr('content')) &&
	    $deal_urls[0]->attr('content') =~ /^http/) {
	    my $url = $deal_urls[0]->attr('content');
	    addToDealProperties($_[0], $_[2], $url);
	}
	
	@deal_urls = ${$tree_ref}->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq
		     "offer-view-concurrent-view-deal-button")});

	foreach my $deal (@deal_urls) {
	    if ($deal->as_HTML() =~ /href=[\'\"](\/offer\/[^\'\"]+)/) {
		addToDealProperties($_[0], $_[2], "http://yollar.com$1");
	    }
	}
	
    }

    sub ZoziURLExtractor {
	if (!$#_ == 3) { die "Incorrect usage of GiltCityURLExtractor.\n"; }
	my $tree_ref = $_[3];
	
	my @deal_urls = ${$tree_ref}->look_down(
	    sub{$_[0]->tag() eq 'a' && defined($_[0]->attr('href')) &&
		    ($_[0]->attr('href') =~ /^\/deals\/[0-9]+$/)});
	foreach my $deal (@deal_urls) {
	    addToDealProperties($_[0], $_[2], "http://www.zozi.com".
				$deal->attr('href'));
	}

	@deal_urls = ${$tree_ref}->look_down(
	    sub{$_[0]->tag() eq 'a' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') =~ /buy_now/)});
	if (@deal_urls && defined($deal_urls[0]->attr('href')) &&
	    $deal_urls[0]->attr('href') =~ /^(\/deals\/[0-9]+)/) {
	    addToDealProperties($_[0], $_[2], "http://www.zozi.com$1");
	}
    }

    sub BloomspotURLExtractor {
	if (!$#_ == 3) { die "Incorrect usage of GiltCityURLExtractor.\n"; }
	my $hub_properties = $_[2];
	my $tree_ref = $_[3];
	
	my @deal_urls = ${$tree_ref}->look_down(
	    sub{$_[0]->tag() eq 'a' && defined($_[0]->attr('href')) &&
		    ($_[0]->attr('href') =~ $hub_properties->url())});
	foreach my $deal (@deal_urls) {
	    if ($deal->as_text() eq "see offer") {
		addToDealProperties($_[0], $_[2], $deal->attr('href'));
	    }
	}
    }

    sub ScoutMobURLExtractor {
	if (!$#_ == 3) { die "Incorrect usage of GiltCityURLExtractor.\n"; }
	my $hub_properties = $_[2];
	my $tree_ref = $_[3];
	
	my @deal_urls = ${$tree_ref}->look_down(
	    sub{$_[0]->tag() eq 'a' && defined($_[0]->attr('href'))});
	foreach my $deal (@deal_urls) {
	    if ($deal->attr('href') =~ /^(\/[^\/]+\/deal\/[0-9]+)$/) {
		addToDealProperties($_[0], $_[2], "http://www.scoutmob.com$1");
	    }
	}
    }


    sub AmazonLocalURLExtractor {
	if (!$#_ == 3) { die "Incorrect usage of GiltCityURLExtractor.\n"; }
	my $hub_properties = $_[2];
	my $tree_ref = $_[3];
	
	my @deal_urls = ${$tree_ref}->look_down(
	    sub{$_[0]->tag() eq 'a' && defined($_[0]->attr('href')) &&
		    defined($_[0]->attr('class')) && 
		    $_[0]->attr('class') eq "deal_title"});

	if (@deal_urls) {
	    if ($deal_urls[0]->attr('href') =~ /^(\/.*)/) {
		addToDealProperties($_[0], $_[2], "http://local.amazon.com".
				    $deal_urls[0]->attr('href'));
	    }
	}
    }

    1;
}
