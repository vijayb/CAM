#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package scoutmobextractor;
    
    use strict;
    use warnings;
    use deal;
    use genericextractor;
    use HTML::TreeBuilder;
    use Encode;


    sub extract {
	my $tree = HTML::TreeBuilder->new;
	my $deal = shift;
	my $deal_content_ref = shift;
	
	$tree->parse(decode_utf8 $$deal_content_ref);
	$tree->eof();

	my @title = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "title")});
	if (@title) {
	    $deal->title($title[0]->as_text());
	}
	
	# ScoutMob doesn't give us a price and a value. Instead they give
	# you a percentage off value and the maximum savings you're allowed.
	# From these we infer price and value.
	if ($tree->as_HTML() =~ /percentage_off[^0-9]+([0-9]{1,2})%\\\"/) {
	    my $discount = 1.0*$1/100.0;

	    my @price = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "details")});

	    if (@price && $discount > 0 &&
		$price[0]->as_text() =~ /\$([0-9,]+)\s+max\s+discount/) {
		my $savings = 1.0*$1;

		my $price = ($savings - ($savings*$discount))/$discount;
		my $value = $price + $savings;

		$deal->price($price);
		$deal->value($value);
	    }
	}

	if ($tree->as_HTML() =~ /number_used[^0-9]+([0-9]+)/) {
	    $deal->num_purchased($1);
	}

	my @text = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') =~ /description/)});
	if (@text) {
	    my $text = $text[0]->as_HTML();
	    $text =~ s/<\/?div[^>]*>//g;
	    $deal->text($text);
	}

	my @fine_print = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') =~ /fine_print/)});
	if (@fine_print) {
	    my $fine_print = $fine_print[0]->as_HTML();
	    $fine_print =~ s/<\/?div[^>]*>/ /g;
	    $fine_print =~ s/^\s+//;
	    $fine_print =~ s/\s+$//;
	    $deal->fine_print($fine_print);
	}


	my @image = $tree->look_down(
	    sub{$_[0]->tag() eq 'img' && defined($_[0]->attr('class')) &&
		    ($_[0]->attr('class') eq "picture")});
	if (@image && $image[0]->as_HTML() =~ /src=[\'\"]([^\'\"]+)/) {
	    $deal->image_url($1);
	}


	if (!defined($deal->expired()) && !$deal->expired()) {
	    if ($tree->as_HTML() =~ /site_end_utc[^0-9]+([0-9]{10})/) {
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


	# ScoutMob puts the expiry information in the fine print.
	if (defined($deal->fine_print()) && $deal->fine_print() =~ 
	    /Expires[^0-9]+([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{4})/) {
	    my $month = $1;
	    my $day = $2;
	    my $year = $3;
	    
	    my $expires = sprintf("%d-%02d-%02d 01:01:01", $year, $month, $day);
	    $deal->expires($expires);
	}





	my @name = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    $_[0]->attr('class') eq "biz_name"});
	if (@name) {
	    $deal->name($name[0]->as_text());
	}

	my @website = $tree->look_down(
	    sub{$_[0]->tag() eq 'a' && defined($_[0]->attr('name')) &&
		    $_[0]->attr('name') eq "website"});
	if (@website) {
	    $deal->website($website[0]->attr('href'));
	}

	my @phone = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    $_[0]->attr('class') eq "phone"});
	if (@phone) {
	    $deal->phone($phone[0]->as_text());
	}

	my @address = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    $_[0]->attr('class') eq "address"});

	my @citystate = $tree->look_down(
	    sub{$_[0]->tag() eq 'div' && defined($_[0]->attr('class')) &&
		    $_[0]->attr('class') eq "city_state"});

	if (@address && @citystate) {
	    $deal->addresses(
		$address[0]->as_text()." ".$citystate[0]->as_text());
	}



	$tree->delete();
    }
  

    1;
}
