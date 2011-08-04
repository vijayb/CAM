#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) August, 2010
#
#

package main;

use strict;
use warnings;

use Geo::Coder::Googlev3;
use LWP::UserAgent;
use LWP::Simple;
use HTTP::Request::Common qw(POST);
use getargs;

my ($webserver, $database, $user, $password);
getargs::get(\$webserver, \$database, \$user, \$password);


my $browser = LWP::UserAgent->new();
my $geocoder = Geo::Coder::Googlev3->new;
my $request = $webserver."get_addresses.php?"."database=".$database.
    "&user=".$user."&password=".$password;
my $post_request = $webserver."insert_address.php?"."database=".$database.
    "&user=".$user."&password=".$password;


while (1) {
    my $addresses_page = get $request;
    my %raw_addresses;
    if (defined($addresses_page)) {
	my @address_lines = split(/\n/, $addresses_page);

	print "".(1+$#address_lines)." address lines that need geocoding ".
	    "read from database.\n";
	foreach my $address_line (@address_lines) {
	    if ($address_line =~ /([0-9]+),(.*)/) {
		$raw_addresses{$1} = $2;
	    } else {
		die "Error: badly formed line [$address_line]\n";
	    }
	}
    }


    foreach my $id (keys %raw_addresses) {
	print "Geocoding id $id, address [$raw_addresses{$id}]\n";
	my $location = $geocoder->geocode(location => $raw_addresses{$id});

	my @address_components = @{$location->{address_components}};
	
	my $street_number;
	my $street;
	my $city;
	my $state;
	my $zipcode;
	my $country;
	my $latitude;
	my $longitude;

	foreach my $component (@address_components) {
	    if (defined($component->{'types'}[0])) {
		if ($component->{'types'}[0] eq "street_number") {
		    $street_number = $component->{long_name};
		}

		if ($component->{'types'}[0] eq "route") {
		    $street = $component->{long_name};
		}

		if ($component->{'types'}[0] eq "locality") {
		    $city = $component->{long_name};
		}

		if ($component->{'types'}[0] eq "administrative_area_level_1") {
		    $state = $component->{short_name};
		}

		if ($component->{'types'}[0] eq "country") {
		    $country = $component->{long_name};
		}

		if ($component->{'types'}[0] eq "postal_code") {
		    $zipcode = $component->{short_name};
		}
	    }
	}
	if (defined($street_number) && defined($street)) {
	    $street = $street_number." ".$street;
	}
	$latitude = $location->{geometry}->{location}->{lat};
	$longitude = $location->{geometry}->{location}->{lng};


	my %post_form;

	$post_form{"id"} = $id;

	if (defined($street)) {
	    $post_form{"street"} = $street;
	}
	if (defined($city)) {
	    $post_form{"city"} = $city;
	}
	if (defined($zipcode)) {
	    $post_form{"zipcode"} = $zipcode;
	}
	if (defined($state)) {
	    $post_form{"state"} = $state;
	}
	if (defined($country)) {
	    $post_form{"country"} = $country;
	}
	if (defined($latitude)) {
	    $post_form{"latitude"} = $latitude;
	}
	if (defined($longitude)) {
	    $post_form{"longitude"} = $longitude;
	}

	print "Inserting... ";
	my $response = $browser->post($post_request, \%post_form);

	#print "\n".$response->content()."\n";
	if (defined($response) &&
	    $response->content() =~ /error/i) {
	    die "\n",$response->content(),"\n";
	} else {
	    print "success!\n";
	}
	sleep(2);
    }
    

    print "Sleeping for a few seconds... ".time()."\n";
    sleep(10);
}
