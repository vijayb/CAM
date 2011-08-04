#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    use strict;
    use warnings;
    use deal;
    use dealextractor;
    use crawlerutils;

    use Getopt::Long qw(GetOptionsFromArray);

    my %domain_to_id_map;
    
    # In the crawler the company_id() is obtained from the hub pointing
    # to the deal page. Since deal_extractor_tester.pl won't have
    # the hub in offline mode, the way to specify the company_id is by
    # manually mapping the domain of the website to its company_id()
    # To test new extractors add to the domain map below.
    # The additions should correspond to the map in dealextractor.pm
    $domain_to_id_map{"http://groupon.com"} = 1;
    $domain_to_id_map{"http://www.groupon.com"} = 1;
    $domain_to_id_map{"http://livingsocial.com"} = 2;
    $domain_to_id_map{"http://www.livingsocial.com"} = 2;
    $domain_to_id_map{"http://buywithme.com"} = 3;
    $domain_to_id_map{"http://www.buywithme.com"} = 3;
    $domain_to_id_map{"http://tippr.com"} = 4;
    $domain_to_id_map{"http://www.tippr.com"} = 4;
    $domain_to_id_map{"https://www.tippr.com"} = 4;
    $domain_to_id_map{"https://tippr.com"} = 4;


    my ($deal_directory, $company_id, $deal_file);
    my ($verbose, $skiperrors, $numerrors, $numwarnings, $total_deal_pages);

    my $result = GetOptionsFromArray(\@ARGV,
				     "directory=s" => \$deal_directory,
				     "company_id=i" => \$company_id,
				     "file=s" => \$deal_file,
				     "verbose=i" => \$verbose,
				     "skiperrors=i" => \$skiperrors);

    if (!defined($verbose)) { $verbose = 0; }
    if (!defined($skiperrors)) { $skiperrors = 0; }
    $numerrors = 0;
    $numwarnings = 0;
    $total_deal_pages = 0;

    if (defined($deal_directory)) {
	my $list_cmd = "find ".$deal_directory." -mindepth 1 -maxdepth 1";
	my @deal_files = `$list_cmd`;

	foreach my $deal_file (@deal_files) {
	    extractFile($deal_file);
	}
    } elsif (defined($deal_file)) {
	extractFile($deal_file);
    } else {
	die "Error: you need to specify a directory containing deals using ".
	    "--directory=... or you need to specify a deal file using ".
	    "--file=...\n";
    }

    print "Total deals pages : $total_deal_pages\n";
    print "Total errors      : $numerrors\n";
    print "Total warnings    : $numwarnings\n";

    sub extractFile {
	my $file = shift;
	chomp($file);
	my $filehandle;
	    
	if (open($filehandle, $file)) {
	    my $url;
	    my $timestamp;
	    my $content;
	    my $domain;
	    
	    # First line in a cache entry will be a timestamp
	    # and the url for the content that follows in
	    # subsequent lines. They will be comma separated.
	    # E.g., 1310258023,http://tippr.com/seattle/
	    my $line = <$filehandle>;
	    if (defined($line) &&
		$line =~ /^([0-9]+),(.+)$/) {
		$timestamp = $1 + 0;
		$url = $2;

		while ($line=<$filehandle>) {
		    $content = $content.$line;
		}

		if ($url =~ /(http[s]?:\/\/[^\/]+)/ &&
		    defined($domain_to_id_map{$1})) {
		    $domain = $1;
		} else {
		    dieN("Couldn't extract domain from: [$url] or domain ".
			"has no id mapping.\n");
		}

		if (defined($company_id) &&
		    $domain_to_id_map{$domain} != $company_id) {
		    return;
		}

		
		$total_deal_pages++;
		# We only want to run deal extraction on deal pages
		print "$url\n";
		print "$file\n";
		my ($year, $month, $day, $hour, $minute, $second);
		($year, $month, $day, $hour, $minute, $second) =
		    (localtime($timestamp))[5,4,3,2,1,0];
		$month+=1; # localtime range for month is 0..11
		$year+=1900;
		print "Crawled $day/$month/$year $hour:$minute:$second\n";
		
		my $deal = deal->new();
		$deal->url($url);
		
		$deal->company_id($domain_to_id_map{$domain});
		
		dealextractor::extractDeal($deal, \$content);
		
		if (defined($deal->title())) {
		    printV("Title: [".$deal->title()."]\n", 1);
		} else {
		    dieN("Error extracting title\n");
		}
		
		if (defined($deal->subtitle())) {
		    printV("Subtitle: [".$deal->subtitle()."]\n", 1);
		} else {
		    warnN("Error extracting subtitle\n");
		}
		
		if (defined($deal->price()) &&
		    $deal->price() =~ /^[0-9]*\.?[0-9]+$/) {
		    printV("Price: \$".$deal->price()."\n", 1);
		} else {
		    dieN("Error extracting price\n");
		}
		
		if (defined($deal->value()) &&
		    $deal->value() =~ /^[0-9]*\.?[0-9]+$/) {
		    printV("Value: \$".$deal->value()."\n", 1);
		} else {
		    dieN("Error extracting value\n");
		}

		if (defined($deal->price()) && defined($deal->value())) {
		    my $discount = 
			100.0*($deal->value() - $deal->price())/$deal->value();
		    printV(sprintf("Discount: %.0f%% off\n", $discount), 1);
		} else {
		    printV("Unable to calculated discount, either price or ".
			   "value are undefined\n", 1);
		}
		
		if (defined($deal->num_purchased()) &&
		    $deal->num_purchased =~ /^-?[0-9]+$/) {
		    printV("Num purchased: ".$deal->num_purchased()."\n", 1);
		} else {
		    warnN("Error extracting num_purchased\n");
		}
		
		if (defined($deal->expired())) {
		    printV("Deal is expired\n", 1);
		} else {
		    if (defined($deal->deadline()) &&
			crawlerutils::validDatetime($deal->deadline()))
		    {
			printV("Deal deadline: [".$deal->deadline()."]\n",
			       1);
		    } else {
			dieN("Error extracting deal deadline\n");
		    }
		}
		
		if (defined($deal->expires()) &&
		    crawlerutils::validDatetime($deal->expires()))
		{
		    printV("Deal expires : [".$deal->expires()."]\n", 1);
		} else {
		    dieN("Error extracting deal expires\n");
		}
		
		if (defined($deal->image_url())) {
		    printV("Image URL: [".$deal->image_url()."]\n", 1);
		} else {
		    dieN("Error extracting image url\n");
		}
		
		if (defined($deal->text())) {
		    printV("Deal text length: ".length($deal->text()).
			   "\n", 1);
		    printV("Text: [".$deal->text()."]\n", 3);
		} else {
		    dieN("Error extracting deal text\n");
		}
		
		if (defined($deal->fine_print())) {
		    printV("Deal fine print length: ".
			   length($deal->fine_print())."\n", 1);
		    printV("Fine print: [".$deal->fine_print()."]\n", 2);
		} else {
		    dieN("Error extracting deal fine print\n");
		}
		
		if (defined($deal->website())) {
		    printV("Website: [".$deal->website()."]\n", 1);
		} else {
		    dieN("Error extracting website url\n");
		}

		if (defined($deal->name())) {
		    printV("Business name: [".$deal->name()."]\n", 1);
		} else {
		    dieN("Error extracting business name\n");
		}

		if (defined($deal->phone())) {
		    printV("Business phone: [".$deal->phone()."]\n", 1);
		} else {
		    warnN("Warning: unable to extract business phone\n");
		}

		my $addresses_ref = $deal->addresses();
		my $address_count = scalar(keys(%{$addresses_ref}));
		if ($address_count > 0) {
		    printV("Extracted $address_count addresses:\n", 1);
		    foreach my $address (keys %{$addresses_ref}) {
			printV("    - [$address]\n", 1);
		    }
		} else {
		    dieN("Error extracting any addresses\n");
		}


		print "\n";
	    }
	    close($filehandle);
	}
    }

    sub dieN {
	$numerrors++;
	if (@_) {
	    my ($message) = shift;
	    print $message;

	    if ($numerrors <= $skiperrors) {
		print "Num errors $numerrors, skipping this error\n";
	    } else {
		die;
	    }
	}
    }

    sub warnN {
	$numwarnings++;
	if (@_) {
	    my ($message) = shift;
	    print $message;
	}
    }

    sub printV {
	if ($#_ != 1) { die "Error using printV\n"; }

	my $message = shift;
	my $print_level = 0 + shift;

	if ($print_level <= $verbose) {
	    print $message;
	}
    }

    1;
}


