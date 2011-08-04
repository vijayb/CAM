#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package genericextractor;
    
    use strict;
    use warnings;
    use deal;
    use logger;

    my @state_abbreviations = ('AK', 'AL', 'AR', 'AZ', 'CA', 'CO', 'CT', 'DC',
			       'DE', 'FL', 'GA', 'HI', 'IA', 'ID', 'IL', 'IN',
			       'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN',
			       'MO', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ',
			       'NM', 'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'RI',
			       'SC', 'SD', 'TN', 'TX', 'UT', 'VA', 'VT', 'WA',
			       'WI', 'WV', 'WY');

    my @state_names = ('ALABAMA', 'ALASKA', 'ARIZONA', 'ARKANSAS',
		       'CALIFORNIA', 'COLORADO', 'CONNECTICUT', 'DELAWARE',
		       'FLORIDA', 'GEORGIA', 'HAWAII', 'IDAHO', 'ILLINOIS',
		       'INDIANA', 'IOWA', 'KANSAS', 'KENTUCKY', 'LOUISIANA',
		       'MAINE', 'MARYLAND', 'MASSACHUSETTS', 'MICHIGAN',
		       'MINNESOTA', 'MISSISSIPPI', 'MISSOURI', 'MONTANA',
		       'NEBRASKA', 'NEVADA', 'NEW HAMPSHIRE', 'NEW JERSEY',
		       'NEW MEXICO', 'NEW YORK', 'NORTH CAROLINA',
		       'NORTH DAKOTA', 'OHIO', 'OKLAHOMA', 'OREGON',
		       'PENNSYLVANIA', 'RHODE ISLAND', 'SOUTH CAROLINA',
		       'SOUTH DAKOTA', 'TENNESSEE', 'TEXAS', 'UTAH', 'VERMONT',
		       'VIRGINIA', 'WASHINGTON', 'WEST VIRGINIA', 'WISCONSIN',
		       'WYOMING');

    my %states;
    foreach my $state (@state_abbreviations, @state_names) {
	$states{$state} = 1;
    }

    sub isState {
	if (@_) {
	    return defined($states{uc($_[0])});
	}

	return 0;
    }

    sub containsPattern {
	if ($#_ != 1) { die "Incorrect usage of containsPattern\n"; }

	my $deal_content_ref = shift;
	my $pattern = shift;

	my $regex = eval { qr/$pattern/ };
	if (!defined($regex)) {
	    die "Unable to parse regex $pattern in containsPattern\n";
	}

	my @lines = split(/\n/, $$deal_content_ref);
	my $match;
	foreach my $line (@lines) {
	    if ($line =~ /$regex/) {
		return 1;
	    }
	}

	return 0;
    }

    sub extractFirstPatternMatched {
	if ($#_ < 1) { die "Incorrect usage of extractFirstPatternMatched\n"; }

	my $deal_content_ref = shift;
	my $pattern = shift;

	my $regex = eval { qr/$pattern/ };
	if (!defined($regex)) {
	    die "Unable to parse regex $pattern in ".
		"extractFirstPatternMatched\n";
	}

	my @lines = split(/\n/, $$deal_content_ref);
	my $match;
	foreach my $line (@lines) {
	    if ($line =~ /$regex/) {
		$match = $1;
		last;
	    }
	}

	if (defined($match) && @_) {
	    foreach my $filter (@_) {
		$match =~ s/$filter//g;
	    }
	}
	return $match;
    }

    sub extractMPatterns {
	if ($#_ < 2) { die "Incorrect usage of extractMPatterns\n"; }

	my $max_matches = shift;
	my $deal_content_ref = shift;
	my $pattern = shift;

	my $regex = eval { qr/$pattern/ };
	if (!defined($regex)) {
	    die "Unable to parse regex $pattern in extractMPatterns\n";
	}

	my @lines = split(/\n/, $$deal_content_ref);
	my @matches;
	foreach my $line (@lines) {
	    if ($line =~ /$regex/) {
		push(@matches, $1);
	    }
	}

	if (@_) {
	    foreach my $filter (@_) {
		foreach my $match (@matches) {
		    $match =~ s/$filter//g;
		}
	    }
	}

	return @matches;
    }


    sub extractBetweenPatterns {
	extractBetweenPatternsN(-1, @_);
    }

    sub extractBetweenPatternsN {
	if ($#_ < 3) { die "Incorrect usage of extractBetweenPatternsN\n"; }

	my $max_lines = shift;	
	my $deal_content_ref = shift;
	my $start_pattern = shift;
	my $end_pattern = shift;


	my $start_regex = eval { qr/$start_pattern/ };
	my $end_regex = eval { qr/$end_pattern/ };
	if (!defined($start_regex) || !defined($end_regex)) {
	    die "Unable to parse regexs provided to extractBetweenPatterns.\n";
	}

	my @lines = split(/\n/, $$deal_content_ref);
	my $match;
	my $start = 0;
	my $num_lines = 0;
	foreach my $line (@lines) {
	    if ($start && $line =~ /$end_regex/) {
		last;
	    }
	    if ($start) {
		if (!defined($match)) {
		    $match = $line."\n";
		} else {
		    $match = $match.$line."\n";
		}
		$num_lines++;
	    }
	    if ($line =~ /$start_regex/) {
		$start = 1;
	    }

	    if ($max_lines > 0 && $num_lines >= $max_lines) {
		last;
	    }
	}

	if (defined($match) && @_) {
	    foreach my $filter (@_) {
		$match =~ s/$filter//g;
	    }
	}
	return $match;
    }



    sub extractMBetweenPatternsN {
	if ($#_ < 4) { die "Incorrect usage of extractMBetweenPatternsN\n"; }

	my $max_matches = shift;
	my $max_lines = shift;	
	my $deal_content_ref = shift;
	my $start_pattern = shift;
	my $end_pattern = shift;


	my $start_regex = eval { qr/$start_pattern/ };
	my $end_regex = eval { qr/$end_pattern/ };
	if (!defined($start_regex) || !defined($end_regex)) {
	    die "Unable to parse regexs provided to extractMBetweenPatterns.\n";
	}

	my @lines = split(/\n/, $$deal_content_ref);
	my @matches;
	my $match;
	my $start = 0;
	my $num_lines = 0;
	foreach my $line (@lines) {
	    if ($start) {
		if ($line =~ /$end_regex/ || 
		    ($max_lines > 0 && $num_lines >= $max_lines)) {
		    if (defined($match) && @_) {
			foreach my $filter (@_) {
			    $match =~ s/$filter//g;
			}
		    }
		    
		    push(@matches, $match);

		    $start = 0;
		    $num_lines = 0;
		    undef $match;
		}
	    }

	    if ($#matches >= $max_matches - 1) {
		last;
	    }

	    if ($start) {
		if (!defined($match)) {
		    $match = $line;
		} else {
		    $match = $match.$line;
		}
		$num_lines++;
	    }
	    if ($line =~ /$start_regex/ && $start==0) {
		$start = 1;
	    }
	}

	return @matches;
    }

    1;
}
