package Whada::Engine;

use strict;
use warnings;
use Carp;

use Log::Minimal;

use Whada::PrivStore;

# check authorized or not, but not check authenticated or not.
sub authorize {
    shift;
    my $opts = {@_};
    my $credential = $opts->{credential};
    my $dictionary = $opts->{dictionary};
    my $logger = $opts->{logger};
    croak 'credential not found' unless $credential;
    croak 'dictionary not found' unless $dictionary;
    croak 'failed to init logger' unless $logger;

    return drive($credential, $logger, 0, sub {
                     return $dictionary->entry(shift);
                 });
}

# check authorized or not, and also check authenticated or not.
sub authenticate {
    shift;
    my $opts = {@_};
    my $credential = $opts->{credential};
    my $dictionary = $opts->{dictionary};
    my $logger = $opts->{logger};
    croak 'credential not found' unless $credential;
    croak 'dictionary not found' unless $dictionary;
    croak 'failed to init logger' unless $logger;

    return drive($credential, $logger, 1, sub {
                     return $dictionary->authenticate(shift);
                 });
}

# check username exists or not by credential from dictionary
sub search {
    shift; # throw package name away
    my $opts = {@_};
    my $credential = $opts->{credential};
    my $dictionary = $opts->{dictionary};
    return 1 if $dictionary->entry($credential);
    return undef;
}

sub drive {
    my ($credential, $logger, $with_authentication, $sub) = @_;

    my $authorized_check = Whada::PrivStore->check($credential);
    my $authorized = 0;
    my $entry = undef;

    if (defined $authorized_check && $authorized_check) {
        $authorized = 1;
        $entry = $sub->($credential);
    }
    elsif (defined $authorized_check) {
        # not authorized
        $entry = undef;
    }
    elsif (Whada::PrivStore->global_default_privilege) {
        $authorized = 1;
        $entry = $sub->($credential);
    }
    else {
        # not authorized
        $entry = undef;
    }

    if ($authorized and $entry and $with_authentication) {
        $logger->logging($credential, 'successed');
    }
    if ($authorized and $entry) {
        if (scalar(@$entry) > 1) {
            $logger->logging($credential, "2 or more entries found about credential");
            $entry = undef;
        }
        else {
            $logger->logging($credential, 'authorized (without password verification)');
        }
    }
    elsif ($authorized) {
        $logger->logging($credential, 'authentication failed');
    }
    else {
        $logger->logging($credential, 'not authorized');
    }
    return $entry && $entry->[0];
}

1;

