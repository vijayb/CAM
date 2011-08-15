#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package giltcityextractor;
    
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

	# GiltCity doesn't provide this information on its pages
	$deal->num_purchased(-1);

	my @title = $tree->look_down(
	    sub{$_[0]->tag() eq 'h1' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "name")});
	if (@title) {
	    $deal->title($title[0]->as_text());
	}

	my @subtitle = $tree->look_down(
	    sub{$_[0]->tag() eq 'h2' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "tagline")});
	if (@title) {
	    $deal->subtitle($subtitle[0]->as_text());
	}

	my @price = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "cost")});
	if (@price) {
	    my $price = $price[0]->as_text();
	    if ($price =~ /([0-9,]+)/) {
		$price = $1;
		$price =~ s/,//g;
		$deal->price($price);
	    }
	}

	my @value = $tree->look_down(
	    sub{$_[0]->tag() eq 'span' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') =~ /msrp/)});
	if (@value) {
	    my $value = $value[0]->as_text();
	    if ($value =~ /([0-9,]+)/) {
		$value = $1;
		$value =~ s/,//g;
		$deal->value($value);
	    }
	}

	my @text = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('id')) &&
		    ($_[0]->attr('id') eq "info_tab_about")});
	if (@text) {
	    my $text = $text[0]->as_HTML();
	    $text =~ s/<\/?div[^>]*>//g;
	    $text =~ s/<h2[^<]*<\/h2>//g;

	    $deal->text($text);
	}

	my @fine_print = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('id')) &&
		    ($_[0]->attr('id') =~ /info_tab_needhelp_questions/)});
	if (@fine_print) {
	    my $fine_print = $fine_print[0]->as_HTML();
	    $fine_print =~ s/<\/?div[^>]*>//g;
	    $deal->fine_print($fine_print);
	}


	my @image = $tree->look_down(
	    sub{$_[0]->tag() eq 'li' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "slide")});
	if (@image &&
	    $image[0]->as_HTML() =~ /src=[\'\"]([^\'\"]+)/) {
	    $deal->image_url($1);
	}


	if ($tree->as_HTML() =~ /is_sold_out[^a-z]true/) {
	    $deal->expired(1);
	}


	# Just make up a deadline for GiltCity since it's friggin
	# impossible to extract it
	if (!defined($deal->expired()) && !$deal->expired()) {
	    my ($year, $month, $day);
	    ($year, $month, $day) =
		(gmtime(time() + 3*24*60*60))[5,4,3];
	    
	    my $deadline = sprintf("%d-%02d-%02d 01:01:01",
				1900+$year, $month+1, $day);
	    
	    $deal->deadline($deadline);
	}

	if ($tree->as_HTML() =~
	    /redemption_end_datetime[^0-9]+([0-9]+)\s+([A-Z][a-z]+)\s+([0-9]{4})/) {
	    my $day = $1;
	    my $month = $2;
	    my $year = $3;
	    if (defined($month_map{$month})) {
		my $expires = sprintf("%d-%02d-%02d 01:01:01",
				      $year, $month_map{$month}, $day);
		$deal->expires($expires);		
	    }
	}


	if ($tree->as_HTML() =~ /name_short[\'\"][^\'\"]+[\'\"]([^\'\"]+)/) {
	    $deal->name($1);
	}

	# GiltCity doesn't seem to provide any website information
	# for businesses. Boo!

	my @address_group = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') =~ /map_addresses/)});
	if (@address_group) {
	    my @addresses = $address_group[0]->look_down(
		sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
			$_[0]->attr('class') eq "address"});

	    foreach my $address (@addresses) {
		my $address_raw = $address->as_text();
		$address_raw =~ s/^\s+//;
		$address_raw =~ s/\s+$//;
		$deal->addresses($address_raw);
	    }
	}



	$tree->delete();
    }
  

    1;
}
