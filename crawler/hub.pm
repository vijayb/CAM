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
	$self->{city_id} = undef;
	$self->{category_id} = undef;
	$self->{use_cookie} = undef;
	$self->{recrawl_deal_urls} = undef;
	$self->{hub_contains_deal} = undef;
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

    sub city_id {
	my $self = shift;
	if (@_) { $self->{city_id} = shift; }
	return $self->{city_id};
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

    sub last_crawled {
	my $self = shift;
	if (@_) { $self->{last_crawled} = shift; }
	return $self->{last_crawled};
    }

    1;
}
