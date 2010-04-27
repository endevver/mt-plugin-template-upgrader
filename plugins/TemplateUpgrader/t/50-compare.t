#!/usr/bin/perl -w

package TemplateUpgrader::Test::Compare;

use strict;
use lib qw( t/lib   plugins/TemplateUpgrader/lib
            plugins/TemplateUpgrader/extlib lib extlib );
# use lib 't/lib', 'extlib', 'lib', '../lib', '../extlib';

use IPC::Open2;
use SelfLoader;
use Data::Dumper;

# BEGIN {
#     $ENV{MT_CONFIG} = 'mysql-test.cfg';
# }

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

my $mt = MT->new();

# my $blog_name_tmpl = MT::Template->load({name => "blog-name", blog_id => 1});
# ok($blog_name_tmpl, "'blog-name' template found");
# 
my $ctx = MT::Template::Context->new;
# my $blog = MT::Blog->load(1);
# ok($blog, "Test blog loaded");
# $ctx->stash('blog', $blog);
# $ctx->stash('blog_id', $blog->id);
$ctx->stash('builder', MT::Builder->new);

# my $entry  = MT::Entry->load( 1 );
# ok($entry, "Test entry loaded");
# 
# # entry we want to capture is dated: 19780131074500
# my $tsdiff = time - ts2epoch($blog, '19780131074500');
# my $daysdiff = int($tsdiff / (60 * 60 * 24));
# my %const = (
#     CFG_FILE => MT->instance->{cfg_file},
#     VERSION_ID => MT->instance->version_id,
#     CURRENT_WORKING_DIRECTORY => MT->instance->server_path,
#     STATIC_CONSTANT => '1',
#     DYNAMIC_CONSTANT => '',
#     DAYS_CONSTANT1 => $daysdiff + 1,
#     DAYS_CONSTANT2 => $daysdiff - 1,
#     CURRENT_YEAR => POSIX::strftime("%Y", localtime),
#     CURRENT_MONTH => POSIX::strftime("%m", localtime),
# );
# 
# $test_json =~ s/\Q$_\E/$const{$_}/g for keys %const;
# $test_suite = $json->decode($test_json);
# 
# $ctx->{current_timestamp} = '20040816135142';
# 
# my $num = 1;
# foreach my $test_item (@$test_suite) {
#     unless ($test_item->{r}) {
#         pass("perl test skip " . $num++);
#         next;
#     }
#     local $ctx->{__stash}{entry} = $entry if $test_item->{t} =~ m/<MTEntry/;
#     $ctx->{__stash}{entry} = undef if $test_item->{t} =~ m/MTComments|MTPings/;
#     $ctx->{__stash}{entries} = undef if $test_item->{t} =~ m/MTEntries|MTPages/;
#     $ctx->stash('comment', undef);
#     my $result = build($ctx, $test_item->{t});
#     is($result, $test_item->{e}, "perl test " . $num++);
# }
# 

my $num = 1;
while ( defined( my $test = get_test() ) ) {
    # print STDERR Dumper($test);
    unless ($test->{r}) {
        pass("perl test skip " . $num++);
        next;
    }
    # my $result = build($ctx, $test->{t});
    my $result = transform($ctx, $test->{t});
    is($result, $test->{e}, "perl test " . $num++);
}

{
    my $test_suite;
    sub get_test {
        init_test_data() unless $test_suite;
        shift @$test_suite if @$test_suite;
    }

    sub init_test_data {
        my $json = new JSON;
        $json->loose(1); # allows newlines inside strings
        $test_suite = $json->decode(_test_data());
        push(@$test_suite, undef);  # Stopper/reset value
        # print Dumper($test_suite);
        # Ok. We are now ready to test!
        plan tests => (scalar(@$test_suite)) -1;
        $test_suite;
    }

    sub _test_data {
        local $/ = undef;
        local $_ = <TemplateUpgrader::Test::Compare::DATA>;
        # Remove our comments
        s{^ *#.*$}{}mg;
        s{# *\d+ *(?:TBD.*)? *$}{}mg;
        return $_;
    }
}

sub build {
    my($ctx, $markup) = @_;
    my $b = $ctx->stash('builder');
    my $tokens = $b->compile($ctx, $markup);
    print('# -- error compiling: ' . $b->errstr), return undef
        unless defined $tokens;
    my $res = $b->build($ctx, $tokens);
    print '# -- error building: ' . ($b->errstr ? $b->errstr : '') . "\n"
        unless defined $res;
    return $res;
}

my $markup =<<EOF;
<mt:SetVarBlock name="woottang">
    Wheeeee!
</mt:SetVarBlock>
EOF

sub transform {
    my ( $ctx, $markup ) = @_;
    $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    my $handlers ||= MT->registry('tag_upgrade_handlers') || {};
    use TemplateUpgrader;
    my $upgrader = TemplateUpgrader->new({ handlers => $handlers });
# my $b = $ctx->stash('builder');
# my $tokens = $b->compile($ctx, $markup);
# $logger->debug('$tokens: ', l4mtdump($tokens));

    return $upgrader->upgrade( ref $markup ? $markup : \$markup );

#     return $tokens->[6];
# upgrade_template
# my $upgrader = TemplateUpgrader->new({ handlers => $handlers });
# $tmpl        = $upgrader->upgrade( $tmpl );
# 
# my $new = $tmpl->text || '';
# 
# if ( $new eq $orig ) {
#     printf "%s template \"%s\" (ID:%s) not modified.\n",
#         ucfirst($tmpl->type), $tmpl->name, $tmpl->id;
#     return 0;
# }

}

exit;


__DATA__

[
{ "r" : "1", "t" : "", "e" : ""}, #1

{ "r" : "0",    "t" :  "<$mt:SetVar name=\"hello\" value=\"kitty\"$>", 
                "e" : "<mt:var value=\"kitty\" name=\"hello\">"},           #2

{ "r" : "1",    "t" : "<MTGetVar name=\"hello\">",
                "e" : "<mt:var name=\"hello\">"},                           #3

{ "r" : "0",    "t" : "<MTIfOne name=\"hello\">1</MTIfOne>",
                "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"},          #4

{ "r" : "0",    "t" : "<MTUnlessZero name=\"hello\">1</MTUnlessZero>",
                "e" : "<mt:ifnonzero name=\"hello\">1</mt:ifnonzero>"},     #5

{ "r" : "0",    "t" : "<MTUnlessEmpty name=\"hello\">1</MTUnlessEmpty>",
                "e" : "<mt:ifnonempty name=\"hello\">1</mt:ifnonempty>"},   #6

{ "r" : "1",    "t" : "<MTIfEqual a=\"VAL1\" b=\"VAL2\">yay!</MTIfEqual>",
                "e" : "<mt:IfEqual a=\"VAL1\" b=\"VAL2\">yay!</mt:IfEqual>"},       #7

{ "r" : "1",    "t" : "<MTIfEqual a=\"[MTGetVar name='spanky']\" b=\"VAL2\">yay!</MTIfEqual>",
                "e" : "<mt:if name=\"spanky\" eq=\"VAL2\">yay!</mt:if>"},   #8

{ "r" : "1",    "t" : "<MTIfEqual a=\"VAL0\" b=\"[MTGetVar name='pooky']\">yay!</MTIfEqual>",
                "e" : "<mt:if name=\"pooky\" eq=\"VAL0\">yay!</mt:if>"}, #9

{ "r" : "1",    "t" : "<MTIfEqual a=\"[MTCGIPath]\" b=\"[MTGetVar name='ophelia']\">yay!</MTIfEqual>",
                "e" : "<mt:if tag=\"CGIPath\" eq=\"$ophelia\">yay!</mt:if>"}, #10

{ "r" : "1",    "t" : "<MTIfEqual a=\"[MTCGIPath]\" b=\"[MTCGIPath]\">yay!</MTIfEqual>",
                "e" : "<mt:cgipath setvar=\"mtcgipath\"><mt:if tag=\"CGIPath\" eq=\"$mtcgipath\">yay!</mt:if>"} #11


# { "r" : "1", "t" : "<MTIfNotEqual a=\"VAL\" b=\"VAL\">1</MTIfNotEqual>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# { "r" : "1", "t" : "<MTIfGreater a=\"VAL\" b=\"VAL\">1</MTIfGreater>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# { "r" : "1", "t" : "<MTIfGreaterOrEqual a=\"VAL\" b=\"VAL\">1</MTIfGreaterOrEqual>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# { "r" : "1", "t" : "<MTIfLess a=\"VAL\" b=\"VAL\">1</MTIfLess>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# { "r" : "1", "t" : "<MTIfLessOrEqual a=\"VAL\" b=\"VAL\">1</MTIfLessOrEqual>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7

# { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
]
