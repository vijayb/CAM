#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package bloomspotextractor;
    
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


    sub extract {
	my $tree = HTML::TreeBuilder->new;
	my $deal = shift;
	my $deal_content_ref = shift;
	
	$tree->parse(decode_utf8 $$deal_content_ref);
	$tree->eof();

	# Bloomspot doesn't provide this information on its pages
	$deal->num_purchased(-1);

	my @title = $tree->look_down(
	    sub{$_[0]->tag() eq 'h1' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "deal_heading")});
	if (@title) {
	    my $title = $title[0]->as_text();
	    $title =~ s/&nbsp;//g;
	    $deal->title($title);
	}

	my @subtitle = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "deal_info")});
	if (@subtitle) {
	    my $subtitle = $subtitle[0]->as_text();
	    $deal->subtitle($subtitle);
	}

	my @price = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "twosku_detail")});
	if (@price) {
	    my $price = $price[0]->as_text();
	    if ($price =~ /\$([0-9,]+)\s+for[^\$]+\$([0-9,]+)/) {
		$price = $1;
		my $value = $2;
		$price =~ s/,//g;
		$value =~ s/,//g;
		$deal->price($price);
		$deal->value($value);
	    }
	}


	if (0 && !defined($deal->price()) || !defined($deal->value())) {
	    if (defined($deal->subtitle()) &&
		$deal->subtitle =~ /\$([0-9,]+)[^\$]+\$([0-9,]+)/) {
		if ($1 < $2) {
		    $deal->price($1);
		    $deal->value($2);
		} else {
		    $deal->price($2);
		    $deal->value($1);
		}
	    }
	}
	
	my @text = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "deal_review")});
	if (@text) {
	    my $text = $text[0]->as_HTML();
	    $text =~ s/<\/?div[^>]*>//g;
	    $deal->text($text);

	    # Bloomspot puts the name of the business at the start of
	    # the deal text, in bold. E.g., <b>Emerald City Pilates and
	    # Personal Training</b> - by bloomspot Staff Writers"
	    if ($text =~ /^<b>([^<]+)/) {
		$deal->name($1);
	    } elsif ($text[0]->as_text() =~
		     /^(.*)\s+-\s+by\s+bloomspot\s+staff\s+writers/i) {
		$deal->name($1);
	    }
	}

	my $offer_details = 0;
	my @fine_print = $tree->look_down(
	    sub {
		my $tag = $_[0]->tag();
		my $class = $_[0]->attr('class');
		my $text = $_[0]->as_text();
		if ($tag eq "div" && $text =~ /offer\s+details/i &&
		    defined($class) && $class eq "rightsecheader") {
		    $offer_details = 1;
		}

		return $offer_details && $_[0]->tag() eq 'div' && 
		    defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "detail_section")
	    });
	if (@fine_print) {
	    my $fine_print = $fine_print[0]->as_HTML();
	    $fine_print =~ s/<\/?div[^>]*>//g;
	    $deal->fine_print($fine_print);
	}


	my @image = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('id')) &&
		    ($_[0]->attr('id') =~ /slideshowModule/i)});
	if (@image && $image[0]->as_HTML() =~ 
	    /rel=[\'\"](http:\/\/cdn.bloomspot.com[^\'\"]+)/) {
	    $deal->image_url($1);
	}


	my @expired = $tree->look_down(
	    sub{$_[0]->tag() eq 'img' && defined($_[0]->attr('alt')) &&
		    ($_[0]->attr('alt') =~ /closed/i)});
	if (@expired) {
	    $deal->expired_url($1);
	}


	if (!defined($deal->expired()) && !$deal->expired()) {
	    if ($tree->as_HTML =~ /CountDownTimer\(([0-9]+)/) {
		my $offset = $1;

		my ($year, $month, $day, $hour, $minute);
		($year, $month, $day, $hour, $minute) =
		    (gmtime(time() + $offset))[5,4,3,2,1];
		
		my $deadline = sprintf("%d-%02d-%02d %02d:%02d:01",
				    1900+$year, $month+1, $day,
				    $hour, $minute);

		$deal->deadline($deadline);
	    }
	}

	# Bloomspot puts the expiry information in the fine print.
	# This regex will only work for United States format. E.g.,
	# August 9, 2012. In Australia they do 9 August, 2012

	if (defined($deal->fine_print()) && $deal->fine_print() =~ 
	    /Expires\s+([A-Z][a-z]+)\s+([0-9]{1,2}),\s+([0-9]{4})/) {
	    my $month = $1;
	    my $day = $2;
	    my $year = $3;
	    
	    if (defined($month_map{$month})) {
		my $expires = sprintf("%d-%02d-%02d 01:01:01",$year,
				      $month_map{$month}, $day);
		$deal->expires($expires);
	    }
	}

	my $merchant_section = 0;
	my @info = $tree->look_down(
	    sub {
		my $tag = $_[0]->tag();
		my $class = $_[0]->attr('class');
		my $text = $_[0]->as_text();
		if ($tag eq "div" && $text eq "Where" && defined($class) &&
		    $class eq "rightsecheader") {
		    $merchant_section = 1;
		}
		
		return $merchant_section && $_[0]->tag() eq 'div' && 
		    defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "detail_section");
	    });

	if (@info) {
	    my @litags = $info[0]->look_down(sub{$_[0]->tag() eq 'li'});
	    foreach my $litag (@litags) {
		my $litext = $litag->as_HTML();
		$litext =~ s/<[^>]+>/ /g;
		$litext =~ s/^\s+//;
		$litext =~ s/\s+$//;
		my $linum = $litext;
		$linum =~ s/[^0-9]+//g;

		if (length($litext) - length($linum) <= 4 &&
		    length($linum) > 8) {
		    $deal->phone($litext);
		    next;
		}
		if ($litag->as_HTML =~ /href=[\'\"]([^\'\"]+)/) {
		    $deal->website($1);
		}

		if ($litext =~ /([A-Z]{2})\s+[0-9]{5}$/ &&
		    genericextractor::isState($1)) {
		    $deal->addresses($litext);
		}
	    }
	}



	$tree->delete();
    }
  

    1;
}
