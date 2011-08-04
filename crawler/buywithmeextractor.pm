#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package buywithmeextractor;
    
    use strict;
    use warnings;
    use deal;
    use genericextractor;
    use logger;

    my %month_map = (
	"Jan" => 1,
	"Feb" => 2,
	"Mar" => 3,
	"Apr" => 4,
	"May" => 5,
	"Jun" => 6,
	"Jul" => 7,
	"Aug" => 8,
	"Sep" => 9,
	"Oct" => 10,
	"Nov" => 11,
	"Dec" => 12
    );

    sub extract {
	my $deal = shift;
	my $deal_content_ref = shift;

	# BuyWithMe doesn't provide this information on its pages
	$deal->num_purchased(-1);

	my $title = &genericextractor::extractBetweenPatternsN(
	    5, $deal_content_ref, "<span\\s+id=[\'\"]main_title_span",
	    "<div");
	if (defined($title) &&
	    $title =~ /<h1>([^<]+)<\/h1>/) {
	    $deal->title($1);  
	}

	my $subtitle_regex = "main_title_span[\'\"][^>]+>([^<]+)<";
	my $subtitle = &genericextractor::extractFirstPatternMatched(
	    $deal_content_ref, $subtitle_regex);
	$deal->subtitle($subtitle);

	my $price = &genericextractor::extractBetweenPatternsN(
	    2, $deal_content_ref, "id=[\'\"]main_price_text", "<div");
	if (defined($price) &&
	    $price =~ /\$([0-9]*\.?[0-9]+)/) {
	    $deal->price($1);  
	} else {
	    my $price = &genericextractor::extractFirstPatternMatched(
	    $deal_content_ref, "pack_price[^\\\$]+\\\$([0-9]*\.[0-9]+)");
	    if (defined($price)) {
		$deal->price($price);  
	    }
	}

	my $value = &genericextractor::extractBetweenPatternsN(
	    3, $deal_content_ref, "id=[\'\"]value_display", "<\/div");
	if (defined($value) &&
	    $value =~ /\$([0-9]*\.?[0-9]+)/) {
	    $deal->value($1);  
	} else {
	    my $value = &genericextractor::extractBetweenPatternsN(
		3, $deal_content_ref, "pack_price", "pack_price");
	    if (defined($value) &&
		$value =~ /[Ss]avings:\s+\$([0-9]*\.?[0-9]+)/) {
		$deal->value($1);  
	    }
	}

	my $expired_regex = "<div\\s+class=[\'\"]deal_over";
	if (&genericextractor::containsPattern($deal_content_ref,
					       $expired_regex))
	{
	    $deal->expired(1);
	}


	if (!defined($deal->expired()) && !$deal->expired()) {
	    my $deadline_regex = "<div\\s+class=[\'\"]tri_box\\s+timer[\'\"]\\s+title=[\'\"]([^\'\"]+)";
	    my $deadline = &genericextractor::extractFirstPatternMatched(
		$deal_content_ref, $deadline_regex);

	    if (defined($deadline) && 
		$deadline =~ /[a-zA-Z]+\s+([a-zA-Z]+)\s+([0-9][0-9]?)\s+([0-9][0-9]:[0-9][0-9]:[0-9][0-9])\s+UTC\s+([0-9]{4})/) {
		my $month = $1;
		my $year = $4;
		my $day = $2;
		my $timestamp = $3;
		if (defined($month_map{$month})) {
		    $deadline = sprintf("%d-%02d-%02d %s",
					$year, $month_map{$month}, $day,
					$timestamp);
		    $deal->deadline($deadline);  
		}
	    }
	}

	my $expires = &genericextractor::extractBetweenPatternsN(
	    5, $deal_content_ref, "<h4>Deal Terms", "<\/div");

	if (defined($expires)) {
	    $expires =~ s/[^0-9]+$//;
	    if ($expires =~ /([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{4})$/) {
		my $day = $2;
		my $month = $1;
		my $year = $3;
		$expires = sprintf("%d-%02d-%02d %s", $year, $month, $day,
				   "01:01:01");
		$deal->expires($expires); 
	    }
	}

	my $image_url_regex = 
	    "id=[\'\"]main_asset[\'\"]\\s+src=[\'\"]([^\'\">]+)";
	my $image_url = &genericextractor::extractFirstPatternMatched(
	    $deal_content_ref, $image_url_regex);
	if (defined($image_url)) {
	    $image_url =~ s/\?.*$//;
	    $deal->image_url("http://buywithme.com$image_url"); 
	}

	my $text = &genericextractor::extractBetweenPatterns(
	    $deal_content_ref, "<div\\s+id=[\'\"]short_description",
	    "<h[0-9]>Deal\\s+Terms", "<\\/?div[^>]*>",
	    "<p\\s+class=[\'\"]link[\'\"]>[^<]*<\\/p>", "^\\s*", "\\s*\$");
	if (defined($text)) {
	    $deal->text($text);
	}

	my $fine_print = &genericextractor::extractBetweenPatternsN(
	    5, $deal_content_ref, "<h4>Deal Terms", "</div", "\\r",
	    "^\\s*", "\\s*\$");
	if (defined($fine_print)) { $deal->fine_print($fine_print); }



	my $name = &genericextractor::extractBetweenPatternsN(
	    3, $deal_content_ref, "<div\\s+id=[\'\"]dealSpot", "</div>");
	if (defined($name) && $name =~ /<em>([^<]+)/) {
	    $name = $1;
	    $name =~ s/^\s+//;
	    $name =~ s/\s+$//;
	    $deal->name($name);
	}

	if (defined($deal->name())) {
	    my $deal_name = $deal->name();
	    $deal_name =~ s/&/&amp;/;
	    $deal_name =~ s/'/&rsquo;/;
	    $deal_name =~ s/’/&rsquo;/;

	    my $website_regex = 
		"href=[\'\"]([^\'\"]+)[\'\"][^>]*>[^>]*.?".$deal_name;
	    
	    if (defined($deal->text()) && $deal->text() =~ $website_regex) {
		$deal->website($1);
	    }
	}

	
	my $address_text = &genericextractor::extractBetweenPatterns(
	    $deal_content_ref, "<div\\s+id=[\'\"]dealSpot", "</div>");

	if (defined($address_text)) {
	    # Extract at most 10 addresses
	    my @addresses = &genericextractor::extractMPatterns(
		10, \$address_text, "<li>([^<]+)");
	    if ($#addresses >= 0) {
		foreach my $address (@addresses) {
		    if ($address =~ /\s([A-Za-z]+),?\s+([0-9]{5})/ &&
			&genericextractor::isState($1)) {
			$deal->addresses($address);
		    }
		}
	    }


	}
    }



    1;
}
