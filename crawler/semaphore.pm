#!/usr/bin/perl -w
# Copyright (c) 2010, All Rights Reserved
# Author: Vijay Boyapati (vijayb@gmail.com) July, 2010
#
{
    # Package for getting asynchronous write locks on a specified file
    package semaphore;
    use strict;
    use Fcntl qw (:flock);
    use warnings;
    use Symbol;
    
    my (%lock_hash);

    sub openLock {
	$#_ == 1 or die
	    "openLock() needs 2 arguments: lock file name, " .
	    "and write type: '>' (write) or '>>' (append)\n";

	# Use of gensym prevents file handles stomping on each other
	# apparently (or maybe not?? - more research needed)
	my $filehandle; # = gensym;
	open $filehandle, $_[1].$_[0] or return 0;
	unless (flock($filehandle, LOCK_EX|LOCK_NB)) {
	    return 0;
	}
	
	$lock_hash{$_[0]} = $filehandle;
	return 1;
    }

    sub openAppendLockReturnFileHandle {
	my $val = openLock($_[0], ">>");

	${$_[1]} = $lock_hash{$_[0]};
	
	return $val;
    }

    sub openWriteLockReturnFileHandle {
	my $val = openLock($_[0], ">");

	${$_[1]} = $lock_hash{$_[0]};
	
	return $val;
    }


    sub closeLock {
	my ($tmp_file_handle);
	$#_ == 0 or die "closeLock() needs the lock file as an argument.\n";

	defined($lock_hash{$_[0]}) or return 0;

	$tmp_file_handle = $lock_hash{$_[0]};
	delete($lock_hash{$_[0]});

	close $tmp_file_handle or return 0;

	return 1;
    }

    1;
}
