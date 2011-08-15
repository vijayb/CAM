#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package grouponextractor;
    
    use strict;
    use warnings;
    use deal;
    use genericextractor;
    use HTML::TreeBuilder;
    use Encode;

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
	my $tree = HTML::TreeBuilder->new;
	my $deal = shift;
	my $deal_content_ref = shift;
	
	$tree->parse(decode_utf8 $$deal_content_ref);
	$tree->eof();

	my $title_regex = "(<h2><a href.*)";
	my $title_filter = "<[^>]+>";
	my $title = &genericextractor::extractFirstPatternMatched(
	    $deal_content_ref, $title_regex, $title_filter);
	$deal->title($title);

	my $subtitle_regex = "(<h3\\s+class=[\'\"]subtitle[\'\"]>.*)";
	my $subtitle_filter = "<[^>]+>";
	my $subtitle = &genericextractor::extractFirstPatternMatched(
	    $deal_content_ref, $subtitle_regex, $subtitle_filter);
	$deal->subtitle($subtitle);

	my $price_regex = "(<span\\s+class=[\'\"]price[\'\"].*)";
	my $price_filter = "<[^>]+>";
	my $price = &genericextractor::extractFirstPatternMatched(
	    $deal_content_ref, $price_regex, $price_filter, "\\\$");
	if (defined($price) && $price =~ /([0-9,]*\.?[0-9]+)/) {
	    $price = $1;
	    $price =~ s/,//g;
	    $deal->price($price);  
	}

	my $value_regex = "<dd>([^<]+)";
	my $value = &genericextractor::extractFirstPatternMatched(
	    $deal_content_ref, $value_regex);
	if (defined($value) && $value =~ /([0-9,]*\.?[0-9]+)/) {
	    $value = $1;
	    $value =~ s/,//g;
	    $deal->value($value);  
	}

	my $expired_regex1 = "<h5>This\\s+deal\\s+ended";
	my $expired_regex2 = "<h5>This\\s+deal\\s+sold\\s+out";
	if (&genericextractor::containsPattern($deal_content_ref,
					       $expired_regex1) ||
	    &genericextractor::containsPattern($deal_content_ref,
					       $expired_regex2))
	{
	    $deal->expired(1);
	}


	if (!defined($deal->expired()) && !$deal->expired()) {
	    my $deadline_regex = "data-value=[\'\"]([^\'\"]+)[\'\"]\\s+id=[\'\"]deal_deadline";
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

	my $expires_regex = "Expires(.*)";
	my $expires = &genericextractor::extractFirstPatternMatched(
	    $deal_content_ref, $expires_regex);
	my ($year, $month, $day);
	if (defined($expires)) {
	    if ($expires =~ /([a-zA-Z]+)\s+([0-9]{1,2}),\s+([0-9]{4})/) {
		$day = $2;
		$month = $1;
		$year = $3;
		if (defined($month_map{$month})) {
		    $expires = sprintf("%d-%02d-%02d 01:01:01",
				       $year, $month_map{$month}, $day);
		    $deal->expires($expires);  
		}
	    } elsif ($expires =~ /in 1 year/) {
		($year, $month, $day) =
		    (localtime(time()+365*24*60*60))[5,4,3];
		$year += 1900;
		$expires = sprintf("%d-%02d-%02d 01:01:01",
				   $year, $month+1, $day);
		$deal->expires($expires);
	    }
	}

	my $text = &genericextractor::extractBetweenPatterns(
	    $deal_content_ref, "<div\\s+class=[\'\"]pitch_content[\'\"]",
	    "<\\\/div>");
	$deal->text($text);  

	my $fine_print = &genericextractor::extractBetweenPatterns(
	    $deal_content_ref, "The Fine Print<\\\/h3>",
	    "<\\\/div>", "^\\s+");
	if (defined($fine_print)) {
	    # Make relative URLs absolute:
	    $fine_print =~ s/<a href="\//<a href="http:\/\/groupon.com\//g;
	    $fine_print =~ s/<a href='\//<a href='http:\/\/groupon.com\//g;
	}
	$deal->fine_print($fine_print);  

	my $image_url = &genericextractor::extractBetweenPatternsN(
	    5,
	    $deal_content_ref,
	    "<div\\s+class=[\'\"]photos[\'\"]\\s+id=[\'\"]everyscape[\'\"]",
	    "<\\\/div>");
	if (defined($image_url) &&
	    $image_url =~ /src=[\'\"](http:\/\/[^\'\"\?<]+)/) {
	    $deal->image_url($1);  
	}

	my $num_purchased = &genericextractor::extractBetweenPatternsN(
	    3, $deal_content_ref, "number_sold_container", "obfuscate",
	    "<[^>]+>", "\\s", ",", "bought");
	if (defined($num_purchased)) {
	    if ($num_purchased =~ /^[0-9]+$/) {
		$deal->num_purchased($num_purchased);
	    } elsif ($num_purchased =~ /first/ &&
		     $num_purchased =~ /buy/) {
		$deal->num_purchased(0);
	    }
	}


	my @name = $tree->look_down(
	    sub{$_[0]->tag() eq 'h3' && defined($_[0]->attr('class')) &&
		    $_[0]->attr('class') eq "name"});
	if (@name) {
	    $deal->name($name[0]->as_text());
	}


	my @website = $tree->look_down(
	    sub{$_[0]->tag() eq 'a' && defined($_[0]->attr('href')) &&
		    $_[0]->as_text() =~ /company\s+website/i});
	if (@website && $website[0]->attr('href') =~ /^http/) {
	    $deal->website($website[0]->attr('href'));
	}


	my $no_address_regex =
	    "class=[\'\"]bold\\s+location_note[\'\"]>[Rr]edeem";
	if (!&genericextractor::containsPattern($deal_content_ref,
						$no_address_regex))
	{# Only get address if deal isn't "redeemable from home" (not local)
	    # Gather at most 15 addresses:
	    my @addresses = &genericextractor::extractMBetweenPatternsN(
		15, 15, $deal_content_ref, "<div\\s+class=[\'\"]address[\'\"]",
		"<\\/div>", "<h4[^<]+<\\/h4>", "<[^>]+>", "^\\s+",
		"[Gg]et\\s+[Dd]irections");
	    if ($#addresses >= 0) {
		foreach my $address (@addresses) {
		    $address =~ s/\s+/ /g;
		    $address =~ s/\s+$//;
		    
		    if (($address =~ /,\s+([A-Za-z\s]+)\s+([0-9]{5})/ &&
			&genericextractor::isState($1)) ||
			# Check for Canadian addresses:
			($address =~
			 /,\s+([A-Za-z\s]+)\s+([A-Z0-9]{3}\s[A-Z0-9]{3})/ &&
			 &genericextractor::isState($1))) {
			my $zip = $2;
			$address =~ s/$zip(.*)/$zip/;
			# Phone number is put after the address in groupon pages
			my $phone = $1;
			if ($phone =~
			    /(\([0-9]{3}\)[^0-9]?[0-9]{3}[^0-9]?[0-9]{4})/) {
			    $deal->phone($1);
			}
			$deal->addresses($address);
		    }
		}
	    }
	}


	$tree->delete();
    }
  

    1;
}
