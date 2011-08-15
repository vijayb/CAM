#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package zoziextractor;
    
    use strict;
    use warnings;
    use deal;
    use genericextractor;
    use HTML::TreeBuilder;
    use Encode;

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

    my %num_map = (
	"one" => 1,
	"two" => 2,
	"three" => 3,
	"four" => 4,
	"five" => 5,
	"six" => 6,
	"seven" => 7,
	"eight" => 8,
	"nine" => 9,
	"ten" => 10,
	"eleven" => 11,
	"twelve" => 12
    );


    sub extract {
	my $tree = HTML::TreeBuilder->new;
	my $deal = shift;
	my $deal_content_ref = shift;
	
	$tree->parse(decode_utf8 $$deal_content_ref);
	$tree->eof();

	# Zozi doesn't provide this information on its pages
	$deal->num_purchased(-1);

	my @title = $tree->look_down(
	    sub{$_[0]->tag() eq 'h1'});
	if (@title) {
	    $deal->title($title[0]->as_text());
	}

	my @price = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "your_price")});
	if (@price) {
	    my $price = $price[0]->as_text();
	    if ($price =~ /([0-9,]+)/) {
		$price = $1;
		$price =~ s/,//g;
		$deal->price($price);
	    }
	}

	my @value = $tree->look_down(
	    sub{$_[0]->tag() eq 'table' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') =~ /deal_numbers/)});
	if (@value) {
	    my $value = $value[0]->as_HTML();
	    if ($value =~ /([0-9,]+)/) {
		$value = $1;
		$value =~ s/,//g;
		$deal->value($value);
	    }
	}


	my @text = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') =~ /long_description/)});
	if (@text) {
	    my $text = $text[0]->as_HTML();
	    $text =~ s/<\/?div[^>]*>//g;
	    $deal->text($text);
	}

	my @fine_print = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') =~ /special_terms/)});
	if (@fine_print) {
	    my $fine_print = $fine_print[0]->as_HTML();
	    $fine_print =~ s/<\/?div[^>]*>//g;
	    $fine_print =~ s/<\/?h4[^>]*>//g;
	    $deal->fine_print($fine_print);
	}


	my @image = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('id')) &&
		    ($_[0]->attr('id') =~ /loadarea/)});
	if (@image && $image[0]->as_HTML() =~ /src=[\'\"]([^\'\"]+)/) {
	    $deal->image_url($1);
	}


	if ($tree->as_text() =~ /this\s+deal\s+has\s+expired/i) {
	    $deal->expired(1);
	}

	if (!defined($deal->expired()) && !$deal->expired()) {
	    my @deadline = $tree->look_down(
		sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
			($_[0]->attr('class') =~ /countdown_end_date/)});
	    if (@deadline && $deadline[0]->as_text() =~ /^([0-9]{10})/) {
		my $time = $1;
		my ($year, $month, $day, $hour, $minute);
		($year, $month, $day, $hour, $minute) =
		    (gmtime($time))[5,4,3,2,1];
		
		my $deadline = sprintf("%d-%02d-%02d %02d:%02d:01",
				    1900+$year, $month+1, $day,
				    $hour, $minute);

		$deal->deadline($deadline);
	    }
	}

	# Zozi puts the expiry information in the fine print.
	# This regex will only work for United States format. E.g.,
	# May 5th, 2011. In Australia they do 5th May, 2011
	if (defined($deal->fine_print()) && $deal->fine_print() =~ 
	    /([A-Z][a-z]+)\s+([0-9]{1,2})[a-z]{0,2},\s+([0-9]{4})/) {
	    my $month = $1;
	    my $day = $2;
	    my $year = $3;
	    
	    if (defined($month_map{$month})) {
		my $expires = sprintf("%d-%02d-%02d 01:01:01",$year,
				      $month_map{$month}, $day);
		$deal->expires($expires);
	    }
	}

	# Sometimes Zozi gives us expiry information in the form
	# Expires 6 months from the date of purchase. Or, even, annoyingly,
	# six months from the data of purchase.
	if (defined($deal->fine_print()) && $deal->fine_print() =~ 
	    /[Ee]xpires\s+([^\s]+)\s+([a-z]+)/) {
	    my $num_months = $1;
	    my $period = $2;
	    if ($period =~ /week/) {
		$period = 0.25;
	    } elsif ($period =~ /month/) {
		$period = 1;
	    } elsif ($period =~ /year/) {
		$period = 12;
	    } else {
		$period = 0;
	    }

	    if (defined($num_map{$num_months})) {
		$num_months = $num_map{$num_months};
	    }

	    if ($num_months =~ /^[0-9]+$/) {
		my ($year, $month, $day);
		($year, $month, $day) =
		    (gmtime(time() + $period*$num_months*30*24*60*60))[5,4,3];
		
		my $expires = sprintf("%d-%02d-%02d 01:01:01",
				      1900+$year, $month+1, $day);
		$deal->expires($expires);
	    }
	}


	if (defined($deal->fine_print()) && $deal->fine_print() =~ 
	    /[Ee]xpires\s+o?n?\s*([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{2,4})/) {
	    my $month = $1;
	    my $day = $2;
	    my $year = $3;
	    if (length($year)==2) {
		$year += 2000;
	    }
	    
	    my $expires = sprintf("%d-%02d-%02d 01:01:01",$year,
				  $month, $day);
	    $deal->expires($expires);
	}


	my @info = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') =~ /merchant_info/i)});
	if (@info) {
	    if ($info[0]->as_HTML =~ /<h5>([^<]+)/) {
		$deal->name($1);
	    }
	    if ($info[0]->as_HTML =~ /href=[\'\"]([^\'\"]+)/) {
		$deal->website($1);
	    }

	    if ($info[0]->as_HTML =~ /maps.google.com\/\?q=loc:([^\'\"]+)/) {
		# Sometimes zozi gives just a city or a state as an address.
		# We're only interested in full addresses, so we'll filter
		# by length
		if (length($1) > 15) {
		    $deal->addresses($1);
		}
	    }
	}

	my @website = $tree->look_down(
	    sub{$_[0]->tag() eq 'a' && defined($_[0]->attr('id')) &&
		    ($_[0]->attr('id') =~ /Main_MerchantWebSite/i)});
	if (@website) {
	    $deal->website($website[0]->attr('href'));
	}

	my @addresses = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') =~ /smallMap/)});
	if (@addresses) {
	    my @ptags = $addresses[0]->look_down(
		sub{$_[0]->tag() eq 'p' && !defined($_[0]->attr('id'))});

	    foreach my $ptag (@ptags) {
		my $address = $ptag->as_HTML();
		if ($address =~ /([^>]+)$/) {
		    my $end = $1;
		    $end =~ s/\s+//g;
		    my $end2 = $end;
		    $end2 =~ s/[^0-9]+//g;

		    # Check if end of string is a phone number
		    # (most of its content is numbers)
		    if (length($end2) > 8 &&
			length($end) - length($end2) <= 3) {
			$deal->phone($end);
			$address =~ s/<[^>]+>[^>]+$//;
		    }
		}
		
		# Remove superfluous tags and text for deals
		# which can only be redeemed online
		$address =~ s/<[^>]+>/ /g;
		$address =~ s/online redemption only//gi;
		$address =~ s/^\s+//g;

		# US addresses:
		if ($address =~ /,\s+(.*)\s+[0-9]{5}$/ &&
		    genericextractor::isState($1)) {
		    $deal->addresses($address);
		}

		# Canadian addresses:
		if ($address =~ /,\s+(.*)\s+[A-Z0-9]{3}\s+[A-Z0-9]{3}$/ &&
		    genericextractor::isState($1)) {
		    $deal->addresses($address);
		}
	    }
	}



	$tree->delete();
    }
  

    1;
}
