package TemplateUpgrader::Test;

use strict;
use lib qw( t/lib   plugins/TemplateUpgrader/lib
            plugins/TemplateUpgrader/extlib lib extlib );

            # use lib qw( plugins/TemplateUpgrader/t/lib   t/lib
            #             plugins/TemplateUpgrader/lib
            #             plugins/TemplateUpgrader/extlib 
            #             lib 
            #             extlib );

use IPC::Open2;
use SelfLoader;
use Data::Dumper;

$| = 1;

# use MT::Test qw(:db :data);
use Test::More;
use JSON -support_by_pp;
use MT;
# use MT::Util qw(ts2epoch epoch2ts);
use MT::Template::Context;
use MT::Builder;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

require POSIX;

sub run {
    my $class = shift;
    my $num = 1;

    my $mt  = MT->new();
    my $ctx = MT::Template::Context->new;
    $ctx->stash('builder', MT::Builder->new);

    while ( defined( my $test = $class->get_test() ) ) {
        # print STDERR Dumper($test);
        unless ($test->{r}) {
            pass("perl test skip " . $num++);
            next;
        }
        # my $result = build($ctx, $test->{t});
        my $result = $class->transform($ctx, $test->{t});
        is($result, $test->{e}, "perl test " . $num++);
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
        my $class      = shift;
        my $filehandle = (ref $class || $class).'::DATA';
        local $/       = undef;
        local $_ = <$filehandle>;
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
    my $class = shift;
    my ( $ctx, $markup ) = @_;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    my $handlers ||= MT->registry('tag_upgrade_handlers') || {};
$logger->debug('$handlers: ', l4mtdump($handlers));

    use TemplateUpgrader;
    my $upgrader = TemplateUpgrader->new({ handlers => $handlers });
    return $upgrader->upgrade( ref $markup ? $markup : \$markup );
}


1;