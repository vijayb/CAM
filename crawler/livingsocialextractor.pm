#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package livingsocialextractor;

    use strict;
    use warnings;
    use deal;
    use genericextractor;
    use crawlerutils;

    my %month_map = (
	"January" => 1,
	"February" => 2,
	"March" => 3,
	"April" => 4,
	"May" => 5,
	"June" => 6,
	"July" => 7,
	"August" => 8,
	"September" => 9,
	"October" => 10,
	"November" => 11,
	"December" => 12
    );

    sub extract {
	my $deal = shift;
	my $deal_content_ref = shift;


	my $title = &genericextractor::extractBetweenPatternsN(
	    3, $deal_content_ref, "<div\\s+class=[\'\"]deal-title[\'\"]>",
	    "<\\/div>");
	if (defined($title) && $title =~ /<h1>([^<]+)<\/h1>/) {
	    $title = $1;
	    $title =~ s/^\s+|\s+$//g;
	    $deal->title($title);
	}

	my $subtitle = &genericextractor::extractBetweenPatternsN(
	    3, $deal_content_ref, "<div\\s+class=[\'\"]deal-title[\'\"]>",
	    "<\\/div>");
	if (defined($subtitle) && $subtitle =~ /<p>([^<]+)<\/p>/) {
	    $deal->subtitle($1);
	}

	my $price = &genericextractor::extractBetweenPatternsN(
	    3, $deal_content_ref, "<div\\s+class=[\'\"]deal-price",
	    "<\\/div>", "<[^>]*>", "\\\$", "\\s+");
	if (defined($price) && $price =~ /^([0-9]*\.?[0-9]+)$/) {
	    $deal->price($1);
	}

	# LivingSocial doesn't directly give us the value, only
	# the discount percentage. We have to infer the value.
	if (defined($deal->price())) {
	    my $value = &genericextractor::extractBetweenPatternsN(
	    5, $deal_content_ref, "<div\\s+class=[\'\"]value",
	    "<\\/div>", "<[^>]*>");
	    if (defined($value) && $value =~ /([1-9][0-9]?)%/) {
		my $percent = $1/100.0;
		$value = sprintf("%.0f", $deal->price()/(1.0-$percent));
		$deal->value($value);
	    }
	}

	my $num_purchased = &genericextractor::extractBetweenPatternsN(
	    5, $deal_content_ref, "<li\\s+class=[\'\"]purchased",
	    "purchased", "<[^>]*>", "\\s+", ",");
	if (defined($num_purchased) && $num_purchased =~ /^([0-9]+)/) {
	    $deal->num_purchased($1);
	}

	if (&genericextractor::containsPattern(
		 $deal_content_ref,
		 "class=[\'\"]button\\s+buy-sold-out[\'\"]>sold\\s+out") ||
	    &genericextractor::containsPattern(
		 $deal_content_ref,
		 "class=[\'\"]button\\s+buy-sold-out[\'\"]>deal\\s+over"))
	{
	    $deal->expired(1);
	}
	
	if (!defined($deal->expired()) && !$deal->expired()) {
	    my $deadline = &genericextractor::extractBetweenPatternsN(
		10, $deal_content_ref,
		"<div\\s+id=[\'\"]countdown[\'\"]>", "<\\/div>",
		"<[^>]*>", "\\s+");

	    if (!defined($deadline)) {
		$deadline = &genericextractor::extractBetweenPatternsN(
		50, $deal_content_ref,
		    "<ul\\s+class=[\'\"]clearfix\\s+deal-info", "remaining",
		    "<[^>]*>", "\\s+");
	    }

	    my $days = 0;
	    my $hours = 0;
	    my $minutes = 0;
	    my $seconds = 0;
	    my $deadline_offset = 0;
	    # LivingSocial only gives us a countdown timer, not a date,
	    # so we have to infer it. It is either has the format
	    # "N days remaining" or e.g., 15:27:55 remaining.
	    # We compute the UTC time by adding the above countdown offset
	    # to the current UTC time. The greater the time between
	    # crawling the page and performing this calculation, the more
	    # inaccurate will be the computed deadline. But hopefully
	    # it won't be off by more than a few seconds.
	    if (defined($deadline)) {
		if ($deadline =~ /([0-9]{1,2})days?/) {
		    $days = $1;
		} elsif ($deadline =~ /([0-9]{2}):([0-9]{2}):([0-9]{2})/) {
		    $hours = $1;
		    $minutes = $2;
		    $seconds = $3;
		}
		$deadline_offset = ($days*24*60*60)+($hours*60*60)+
		    ($minutes*60) + $seconds;
		
		if ($deadline_offset > 0) {
		    $deadline = crawlerutils::gmtNow($deadline_offset);
		    $deal->deadline($deadline);
		}
	    }
	}


	my $expires = &genericextractor::extractBetweenPatterns(
	    $deal_content_ref, "<div\\s+class=[\'\"]fine-print",
	    "<\\/div>", "<[^>]+>", "\\s+\$");

	if (defined($expires)) {

	    if ($expires =~ /([A-Z][a-z]+)\s+([0-9]{1,2}),\s+([0-9]{4})$/) {
		my $month = $1;
		my $day = $2;
		my $year = $3;
		if (defined($month_map{$month})) {
		    $expires = sprintf("%d-%02d-%02d 01:01:01",
				       $year, $month_map{$month}, $day);
		    
		    $deal->expires($expires);
		}
	    }
	}


	my $image_url_regex = "alpha\\s+portrait(.*)";
	my $image_url = &genericextractor::extractFirstPatternMatched(
	    $deal_content_ref, $image_url_regex);
	if (defined($image_url) &&
	    $image_url =~ /url\((http:\/\/[^\)\s]+)/) {
	    $deal->image_url($1);
	}


	my $text = &genericextractor::extractBetweenPatternsN(
	    5, $deal_content_ref,
	    "<div\\s+class=[\'\"]deal-description[\'\"]>",
	    "<div\\s+class=[\'\"]deal-description[\'\"]>",
	    "<\\/?div[^>]*>",
	    "<a\\s+class=[\'\"]sfwt[^>]*>[^<]*<\\/a>",
	    "^\\s+", "\\s+\$");
	if (defined($text)) {
	    $text =~ s/\r//g;
	    $deal->text($text);
	}

	my $fine_print = &genericextractor::extractBetweenPatterns(
	    $deal_content_ref, "<div\\s+class=[\'\"]fine-print",
	    "<\\/div>", "<h2[^<]+<\\/h2>", "<\\/?a[^>]*>", "^\\s+", "\\s+\$");
	if (defined($fine_print)) {
	    $fine_print =~ s/\r//g;
	    $deal->fine_print($fine_print);
	}

	# Get both the name and website in one go.
	if (defined($deal->title())) {
	    my $website_regex = 
		"href=[\'\"]([^\'\"]+)[\'\"][^>]*>".$deal->title();
	    if (defined($deal->text()) && $deal->text() =~ $website_regex) {
		$deal->website($1);
		$deal->name($deal->title());
	    }
	}

	# Extract at most 10 addresses
	my @addresses = &genericextractor::extractMBetweenPatternsN(
	    10, 15, $deal_content_ref, "<li\\s+class=[\'\"]address[\'\"]",
	    "<span\\s+class=[\'\"]directions");
	if ($#addresses >= 0) {
	    foreach my $address (@addresses) {
		# TODO: figure out how to do with living social's first line
		# in address. Sometimes contains street. Sometimes business
		# name. sigh.
		#"<span\\s+class=[\'\"]street_1[\'\"][^<]+"
		$address =~ s/<[^>]+>/ /g;
		$address =~ s/\s+/ /g;
		$address =~ s/\s+$//;
		$address =~ s/^\s+//;
		
		if ($address =~ /\s([A-Za-z]{2})\s+([0-9]{5})/ &&
		    &genericextractor::isState($1)) {
		    my $zip = $2;
		    $address =~ s/$zip(.*)/$zip/;
		    $deal->addresses($address);
		}
	    }
	}

	
	my $phone_regex = "span\\s+class=[\'\"]phone[\'\"]>([^<]+)";
	my $phone = &genericextractor::extractFirstPatternMatched(
	    $deal_content_ref, $phone_regex);
	if (defined($phone) &&
	    $phone =~ /([0-9]{3})[^0-9]{1,2}([0-9]{3})[^0-9]{1}([0-9]{4})/) {
	    $deal->phone("$1-$2-$3");
	}

    }

    1;
}
