#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package deal;
    use strict;
    use warnings;
    use dealproperties;
    use crawlerutils;

    sub new {
	my $self = {};

	$self->{url} = undef;
	$self->{recrawl} = undef;
	$self->{use_cookie} = undef;

	$self->{company_id} = undef;
	$self->{category_id} = undef;

	$self->{deadline} = undef; # when deal ends
	$self->{expires} = undef; # when deal voucher expires
	$self->{expired} = undef; # whether deal has expired
	$self->{title} = undef;
	$self->{subtitle} = undef;
	$self->{text} = undef;
	$self->{fine_print} = undef;
	$self->{price} = undef;
	$self->{value} = undef;
	$self->{num_purchased} = undef;
	$self->{image_url} = undef;

	$self->{name} = undef; # business name
	$self->{website} = undef;
	$self->{addresses} = ();
	$self->{phone} = undef;

	bless($self);
	return $self;
    }
    
    sub url {
	my $self = shift;
	if (@_) { $self->{url} = shift; }
	return $self->{url};
    }

    sub recrawl {
	my $self = shift;
	if (@_) { $self->{recrawl} = shift; }
	return $self->{recrawl};
    }

    sub use_cookie {
	my $self = shift;
	if (@_) { $self->{use_cookie} = shift; }
	return $self->{use_cookie};
    }

    sub company_id {
	my $self = shift;
	if (@_) { $self->{company_id} = shift; }
	return $self->{company_id};
    }

    sub title {
	my $self = shift;
	if (@_) { $self->{title} = shift; }
	return $self->{title};
    }

    sub subtitle {
	my $self = shift;
	if (@_) { $self->{subtitle} = shift; }
	return $self->{subtitle};
    }

    sub price {
	my $self = shift;
	if (@_) { $self->{price} = shift; }
	return $self->{price};
    }

    sub value {
	my $self = shift;
	if (@_) { $self->{value} = shift; }
	return $self->{value};
    }

    sub text {
	my $self = shift;
	if (@_) { $self->{text} = shift; }
	return $self->{text};
    }

    sub fine_print {
	my $self = shift;
	if (@_) { $self->{fine_print} = shift; }
	return $self->{fine_print};
    }

    sub num_purchased {
	my $self = shift;
	if (@_) { $self->{num_purchased} = shift; }
	return $self->{num_purchased};
    }

    sub deadline {
	my $self = shift;
	if (@_) { $self->{deadline} = shift; }
	return $self->{deadline};
    }

    sub expires {
	my $self = shift;
	if (@_) { $self->{expires} = shift; }
	return $self->{expires};
    }

    sub expired {
	my $self = shift;
	if (@_) { $self->{expired} = shift; }
	return $self->{expired};
    }

    sub image_url {
	my $self = shift;
	if (@_) { $self->{image_url} = shift; }
	return $self->{image_url};
    }

    sub name {
	my $self = shift;
	if (@_) { $self->{name} = shift; }
	return $self->{name};
    }

    sub website {
	my $self = shift;
	if (@_) { $self->{website} = shift; }
	return $self->{website};
    }

    sub addresses {
	my $self = shift;
	if (@_) { 
	    my $address = shift;
	    ${$self->{addresses}}{$address} = 1;
	}
	return \%{$self->{addresses}};
    }


    sub phone {
	my $self = shift;
	if (@_) { $self->{phone} = shift; }
	return $self->{phone};
    }


    sub inherit_from_deal_properties {
	my $self = shift;
	if (!@_) {
	    die "Invalid use of inherit_from_deal_properties. 2 args needed.\n";
	}

	my $deal_properties = shift;
	
	$self->{url} = $deal_properties->url();
	$self->{recrawl} = $deal_properties->recrawl();
	$self->{use_cookie} = $deal_properties->use_cookie();

	$self->{company_id} = $deal_properties->company_id();
	$self->{category_id} = $deal_properties->category_id();
    }


    sub cleanUp {
	my $self = shift;
	
	if (defined($self->{title})) {
	    $self->{title} =~ s/^\s+//;
	    $self->{title} =~ s/\s+$//;
	    $self->{title} =~ s/\s+/ /g;
	}
	if (defined($self->{subtitle})) {
	    $self->{subtitle} =~ s/^\s+//;
	    $self->{subtitle} =~ s/\s+$//;
	    $self->{subtitle} =~ s/\s+/ /g;
	}
	if (defined($self->{price})) {
	    $self->{price} =~ s/^\s+//;
	    $self->{price} =~ s/\s+$//;
	}
	if (defined($self->{value})) {
	    $self->{value} =~ s/^\s+//;
	    $self->{value} =~ s/\s+$//;
	}
	if (defined($self->{text})) {
	    $self->{text} =~ s/^\s+//;
	    $self->{text} =~ s/\s+$//;
	}

	if (defined($self->{fine_print})) {
	    $self->{fine_print} =~ s/^\s+//;
	    $self->{fine_print} =~ s/\s+$//;
	}

	if (defined($self->{expires})) {
	    $self->{expires} =~ s/^\s+//;
	    $self->{expires} =~ s/\s+$//;
	}


	if (defined($self->{deadline})) {
	    $self->{deadline} =~ s/^\s+//;
	    $self->{deadline} =~ s/\s+$//;
	}


	if (defined($self->{image_url})) {
	    $self->{image_url} =~ s/^\s+//;
	    $self->{image_url} =~ s/\s+$//;
	}

	if (defined($self->{name})) {
	    $self->{name} =~ s/^\s+//;
	    $self->{name} =~ s/\s+$//;
	    $self->{title} =~ s/\s+/ /g;
	}
	if (defined($self->{website})) {
	    $self->{website} =~ s/^\s+//;
	    $self->{website} =~ s/\s+$//;
	}
	if (defined($self->{phone})) {
	    $self->{phone} =~ s/^\s+//;
	    $self->{phone} =~ s/\s+$//;
	}

	foreach my $address (keys %{$self->{addresses}}) {
	    $address =~ s/^\s+//;
	    $address =~ s/\s+$//;
	    $address =~ s/\s+/ /g;
	}
    }


    sub check_for_extraction_error {
	my $self = shift;

	if (!defined($self->url()) ||
	    $self->{url} !~ /^http[s]?:\/\/.*/) {
	    return "url";
	}

	if (!defined($self->{company_id}) ||
	    $self->{company_id} !~ /^[0-9]+$/) {
	    return "company_id";
	}

	if (!defined($self->{recrawl}) ||
	    $self->{recrawl} !~ /^[01]$/) {
	    return "recrawl";
	}

	if (!defined($self->{use_cookie}) ||
	    $self->{use_cookie} !~ /^[01]$/) {
	    return "use cookie";
	}

	if (!defined($self->{title}) || length($self->title) < 5) {
	    return "title";
	} 
	
	if (!defined($self->{price}) ||
	    $self->{price} !~ /^[0-9]*\.?[0-9]+$/) {
	    return "price";
	}

	if (!defined($self->{value}) ||
	    $self->{value} !~ /^[0-9]*\.?[0-9]+$/) {
	    return "value";
	}
	
	if (!defined($self->{num_purchased}) ||
	    $self->{num_purchased} !~ /^-?[0-9]+$/) {
	    return "num purchased";
	}
	
	if (!defined($self->{expired}) || !$self->{expired}) {
	    if (!defined($self->{deadline}) ||
		!crawlerutils::validDatetime($self->{deadline}))
	    {
		return "deadline";
	    }
	}

	if (!defined($self->{expires}) ||
	    !crawlerutils::validDatetime($self->{expires}))
	{
	    return "expires";
	}
	
	if (!defined($self->image_url()) ||
	    $self->{image_url} !~ /^http[s]?:\/\/.*/) {
	    return "image url";
	}
	
	if (!defined($self->{text}) || length($self->{text}) < 20) {
	    return "text";
	} 

	if (!defined($self->{fine_print}) || length($self->{fine_print}) < 20) {
	    return "fine print";
	}


	if (!defined($self->{name}) || length($self->name) < 5) {
	    return "name";
	} 

	if (!defined($self->website()) ||
	    $self->{website} !~ /^http[s]?:\/\/.*/) {
	    return "website";
	}

	# TODO: get rid of the != 3 check. just a hack because
	# buywithme (company_id == 3) never has phone numbers.
	if ($self->{company_id} != 3 &&
	    (!defined($self->{phone})  ||
	     $self->{phone} !~
	     /[0-9]{3}[^0-9]{0,2}[0-9]{3}[^0-9]{0,2}[0-9]{4}/)) {
	    return "phone";
	}
	
	if (scalar(keys(%{$self->{addresses}})) == 0) {
	    return "addresses";
	}

	return undef;
    }


    1;
}

