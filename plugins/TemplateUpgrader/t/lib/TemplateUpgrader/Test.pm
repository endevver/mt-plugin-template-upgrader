package TemplateUpgrader::Test;
use strict; use warnings; use Carp; use Data::Dumper;
use IPC::Open2;
# use SelfLoader;
require POSIX;
use JSON -support_by_pp;
use Test::More;
use lib qw( plugins/TemplateUpgrader/t/lib
            plugins/TemplateUpgrader/lib
            plugins/TemplateUpgrader/extlib
            t/lib  lib  extlib );
use TemplateUpgrader;

# use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

use base qw( Class::Data::Inheritable );

$| = 1;

sub run_data_tests {
    my $pkg = shift;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    my $report = sub {
        my $marker = (' 'x9).('*'x4).' ';
        return $marker.($_[0] ? 'PASS' : 'FAIL').(reverse $marker);
    };
    
    my $upgrader = TemplateUpgrader->new();
    ###l4p $logger->debug('$upgrader: ', l4mtdump($upgrader));

    my $num = 1;
    while ( defined( my $test = $pkg->get_test() ) ) {
         if ( $test->{r} ) {

            my $result = $upgrader->upgrade( $test->{t} );
            my $pass   = is( $result, $test->{e}, "perl test " . $num++ );

            ###l4p $logger->debug( 'NEXT TEST for '. $pkg );
            ###l4p $logger->debug( '    GIVEN: '. $test->{t} );
            ###l4p $logger->debug( ' EXPECTED: ', $test->{e} );
            ###l4p $logger->debug( '      GOT: ', $result );
            ###l4p $logger->debug( $report->($pass) );
        }
        else {
            ###l4p $logger->debug('SKIPPING TEST: '.$test->{t} );
            pass("perl test skip " . $num++);
        }
    }
}

{
    my $test_suite;
    sub get_test {
        my $pkg = shift;
        $pkg->init_test_data() unless $test_suite;
        shift @$test_suite if @$test_suite;
    }

    sub init_test_data {
        my $pkg = shift;
        my $json = new JSON;
        $json->loose(1); # allows newlines inside strings
        $test_suite = $json->decode($pkg->_test_data());
        push(@$test_suite, undef);  # Stopper/reset value
        # print Dumper($test_suite);
        # Ok. We are now ready to test!
        plan tests => (scalar(@$test_suite)) -1;
        $test_suite;
    }

    sub _test_data {
        my $pkg = shift;
        my $filehandle = (ref $pkg || $pkg).'::DATA';
        local $/       = undef;
        local $_       = eval "<$filehandle>";
        # Remove our comments
        s{^ *#.*$}{}mg;
        s{# *\d+ *(?:TBD.*)? *$}{}mg;
        return $_;
    }
}

1;

__END__

# Structure of a node:
#   [0] = tag name
#   [1] = attribute hashref
#   [2] = contained tokens
#   [3] = template text
#   [4] = attributes arrayref
#   [5] = parent array reference
#   [6] = containing template

