#!/usr/bin/perl -w
package TemplateUpgrader::Test::Compare;

use strict;
use lib qw( plugins/TemplateUpgrader/t/lib );
use SelfLoader;
use base qw( TemplateUpgrader::Test );
use Test::More skip_all => 'Compare plugin caused problems';

# __PACKAGE__->run_data_tests();

exit;


# __END__
# 
# use strict;
# use lib qw( t/lib   plugins/TemplateUpgrader/lib
#             plugins/TemplateUpgrader/extlib lib extlib );
# 
# use IPC::Open2;
# use SelfLoader;
# use Data::Dumper;
# $| = 1;
# 
# # use MT::Test qw(:db :data);
# use Test::More;
# use JSON -support_by_pp;
# use MT;
# # use MT::Util qw(ts2epoch epoch2ts);
# use MT::Template::Context;
# use MT::Builder;
# 
# use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
# ###l4p our $logger = MT::Log::Log4perl->new();
# 
# require POSIX;
# 
# my $num = 1;
# 
# my $mt  = MT->new();
# my $ctx = MT::Template::Context->new;
# $ctx->stash('builder', MT::Builder->new);
# 
# while ( defined( my $test = get_test() ) ) {
#     # print STDERR Dumper($test);
#     unless ($test->{r}) {
#         pass("perl test skip " . $num++);
#         next;
#     }
#     # my $result = build($ctx, $test->{t});
#     my $result = transform($ctx, $test->{t});
#     is($result, $test->{e}, "perl test " . $num++);
# }
# 
# {
#     my $test_suite;
#     sub get_test {
#         init_test_data() unless $test_suite;
#         shift @$test_suite if @$test_suite;
#     }
# 
#     sub init_test_data {
#         my $json = new JSON;
#         $json->loose(1); # allows newlines inside strings
#         $test_suite = $json->decode(_test_data());
#         push(@$test_suite, undef);  # Stopper/reset value
#         # print Dumper($test_suite);
#         # Ok. We are now ready to test!
#         plan tests => (scalar(@$test_suite)) -1;
#         $test_suite;
#     }
# 
#     sub _test_data {
#         local $/ = undef;
#         local $_ = <TemplateUpgrader::Test::Compare::DATA>;
#         # Remove our comments
#         s{^ *#.*$}{}mg;
#         s{# *\d+ *(?:TBD.*)? *$}{}mg;
#         return $_;
#     }
# }
# 
# # sub build {
# #     my($ctx, $markup) = @_;
# #     my $b = $ctx->stash('builder');
# #     my $tokens = $b->compile($ctx, $markup);
# #     print('# -- error compiling: ' . $b->errstr), return undef
# #         unless defined $tokens;
# #     my $res = $b->build($ctx, $tokens);
# #     print '# -- error building: ' . ($b->errstr ? $b->errstr : '') . "\n"
# #         unless defined $res;
# #     return $res;
# # }
# 
# # my $markup =<<EOF;
# # <mt:SetVarBlock name="woottang">
# #     Wheeeee!
# # </mt:SetVarBlock>
# # EOF
# 
# sub transform {
#     my ( $ctx, $markup ) = @_;
#     ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
#     my $handlers ||= MT->registry('tag_upgrade_handlers') || {};
#     use TemplateUpgrader;
#     my $upgrader = TemplateUpgrader->new({ handlers => $handlers });
#     return $upgrader->upgrade( ref $markup ? $markup : \$markup );
# }
# 
# exit;
# 
# 
# __DATA__
# 
# [
# { "r" : "1", "t" : "", "e" : ""}, #1
# 
# { "r" : "0",    "t" :  "<$mt:SetVar name=\"hello\" value=\"kitty\"$>", 
#                 "e" : "<mt:var value=\"kitty\" name=\"hello\">"},           #2
# 
# { "r" : "1",    "t" : "<MTGetVar name=\"hello\">",
#                 "e" : "<mt:var name=\"hello\">"},                           #3
# 
# { "r" : "0",    "t" : "<MTIfOne name=\"hello\">1</MTIfOne>",
#                 "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"},          #4
# 
# { "r" : "0",    "t" : "<MTUnlessZero name=\"hello\">1</MTUnlessZero>",
#                 "e" : "<mt:ifnonzero name=\"hello\">1</mt:ifnonzero>"},     #5
# 
# { "r" : "0",    "t" : "<MTUnlessEmpty name=\"hello\">1</MTUnlessEmpty>",
#                 "e" : "<mt:ifnonempty name=\"hello\">1</mt:ifnonempty>"},   #6
# 
# { "r" : "1",    "t" : "<MTIfEqual a=\"VAL1\" b=\"VAL2\">yay!</MTIfEqual>",
#                 "e" : "<mt:IfEqual a=\"VAL1\" b=\"VAL2\">yay!</mt:IfEqual>"}, #7
# 
# { "r" : "1",    "t" : "<MTIfEqual a=\"[MTGetVar name='spanky']\" b=\"VAL2\">yay!</MTIfEqual>",
#                 "e" : "<mt:if name=\"spanky\" eq=\"VAL2\">yay!</mt:if>"},   #8
# 
# { "r" : "1",    "t" : "<MTIfEqual a=\"VAL0\" b=\"[MTGetVar name='pooky']\">yay!</MTIfEqual>",
#                 "e" : "<mt:if name=\"pooky\" eq=\"VAL0\">yay!</mt:if>"},    #9
# 
# { "r" : "1",    "t" : "<MTIfEqual a=\"[MTCGIPath]\" b=\"[MTGetVar name='ophelia']\">yay!</MTIfEqual>",
#                 "e" : "<mt:if tag=\"CGIPath\" eq=\"$ophelia\">yay!</mt:if>"}, #10
# 
# { "r" : "1",    "t" : "<MTIfEqual a=\"[MTCGIPath]\" b=\"[MTCGIPath]\">yay!</MTIfEqual>",
#                 "e" : "<mt:cgipath setvar=\"mtcgipath\"><mt:if tag=\"CGIPath\" eq=\"$mtcgipath\">yay!</mt:if>"}, #11
# 
# { "r" : "1",    "t" : "<MTIfNotEqual a=\"VAL1\" b=\"VAL2\">yay!</MTIfNotEqual>",
#                 "e" : "<mt:IfNotEqual a=\"VAL1\" b=\"VAL2\">yay!</mt:IfNotEqual>"}, #12
# 
# { "r" : "1",    "t" : "<MTIfNotEqual a=\"[MTGetVar name='spanky']\" b=\"VAL2\">yay!</MTIfNotEqual>",
#                 "e" : "<mt:if ne=\"VAL2\" name=\"spanky\">yay!</mt:if>"},   #13
# 
# { "r" : "1",    "t" : "<MTIfNotEqual a=\"VAL0\" b=\"[MTGetVar name='pooky']\">yay!</MTIfNotEqual>",
#                 "e" : "<mt:if ne=\"VAL0\" name=\"pooky\">yay!</mt:if>"},    #14
# 
# { "r" : "1",    "t" : "<MTIfNotEqual a=\"[MTCGIPath]\" b=\"[MTGetVar name='ophelia']\">yay!</MTIfNotEqual>",
#                 "e" : "<mt:if ne=\"$ophelia\" tag=\"CGIPath\">yay!</mt:if>"}, #15
# 
# { "r" : "1",    "t" : "<MTIfNotEqual a=\"[MTCGIPath]\" b=\"[MTCGIPath]\">yay!</MTIfNotEqual>",
#                 "e" : "<mt:cgipath setvar=\"mtcgipath\"><mt:if ne=\"$mtcgipath\" tag=\"CGIPath\">yay!</mt:if>"}, #16
# 
# { "r" : "1",    "t" : "<MTIfLess a=\"VAL1\" b=\"VAL2\">yay!</MTIfLess>",
#                 "e" : "<mt:IfLess a=\"VAL1\" b=\"VAL2\">yay!</mt:IfLess>"}, #17
# 
# { "r" : "1",    "t" : "<MTIfLess a=\"[MTGetVar name='spanky']\" b=\"VAL2\">yay!</MTIfLess>",
#                 "e" : "<mt:if lt=\"VAL2\" name=\"spanky\">yay!</mt:if>"},   #18
# 
# { "r" : "1",    "t" : "<MTIfLess a=\"VAL0\" b=\"[MTGetVar name='pooky']\">yay!</MTIfLess>",
#                 "e" : "<mt:if lt=\"VAL0\" name=\"pooky\">yay!</mt:if>"},    #19
# 
# { "r" : "1",    "t" : "<MTIfLess a=\"[MTCGIPath]\" b=\"[MTGetVar name='ophelia']\">yay!</MTIfLess>",
#                 "e" : "<mt:if lt=\"$ophelia\" tag=\"CGIPath\">yay!</mt:if>"}, #20
# 
# { "r" : "1",    "t" : "<MTIfLess a=\"[MTCGIPath]\" b=\"[MTCGIPath]\">yay!</MTIfLess>",
#                 "e" : "<mt:cgipath setvar=\"mtcgipath\"><mt:if lt=\"$mtcgipath\" tag=\"CGIPath\">yay!</mt:if>"}, #21
# 
# { "r" : "1",    "t" : "<MTIfGreater a=\"VAL1\" b=\"VAL2\">yay!</MTIfGreater>",
#                 "e" : "<mt:IfGreater a=\"VAL1\" b=\"VAL2\">yay!</mt:IfGreater>"}, #22
# 
# { "r" : "1",    "t" : "<MTIfGreater a=\"[MTGetVar name='spanky']\" b=\"VAL2\">yay!</MTIfGreater>",
#                 "e" : "<mt:if gt=\"VAL2\" name=\"spanky\">yay!</mt:if>"},   #23
# 
# { "r" : "1",    "t" : "<MTIfGreater a=\"VAL0\" b=\"[MTGetVar name='pooky']\">yay!</MTIfGreater>",
#                 "e" : "<mt:if gt=\"VAL0\" name=\"pooky\">yay!</mt:if>"},    #24
# 
# { "r" : "1",    "t" : "<MTIfGreater a=\"[MTCGIPath]\" b=\"[MTGetVar name='ophelia']\">yay!</MTIfGreater>",
#                 "e" : "<mt:if gt=\"$ophelia\" tag=\"CGIPath\">yay!</mt:if>"}, #25
# 
# { "r" : "1",    "t" : "<MTIfGreater a=\"[MTCGIPath]\" b=\"[MTCGIPath]\">yay!</MTIfGreater>",
#                 "e" : "<mt:cgipath setvar=\"mtcgipath\"><mt:if gt=\"$mtcgipath\" tag=\"CGIPath\">yay!</mt:if>"}, #26
# 
# { "r" : "1",    "t" : "<MTIfGreaterOrEqual a=\"VAL1\" b=\"VAL2\">yay!</MTIfGreaterOrEqual>",
#                 "e" : "<mt:IfGreaterOrEqual a=\"VAL1\" b=\"VAL2\">yay!</mt:IfGreaterOrEqual>"}, #27
# 
# { "r" : "1",    "t" : "<MTIfGreaterOrEqual a=\"[MTGetVar name='spanky']\" b=\"VAL2\">yay!</MTIfGreaterOrEqual>",
#                 "e" : "<mt:if name=\"spanky\" ge=\"VAL2\">yay!</mt:if>"},   #28
# 
# { "r" : "1",    "t" : "<MTIfGreaterOrEqual a=\"VAL0\" b=\"[MTGetVar name='pooky']\">yay!</MTIfGreaterOrEqual>",
#                 "e" : "<mt:if name=\"pooky\" ge=\"VAL0\">yay!</mt:if>"},    #29
# 
# { "r" : "1",    "t" : "<MTIfGreaterOrEqual a=\"[MTCGIPath]\" b=\"[MTGetVar name='ophelia']\">yay!</MTIfGreaterOrEqual>",
#                 "e" : "<mt:if tag=\"CGIPath\" ge=\"$ophelia\">yay!</mt:if>"}, #30
# 
# { "r" : "1",    "t" : "<MTIfGreaterOrEqual a=\"[MTCGIPath]\" b=\"[MTCGIPath]\">yay!</MTIfGreaterOrEqual>",
#                 "e" : "<mt:cgipath setvar=\"mtcgipath\"><mt:if tag=\"CGIPath\" ge=\"$mtcgipath\">yay!</mt:if>"}, #31
# 
# { "r" : "1",    "t" : "<MTIfLessOrEqual a=\"VAL1\" b=\"VAL2\">yay!</MTIfLessOrEqual>",
#                 "e" : "<mt:IfLessOrEqual a=\"VAL1\" b=\"VAL2\">yay!</mt:IfLessOrEqual>"}, #32
# 
# { "r" : "1",    "t" : "<MTIfLessOrEqual a=\"[MTGetVar name='spanky']\" b=\"VAL2\">yay!</MTIfLessOrEqual>",
#                 "e" : "<mt:if name=\"spanky\" le=\"VAL2\">yay!</mt:if>"},   #33
# 
# { "r" : "1",    "t" : "<MTIfLessOrEqual a=\"VAL0\" b=\"[MTGetVar name='pooky']\">yay!</MTIfLessOrEqual>",
#                 "e" : "<mt:if name=\"pooky\" le=\"VAL0\">yay!</mt:if>"},    #34
# 
# { "r" : "1",    "t" : "<MTIfLessOrEqual a=\"[MTCGIPath]\" b=\"[MTGetVar name='ophelia']\">yay!</MTIfLessOrEqual>",
#                 "e" : "<mt:if tag=\"CGIPath\" le=\"$ophelia\">yay!</mt:if>"}, #35
# 
# { "r" : "1",    "t" : "<MTIfLessOrEqual a=\"[MTCGIPath]\" b=\"[MTCGIPath]\">yay!</MTIfLessOrEqual>",
#                 "e" : "<mt:cgipath setvar=\"mtcgipath\"><mt:if le=\"$mtcgipath\" tag=\"CGIPath\">yay!</mt:if>"} #36
# 
# 
# # { "r" : "1", "t" : "<MTIfNotEqual a=\"VAL\" b=\"VAL\">1</MTIfNotEqual>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# # { "r" : "1", "t" : "<MTIfGreater a=\"VAL\" b=\"VAL\">1</MTIfGreater>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# # { "r" : "1", "t" : "<MTIfGreaterOrEqual a=\"VAL\" b=\"VAL\">1</MTIfGreaterOrEqual>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# # { "r" : "1", "t" : "<MTIfLess a=\"VAL\" b=\"VAL\">1</MTIfLess>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# # { "r" : "1", "t" : "<MTIfLessOrEqual a=\"VAL\" b=\"VAL\">1</MTIfLessOrEqual>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# 
# # { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# # { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# # { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# # { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# # { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# # { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# # { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# # { "r" : "0", "t" : "<MTFoo ATTR=\"VAL\">1</MTFoo>", "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"}, #7
# ]

__DATA__

[
{ "r" : "1", "t" : "", "e" : ""}, #1

{ "r" : "1",    "t" : "<MTIfEqual a=\"VAL1\" b=\"VAL2\">yay!</MTIfEqual>",
                "e" : "<mt:var name=\"compare_val\" value=\"VAL1\"><mt:if name=\"compare_val\" eq=\"VAL2\">yay!</mt:if>"}, #2

{ "r" : "1",    "t" : "<MTIfEqual a=\"[MTGetVar name='spanky']\" b=\"VAL2\">yay!</MTIfEqual>",
                "e" : "<mt:if name=\"spanky\" eq=\"VAL2\">yay!</mt:if>"},   #3

{ "r" : "1",    "t" : "<MTIfEqual a=\"VAL0\" b=\"[MTGetVar name='pooky']\">yay!</MTIfEqual>",
                "e" : "<mt:if name=\"pooky\" eq=\"VAL0\">yay!</mt:if>"},    #4

{ "r" : "1",    "t" : "<MTIfEqual a=\"[MTCGIPath]\" b=\"[MTGetVar name='ophelia']\">yay!</MTIfEqual>",
                "e" : "<mt:if tag=\"CGIPath\" eq=\"$ophelia\">yay!</mt:if>"}, #5

{ "r" : "1",    "t" : "<MTIfEqual a=\"[MTCGIPath]\" b=\"[MTCGIPath]\">yay!</MTIfEqual>",
                "e" : "<mt:cgipath setvar=\"tag_mtcgipath\"><mt:if tag=\"CGIPath\" eq=\"$tag_mtcgipath\">yay!</mt:if>"}, #6

{ "r" : "1",    "t" : "<MTIfNotEqual a=\"VAL1\" b=\"VAL2\">yay!</MTIfNotEqual>",
                "e" : "<mt:var name=\"compare_val\" value=\"VAL1\"><mt:if name=\"compare_val\" ne=\"VAL2\">yay!</mt:if>"}, #7

{ "r" : "1",    "t" : "<MTIfNotEqual a=\"[MTGetVar name='spanky']\" b=\"VAL2\">yay!</MTIfNotEqual>",
                "e" : "<mt:if name=\"spanky\" ne=\"VAL2\">yay!</mt:if>"},   #8

{ "r" : "1",    "t" : "<MTIfNotEqual a=\"VAL0\" b=\"[MTGetVar name='pooky']\">yay!</MTIfNotEqual>",
                "e" : "<mt:if name=\"pooky\" ne=\"VAL0\">yay!</mt:if>"},    #9

{ "r" : "1",    "t" : "<MTIfNotEqual a=\"[MTCGIPath]\" b=\"[MTGetVar name='ophelia']\">yay!</MTIfNotEqual>",
                "e" : "<mt:if tag=\"CGIPath\" ne=\"$ophelia\">yay!</mt:if>"}, #10

{ "r" : "1",    "t" : "<MTIfNotEqual a=\"[MTCGIPath]\" b=\"[MTCGIPath]\">yay!</MTIfNotEqual>",
                "e" : "<mt:cgipath setvar=\"tag_mtcgipath\"><mt:if tag=\"CGIPath\" ne=\"$tag_mtcgipath\">yay!</mt:if>"}, #11

{ "r" : "1",    "t" : "<MTIfLess a=\"VAL1\" b=\"VAL2\">yay!</MTIfLess>",
                "e" : "<mt:var name=\"compare_val\" value=\"VAL1\"><mt:if name=\"compare_val\" lt=\"VAL2\">yay!</mt:if>"}, #12

{ "r" : "1",    "t" : "<MTIfLess a=\"[MTGetVar name='spanky']\" b=\"VAL2\">yay!</MTIfLess>",
                "e" : "<mt:if name=\"spanky\" lt=\"VAL2\">yay!</mt:if>"},   #13

{ "r" : "1",    "t" : "<MTIfLess a=\"VAL0\" b=\"[MTGetVar name='pooky']\">yay!</MTIfLess>",
                "e" : "<mt:if name=\"pooky\" lt=\"VAL0\">yay!</mt:if>"},    #14

{ "r" : "1",    "t" : "<MTIfLess a=\"[MTCGIPath]\" b=\"[MTGetVar name='ophelia']\">yay!</MTIfLess>",
                "e" : "<mt:if tag=\"CGIPath\" lt=\"$ophelia\">yay!</mt:if>"}, #15

{ "r" : "1",    "t" : "<MTIfLess a=\"[MTCGIPath]\" b=\"[MTCGIPath]\">yay!</MTIfLess>",
                "e" : "<mt:cgipath setvar=\"tag_mtcgipath\"><mt:if tag=\"CGIPath\" lt=\"$tag_mtcgipath\">yay!</mt:if>"}, #16

{ "r" : "1",    "t" : "<MTIfGreater a=\"VAL1\" b=\"VAL2\">yay!</MTIfGreater>",
                "e" : "<mt:var name=\"compare_val\" value=\"VAL1\"><mt:if name=\"compare_val\" gt=\"VAL2\">yay!</mt:if>"}, #17

{ "r" : "1",    "t" : "<MTIfGreater a=\"[MTGetVar name='spanky']\" b=\"VAL2\">yay!</MTIfGreater>",
                "e" : "<mt:if name=\"spanky\" gt=\"VAL2\">yay!</mt:if>"},   #18

{ "r" : "1",    "t" : "<MTIfGreater a=\"VAL0\" b=\"[MTGetVar name='pooky']\">yay!</MTIfGreater>",
                "e" : "<mt:if name=\"pooky\" gt=\"VAL0\">yay!</mt:if>"},    #19

{ "r" : "1",    "t" : "<MTIfGreater a=\"[MTCGIPath]\" b=\"[MTGetVar name='ophelia']\">yay!</MTIfGreater>",
                "e" : "<mt:if tag=\"CGIPath\" gt=\"$ophelia\">yay!</mt:if>"}, #20

{ "r" : "1",    "t" : "<MTIfGreater a=\"[MTCGIPath]\" b=\"[MTCGIPath]\">yay!</MTIfGreater>",
                "e" : "<mt:cgipath setvar=\"tag_mtcgipath\"><mt:if tag=\"CGIPath\" gt=\"$tag_mtcgipath\">yay!</mt:if>"}, #21

{ "r" : "1",    "t" : "<MTIfGreaterOrEqual a=\"VAL1\" b=\"VAL2\">yay!</MTIfGreaterOrEqual>",
                "e" : "<mt:var name=\"compare_val\" value=\"VAL1\"><mt:if name=\"compare_val\" ge=\"VAL2\">yay!</mt:if>"}, #22

{ "r" : "1",    "t" : "<MTIfGreaterOrEqual a=\"[MTGetVar name='spanky']\" b=\"VAL2\">yay!</MTIfGreaterOrEqual>",
                "e" : "<mt:if name=\"spanky\" ge=\"VAL2\">yay!</mt:if>"},   #23

{ "r" : "1",    "t" : "<MTIfGreaterOrEqual a=\"VAL0\" b=\"[MTGetVar name='pooky']\">yay!</MTIfGreaterOrEqual>",
                "e" : "<mt:if name=\"pooky\" ge=\"VAL0\">yay!</mt:if>"},    #24

{ "r" : "1",    "t" : "<MTIfGreaterOrEqual a=\"[MTCGIPath]\" b=\"[MTGetVar name='ophelia']\">yay!</MTIfGreaterOrEqual>",
                "e" : "<mt:if tag=\"CGIPath\" ge=\"$ophelia\">yay!</mt:if>"}, #25

{ "r" : "1",    "t" : "<MTIfGreaterOrEqual a=\"[MTCGIPath]\" b=\"[MTCGIPath]\">yay!</MTIfGreaterOrEqual>",
                "e" : "<mt:cgipath setvar=\"tag_mtcgipath\"><mt:if tag=\"CGIPath\" ge=\"$tag_mtcgipath\">yay!</mt:if>"}, #26

{ "r" : "1",    "t" : "<MTIfLessOrEqual a=\"VAL1\" b=\"VAL2\">yay!</MTIfLessOrEqual>",
                "e" : "<mt:var name=\"compare_val\" value=\"VAL1\"><mt:if name=\"compare_val\" le=\"VAL2\">yay!</mt:if>"}, #27

{ "r" : "1",    "t" : "<MTIfLessOrEqual a=\"[MTGetVar name='spanky']\" b=\"VAL2\">yay!</MTIfLessOrEqual>",
                "e" : "<mt:if name=\"spanky\" le=\"VAL2\">yay!</mt:if>"},   #28

{ "r" : "1",    "t" : "<MTIfLessOrEqual a=\"VAL0\" b=\"[MTGetVar name='pooky']\">yay!</MTIfLessOrEqual>",
                "e" : "<mt:if name=\"pooky\" le=\"VAL0\">yay!</mt:if>"},    #29

{ "r" : "1",    "t" : "<MTIfLessOrEqual a=\"[MTCGIPath]\" b=\"[MTGetVar name='ophelia']\">yay!</MTIfLessOrEqual>",
                "e" : "<mt:if tag=\"CGIPath\" le=\"$ophelia\">yay!</mt:if>"}, #30

{ "r" : "1",    "t" : "<MTIfLessOrEqual a=\"[MTCGIPath]\" b=\"[MTCGIPath]\">yay!</MTIfLessOrEqual>",
                "e" : "<mt:cgipath setvar=\"tag_mtcgipath\"><mt:if tag=\"CGIPath\" le=\"$tag_mtcgipath\">yay!</mt:if>"}, #31

{ "r" : "1",    "t" : "<MTIfEqual a=\"[MTGetVar name='spanky' cat=' hiya']\" b=\"VAL2\">yay!</MTIfEqual>",
                "e" : "<mt:var name=\"spanky\" cat=\" hiya\" setvar=\"compare_val\"><mt:if name=\"compare_val\" eq=\"VAL2\">yay!</mt:if>"}   #32


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
