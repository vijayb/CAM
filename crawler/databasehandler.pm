#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package databasehandler;
    
    use strict;
    use warnings;
    use deal;
    use hub;
    use logger;
    use getargs;
    use LWP::UserAgent;
    use LWP::Simple;
    use HTTP::Request::Common qw(POST);
    use Sys::Hostname;

    my ($webserver, $database, $user, $password, $company_id_filter);
    getargs::getCrawlerArgs(\$webserver, \$database, \$user,
			    \$password, \$company_id_filter);

    my $browser = LWP::UserAgent->new();


    sub insertDealCitiesIntoDatabase {
	if ($#_ != 1 ) { die "Invalid use of insertCityDealsIntoDatabse"; }
	my $deal_url = shift;
	my $city_ids_hash_ref = shift;

	my $post_url = $webserver."insert_dealcities.php?"."database=".
	    $database."&user=".$user."&password=".$password;
	my %post_form;


	$post_form{"deal_url"} = $deal_url;
	my $i=1;
	foreach my $city_id (keys %{$city_ids_hash_ref}) {
	    $post_form{"city_ids_$i"} = $city_id;
	    $i++;
	}

	my $response =
	    $browser->post($post_url,
			   "Content_Type" => "multipart/form-data",
			   "Content" => \%post_form);

	if ($response->is_success &&
	    defined($response->content()) &&
	    $response->content() !~ /error/i) {
	    return 1;
	} else {
	    my $error_msg = "Unable to insert cities for [".$deal_url."] into ".
		"database.\n";
	    if (defined($response->content())) {
		$error_msg = $error_msg."Response: ".$response->content().
		    "\nResponse code: ".$response->code();
	    }
	    logger::LOG($error_msg, 3);
	}

	return 0;
    }

    sub getAndInsertImageIntoDatabase {
	my $image_url = shift;
	my $post_url = $webserver."insert_image.php?"."database=".$database.
	    "&user=".$user."&password=".$password;

	my $image_data = get $image_url;

	if (defined($image_data)) {
	    my $response =
		$browser->post($post_url,
			       "Content_Type" => "multipart/form-data",
			       "Content" => [
				   "image_url" => $image_url,
				   "image_data" => [ undef,
						     "image",
						     Content=>$image_data ]]);

	    if ($response->is_success &&
		defined($response->content()) &&
		$response->content() !~ /error/i) {
		return 1;
	    } else {
		my $error_msg = "Unable to insert [".$image_url."] into ".
		    "database.\n";
		if (defined($response->content())) {
		    $error_msg = $error_msg."Response: ".$response->content().
			"\nResponse code: ".$response->code();
		}
		logger::LOG($error_msg, 3);
		return 0;
	    }
	} else {
	    logger::LOG("Unable to download image [$image_url]", 3);
	    return 0;
	}
	return 0;
    }

    sub insertDealIntoDatabase {
	my $deal = shift;

	if (defined($deal) && defined($deal->url())) {
	    my %post_form;
	    $post_form{"url"} = $deal->url();

	    if (defined($deal->recrawl())) {
		$post_form{"recrawl"} = $deal->recrawl();
	    }
	    if (defined($deal->use_cookie())) {
		$post_form{"use_cookie"} = $deal->use_cookie();
	    }
	    if (defined($deal->company_id())) {
		$post_form{"company_id"} = $deal->company_id();
	    }
	    if (defined($deal->category_id())) {
		$post_form{"category_id"} = $deal->category_id();
	    }
	    if (defined($deal->title())) {
		$post_form{"title"} = $deal->title();
	    }
	    if (defined($deal->subtitle())) {
		$post_form{"subtitle"} = $deal->subtitle();
	    }
	    if (defined($deal->text())) {
		$post_form{"text"} = $deal->text();
	    }
	    if (defined($deal->fine_print())) {
		$post_form{"fine_print"} = $deal->fine_print();
	    }
	    if (defined($deal->price())) {
		$post_form{"price"} = $deal->price();
	    }
	    if (defined($deal->value())) {
		$post_form{"value"} = $deal->value();
	    }
	    if (defined($deal->num_purchased())) {
		$post_form{"num_purchased"} = $deal->num_purchased();
	    }
	    if (defined($deal->expired())) {
		$post_form{"expired"} = $deal->expired();
	    }
	    if (defined($deal->deadline())) {
		$post_form{"deadline"} = $deal->deadline();
	    }
	    if (defined($deal->expires())) {
		$post_form{"expires"} = $deal->expires();
	    }
	    if (defined($deal->image_url())) {
		$post_form{"image_url"} = $deal->image_url();
	    }
	    if (defined($deal->name())) {
		$post_form{"name"} = $deal->name();
	    }
	    if (defined($deal->website())) {
		$post_form{"website"} = $deal->website();
	    }
	    if (defined($deal->phone())) {
		$post_form{"phone"} = $deal->phone();
	    }

	    my $addresses_ref = $deal->addresses();
	    my $i=1;
	    foreach my $address (keys %{$addresses_ref}) {
		# Write at most 10 addresses to database. Ultimately
		# we need to figure out if we want to allow an arbitrary
		# number of addresses per deal. The value of doing so
		# seems pretty low. Such deals are very rare.
		if ($i>10) { last; }

		$post_form{"address$i"} = $address;
		$i++
	    }
	    
	    my $request = $webserver."insert_deal.php?"."database=".$database.
		"&user=".$user."&password=".$password;
	    
	    my $response = $browser->post($request, \%post_form);

	    if ($response->is_success &&
		defined($response->content()) &&
		$response->content() !~ /error/i) {
		return 1;
	    } else {
		my $error_msg = "Unable to insert [".$deal->url()."] into ".
		    "database.\n";
		if (defined($response->content())) {
		    $error_msg = $error_msg."Response: ".$response->content().
			"\nResponse code: ".$response->code();
		}
		logger::LOG($error_msg, 3);
	    }

	    return 0;
	}
    }


    sub getHubProperties {
	if ($#_ != 0) { die "Incorrect usage of getHubProperties.\n"; }
	my $hash_ref = $_[0];
	my $request = $webserver."get_hubs.php?"."database=".$database.
	    "&user=".$user."&password=".$password;

	my $hub_rows = get $request;

	if (!defined($hub_rows)) {
	    die "Unable to obtain hubs in getHubProperties.\n";
	}
	my @hub_rows = split(/\n/, $hub_rows);
	my $invalid_hub_rows = 0;

	foreach my $row (@hub_rows) {
	    my @hub_parts = split(/,/, $row);
	    $hub_parts[0] =~ s/\s//g;

	    if (($#hub_parts != 6 && $#hub_parts != 7) ||
		$hub_parts[0] !~ /^(((http|https):\/\/)?([[a-zA-Z0-9]\-\.])+(\.)([[a-zA-Z0-9]]){2,4}([[a-zA-Z0-9]\/+=%&_\.~?\-]*))*/ || # hub url
		$hub_parts[1] !~ /^[1-9][0-9]*$/ || # company_id (not zero)
		$hub_parts[2] !~ /^[1-9][0-9]*$/ || # city_id (not zero)
		$hub_parts[3] !~ /^[0-9]+$/ || # category_id (can be zero)
		$hub_parts[4] !~ /^[0-1]$/ || # use cookie to crawl hub
		$hub_parts[5] !~ /^[0-1]$/ || # recrawl deal page on this hub
		$hub_parts[6] !~ /^[0-1]$/ || # hub page contains deal
		# If the 7th part exists, it should be a whitespace separated
		# post form of key-value pairs
		($#hub_parts == 7 && !isValidPostForm($hub_parts[7])))
	    {
		$invalid_hub_rows++;
	    }
	    # Allow user of crawler to only crawl specific companies. This
	    # is useful for debugging crawler/extraction problems
	    elsif ($company_id_filter == 0 ||
		   $hub_parts[1] == $company_id_filter) 
	    {
		if (!defined(${$hash_ref}{$hub_parts[0]})) {
		    ${$hash_ref}{$hub_parts[0]} = hub->new();
		    ${$hash_ref}{$hub_parts[0]}->url($hub_parts[0]);
		    ${$hash_ref}{$hub_parts[0]}->company_id($hub_parts[1]+0);
		    ${$hash_ref}{$hub_parts[0]}->category_id($hub_parts[3]+0);
		    ${$hash_ref}{$hub_parts[0]}->use_cookie($hub_parts[4]+0);
		    ${$hash_ref}{$hub_parts[0]}->
			recrawl_deal_urls($hub_parts[5]+0);
		    ${$hash_ref}{$hub_parts[0]}->
			hub_contains_deal($hub_parts[6]+0);

		    if ($#hub_parts == 7) {
			${$hash_ref}{$hub_parts[0]}->post_form($hub_parts[7]);
			my $post_ref =
			    ${$hash_ref}{$hub_parts[0]}->post_form();
			
			if (scalar(keys(%{$post_ref})) == 0) {
			    die "Error extracting post form in ".
				"getHubProperties\n";
			}
		    }
		}

		${$hash_ref}{$hub_parts[0]}->city_ids($hub_parts[2]+0);
	    }
	}

	my $log_msg = ($#hub_rows+1)." hubs rows read from Hubs table:\n".
	    scalar(keys(%{$hash_ref}))." unique hubs\n".
	    (1+$#hub_rows - $invalid_hub_rows)." valid rows.\n".
	    $invalid_hub_rows." invalid rows.";
	logger::LOG($log_msg, 2);
    }

    # Helper function for getHubProperties. See above. Makes sure a string
    # is splittable into key-value pairs, which represent the data for a 
    # post form.
    sub isValidPostForm {
	if (!@_) {
	    return 0;
	}
	my $string = shift;
	my @post_parts = split(/\s+/, $string);
	# Basically just check there is at least one key value pair
	# and that the number of parts of the post string is even.
	if ($#post_parts >= 1 && (($#post_parts+1)%2 == 0)) {
	    return 1;
	}

	return 0;
    }


    # This subroutine should only be run once, when the crawler is started
    sub getRecrawlableDealUrls  {
	if ($#_ != 1) { die "Incorrect usage of getRecrawlableDealUrls.\n"; }
	my $deal_properties_ref = $_[0];
	my $request = $webserver."get_recrawlable_deals.php?"."database=".
	    $database."&user=".$user."&password=".$password.
	    "&max_days=".$_[1];
	
	my $recrawlable_deals = get $request;
	
	if (!defined($recrawlable_deals)) {
	    die "Unable to obtain recrawlable deals in getRecrawlableDealUrls.".
		" Request [$request]\n";
	}
	
	my @recrawlable_deals = split(/\n/, $recrawlable_deals);
	my $invalid_recrawlable_deals = 0;
	my %dups;
	my $dup_count = 0;
	
	foreach my $row (@recrawlable_deals) {
	    my @parts = split(/,/, $row);
	    $parts[0] =~ s/\s//g;

	    if ($#parts != 3 ||
		$parts[0] !~ /^(((http|https):\/\/)?([[a-zA-Z0-9]\-\.])+(\.)([[a-zA-Z0-9]]){2,4}([[a-zA-Z0-9]\/+=%&_\.~?\-]*))*/ || # hub url
		$parts[1] !~ /^[1-9][0-9]*$/ || # company_id (not zero)
		$parts[2] !~ /^[01]$/ || # use_cookie (boolean)
		# discovered is in datetime format
		!crawlerutils::validDatetime($parts[3]))
	    {
		$invalid_recrawlable_deals++;
	    }
	    # Allow user of crawler to only crawl specific companies. This
	    # is useful for debugging crawler/extraction problems
	    elsif ($company_id_filter == 0 || $parts[1] == $company_id_filter) {
		${$deal_properties_ref}{$parts[0]} = dealproperties->new();
		${$deal_properties_ref}{$parts[0]}->url($parts[0]);
		${$deal_properties_ref}{$parts[0]}->company_id($parts[1]+0);
		${$deal_properties_ref}{$parts[0]}->use_cookie($parts[2]+0);
		${$deal_properties_ref}{$parts[0]}->discovered($parts[3]);
		
		# All urls selected by this method are recrawlable
		${$deal_properties_ref}{$parts[0]}->recrawl(1);
		
		if (!defined($dups{$parts[0]})) {
		    $dups{$parts[0]} = 1;
		} else {	
		    $dups{$parts[0]}++;
		    $dup_count++;
		}
	    }
	}
	
	my $log_msg = ($#recrawlable_deals+1).
	    " recrawlable deals read from Deals table:\n".
	    (1+$#recrawlable_deals - $invalid_recrawlable_deals)." valid rows.\n".
	    $invalid_recrawlable_deals." invalid rows. ".
	    $dup_count." duplicate recrawlable deals.\n";
	logger::LOG($log_msg, 2);
    }



    my $hostname = hostname;
    my $pid = $$;
    if (!defined($hostname) || !defined($pid)) {
	die "Unable to determine hostname or pid for this crawler.\n";
    }


    sub formLockRequest {
	my $action = shift;
	
	return $webserver."crawler_db_lock.php?action=$action".
	    "&database=".$database."&user=".$user."&password=".$password.
	    "&hostname=".$hostname."&pid=".$pid;
    }

    sub getDatabaseLock {
	my $request = &formLockRequest("getlock");
	my $content = get $request;

	if (!defined($content)) {
	    die "Error obtaining lock on database.\n";
	}
	my @array = split(/,/, $content);
	if ($#array != 1 ||
	    !($array[0] eq $hostname) ||
	    !($array[1] eq $pid)) {
	    die "Error obtaining lock on database. Reponse: [$content]";
	}
	
	logger::LOG("Successfully obtained lock on database.", 1);
    }


    sub releaseDatabaseLock {
	my $request = &formLockRequest("deletelock");
	my $content = get $request;

	logger::LOG("Releasing database lock. Response [$content]", 1);
    }
    
    1;
}


