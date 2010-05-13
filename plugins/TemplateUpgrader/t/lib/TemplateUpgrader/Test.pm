package TemplateUpgrader::Test;

use strict;
use warnings;
use lib qw( plugins/TemplateUpgrader/t/lib
            plugins/TemplateUpgrader/lib
            plugins/TemplateUpgrader/extlib
            t/lib  lib  extlib );

use IPC::Open2;
# use SelfLoader;
require POSIX;
use JSON -support_by_pp;
use Data::Dumper;

# use MT::Test qw(:db :data);
use Test::More;
use MT;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

use base qw( Class::Data::Inheritable );
__PACKAGE__->mk_classdata(qw( handlers ));

$| = 1;

sub run {
    my $class = shift;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    my $num = 1;
    # my $mt  = MT->new();
    my $mt = MT->instance( Config => 'mt-config.cgi' ) or die MT->errstr;
    my $registry = $mt->registry()
        or die "Failed initialization of MT registry";

    unless ( $class->handlers ) {
        $class->handlers( $registry->{tag_upgrade_handlers} || {} );
        ###l4p $logger->debug('$class->handlers: ', l4mtdump($class->handlers));
    }

    # Add in our templateupgrader_template object type
    # which is a subclass of MT::Template
    # $registry->{object_types}{templateupgrader_template}
    #     = 'TemplateUpgrader::Template';

    # my $tmpl_class = MT->model('templateupgrader_template');
    # $TemplateUpgrader::Template::ORIG_NEW_METHOD
    #     = MT->model('template')->can('new');
    # 
    # my $rc = Sub::Install::reinstall_sub({
    #     code => '_new',
    #     from => $tmpl_class,
    #     into => 'MT::Template',
    #     as   => 'new',
    # });
    # 
    # my $tmpl = MT::Template->new();
    # die $tmpl;


    my $report = sub {
        my $marker = (' 'x9).('*'x4).' ';
        return $marker.($_[0] ? 'PASS' : 'FAIL').(reverse $marker);
    };
    
    require TemplateUpgrader;
    my $upgrader = TemplateUpgrader->new({ handlers => $class->handlers });
    while ( defined( my $test = $class->get_test() ) ) {
         if ( $test->{r} ) {

            # my $result = $class->transform( $test->{t} );
            my $result = $upgrader->upgrade( $test->{t} );
            my $pass   = is( $result, $test->{e}, "perl test " . $num++ );

            ###l4p $logger->debug( 'NEXT TEST for '. $class );
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
        my $class = shift;
        $class->init_test_data() unless $test_suite;
        shift @$test_suite if @$test_suite;
    }

    sub init_test_data {
        my $class = shift;
        my $json = new JSON;
        $json->loose(1); # allows newlines inside strings
        $test_suite = $json->decode($class->_test_data());
        push(@$test_suite, undef);  # Stopper/reset value
        # print Dumper($test_suite);
        # Ok. We are now ready to test!
        plan tests => (scalar(@$test_suite)) -1;
        $test_suite;
    }

    sub _test_data {
        my $class = shift;
        my $filehandle = (ref $class || $class).'::DATA';
        local $/       = undef;
        local $_       = eval "<$filehandle>";
        # Remove our comments
        s{^ *#.*$}{}mg;
        s{# *\d+ *(?:TBD.*)? *$}{}mg;
        return $_;
    }
}

# sub build {
#     my($ctx, $markup) = @_;
#     my $b = $ctx->stash('builder');
#     my $tokens = $b->compile($ctx, $markup);
#     print('# -- error compiling: ' . $b->errstr), return undef
#         unless defined $tokens;
#     my $res = $b->build($ctx, $tokens);
#     print '# -- error building: ' . ($b->errstr ? $b->errstr : '') . "\n"
#         unless defined $res;
#     return $res;
# }

# my $markup =<<EOF;
# <mt:SetVarBlock name="woottang">
#     Wheeeee!
# </mt:SetVarBlock>
# EOF

sub transform {
    my ( $class, $markup ) = @_;
    my $upgrader = TemplateUpgrader->new({ handlers => $class->handlers });
    my $result = $upgrader->upgrade( $markup );
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

