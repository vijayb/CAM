#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    package getargs;
    
    use strict;
    use warnings;
    use Getopt::Long qw(GetOptionsFromArray);

    sub get {
	if ($#_ != 3) { die "Incorrect number of arguments in getargs.\n"; }
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
