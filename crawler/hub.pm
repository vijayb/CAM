#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package hub;
    use strict;
    use warnings;

    sub new {
	my $self = {};

	$self->{url} = undef;
	$self->{company_id} = undef;
	$self->{city_ids} = ();
	$self->{category_id} = undef;
	$self->{use_cookie} = undef;
	$self->{recrawl_deal_urls} = undef;
	$self->{hub_contains_deal} = undef;
	$self->{post_form} = ();
	$self->{last_crawled} = 0;
	
	bless($self);
	return $self;
    }

    sub url {
	my $self = shift;
	if (@_) { $self->{url} = shift; }
	return $self->{url};
    }

    sub company_id {
	my $self = shift;
	if (@_) { $self->{company_id} = shift; }
	return $self->{company_id};
    }

    sub city_ids {
	my $self = shift;
	if (@_) { 
	    my $city = shift;
	    ${$self->{city_ids}}{$city} = 1;
	}
	return \%{$self->{city_ids}};
    }

    sub category_id {
	my $self = shift;
	if (@_) { $self->{category_id} = shift; }
	return $self->{category_id};
    }

    sub use_cookie {
	my $self = shift;
	if (@_) { $self->{use_cookie} = shift; }
	return $self->{use_cookie};
    }

    sub recrawl_deal_urls {
	my $self = shift;
	if (@_) { $self->{recrawl_deal_urls} = shift; }
	return $self->{recrawl_deal_urls};
    }

    sub hub_contains_deal {
	my $self = shift;
	if (@_) { $self->{hub_contains_deal} = shift; }
	return $self->{hub_contains_deal};
    }

    sub post_form {
	my $self = shift;
	if (@_) { 
	    # Post string comes as white space separated key/value pairs
	    # for post form
	    my $string = shift;
	    my @post_values = split(/\s+/, $string);
	    
	    if ($#post_values >= 1 && (($#post_values+1)%2) == 0) {
		for (my $i=0; $i <= $#post_values; $i+=2) {
		    ${$self->{post_form}}{$post_values[$i]} =
			$post_values[$i+1];
		}
	    }
	}

	return \%{$self->{post_form}};
    }

    sub has_post_form {
	my $self = shift;
	return scalar(keys(%{$self->{post_form}})) > 0;
    }

    sub last_crawled {
	my $self = shift;
	if (@_) { $self->{last_crawled} = shift; }
	return $self->{last_crawled};
    }

    1;
}
