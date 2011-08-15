#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package getargs;
    
    use strict;
    use warnings;
    use Getopt::Long qw(GetOptionsFromArray);

    sub getCrawlerArgs {
	if ($#_ != 4) {
	    die "Incorrect number of arguments in getCrawlerArgs.\n"; 
	}
	my $webserver_ref = shift;
	my $database_ref = shift;
	my $user_ref = shift;
	my $password_ref = shift;
	my $company_id_ref = shift;
	$$company_id_ref=0; # default

	my @args = @ARGV; # To avoid GetOptions deleting @ARGV
	my $result = GetOptionsFromArray(\@args,
					 "webserver=s" => $webserver_ref,
					 "database=s" => $database_ref,
					 "user=s" => $user_ref,
					 "password=s" => $password_ref,
					 "company_id=i" => $company_id_ref);
	
	if (!defined($$webserver_ref) || !defined($$database_ref) ||
	    !defined($$user_ref) || !defined($$password_ref)) {
	    die "Web server (include trailing /), database, user or user ".
		"password not specified. Use options --webserver, --database, ".
		"--user and --password\n";
	}
    }


    sub getBasicArgs {
	if ($#_ != 3) {
	    die "Incorrect number of arguments in getBasicArgs.\n"; 
	}
	my $webserver_ref = shift;
	my $database_ref = shift;
	my $user_ref = shift;
	my $password_ref = shift;

	my @args = @ARGV; # To avoid GetOptions deleting @ARGV
	my $result = GetOptionsFromArray(\@args,
					 "webserver=s" => $webserver_ref,
					 "database=s" => $database_ref,
					 "user=s" => $user_ref,
					 "password=s" => $password_ref);
	
	if (!defined($$webserver_ref) || !defined($$database_ref) ||
	    !defined($$user_ref) || !defined($$password_ref)) {
	    die "Web server (include trailing /), database, user or user ".
		"password not specified. Use options --webserver, --database, ".
		"--user and --password\n";
	}
    }

    1;
}
