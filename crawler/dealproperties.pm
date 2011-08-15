#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package dealproperties;
    use strict;
    use warnings;
    use hub;
    use crawlerutils;

    sub new {
	my $self = {};

	$self->{url} = undef;
	$self->{company_id} = undef;
	$self->{city_ids} = ();
	$self->{city_ids_updated} = 0;
	$self->{category_id} = undef;
	$self->{use_cookie} = undef;
	$self->{recrawl} = undef;
	$self->{expired} = 0;

	$self->{last_inserted} = 0;
	$self->{last_crawled} = 0;
	$self->{discovered} = crawlerutils::gmtNow();

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

    sub city_ids_updated {
	my $self = shift;
	if (@_) { $self->{city_ids_updated} = shift; }
	return $self->{city_ids_updated};
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

    sub recrawl {
	my $self = shift;
	if (@_) { $self->{recrawl} = shift; }
	return $self->{recrawl};
    }

    sub last_inserted {
	my $self = shift;
	if (@_) { $self->{last_inserted} = shift; }
	return $self->{last_inserted};
    }

    sub last_crawled {
	my $self = shift;
	if (@_) { $self->{last_crawled} = shift; }
	return $self->{last_crawled};
    }

    sub discovered {
	my $self = shift;
	if (@_) { $self->{discovered} = shift; }
	return $self->{discovered};
    }

    sub expired {
	my $self = shift;
	if (@_) { $self->{expired} = shift; }
	return $self->{expired};
    }

    sub inherit_properties_from_hub {
	my $self = shift;

	if ($#_ == 1) {
	    my $url = shift;
	    my $parent_hub = shift;

	    $self->{url} = $url;
	    $self->{company_id} = $parent_hub->company_id();
	    # Because multiple hubs can refer to a deal, each
	    # deal needs to be able to store multiple cities.
	    # I.e., a deal can be valid for Portland, OR and
	    # Vancouver, WA at the same time, since they're
	    # so close by.
	    my $city_ids_size = keys(%{$self->{city_ids}});

	    my $cities_ref = $parent_hub->city_ids();
	    foreach my $city (keys %{$cities_ref}) {
		${$self->{city_ids}}{$city} = 1;
	    }

	    if ($city_ids_size != scalar(keys(%{$self->{city_ids}}))) {
		# We inherited a new city_id
		$self->{city_ids_updated} = 1;
	    }

	    $self->{category_id} = $parent_hub->category_id();
	    $self->{use_cookie} = $parent_hub->use_cookie();
	    $self->{recrawl} = $parent_hub->recrawl_deal_urls();
	}
    }

    sub to_string {
	my $self = shift;

	my $cityids="";
	foreach my $key (keys %{$self->{city_ids}}) {
	    $cityids = "$cityids + $key";
	}
	return $self->{url}.",".$self->company_id().
	    ",[".$cityids."],".$self->{category_id}.
	    ",".$self->{use_cookie}.",".$self->{recrawl}.",";
    }

    
    1;
}
