#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package dealextractor;
    
    use strict;
    use warnings;
    use deal;
    use logger;
    use grouponextractor;
    use livingsocialextractor;
    use buywithmeextractor;
    use tipprextractor;
    use travelzooextractor;
    use angieslistextractor;
    use giltcityextractor;
    use yollarextractor;
    use zoziextractor;
    use bloomspotextractor;
    use scoutmobextractor;
    use amazonlocalextractor;


    my %company_to_extractor_map;

    $company_to_extractor_map{1} = \&grouponextractor::extract;
    $company_to_extractor_map{2} = \&livingsocialextractor::extract;
    $company_to_extractor_map{3} = \&buywithmeextractor::extract;
    $company_to_extractor_map{4} = \&tipprextractor::extract;
    $company_to_extractor_map{5} = \&travelzooextractor::extract;
    $company_to_extractor_map{6} = \&angieslistextractor::extract;
    $company_to_extractor_map{7} = \&giltcityextractor::extract;
    $company_to_extractor_map{8} = \&yollarextractor::extract;
    $company_to_extractor_map{9} = \&zoziextractor::extract;
    $company_to_extractor_map{10} = \&bloomspotextractor::extract;
    $company_to_extractor_map{11} = \&scoutmobextractor::extract;
    $company_to_extractor_map{12} = \&amazonlocalextractor::extract;

    sub extractDeal {
	if ($#_ != 1) { die "Incorrect usage of extractDeal, need 2 ".
			    "arguments\n"; }
	my $deal = shift;
	my $deal_content_ref = shift;

	if (!defined($deal->company_id())) {
	    die "Incorrect usage of extractDeal, company_id of deal ".
		"isn't set\n";
	}

	if (defined($company_to_extractor_map{$deal->company_id()}))
	{
	    &{$company_to_extractor_map{$deal->company_id()}}
	    ($deal, $deal_content_ref);
	    $deal->cleanUp();
	} else {
	    logger::LOG("No deal extractor registered for company_id : ".
			$deal->company_id(), 0);
	}
    }

    1;
}
