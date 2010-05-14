#!/usr/bin/perl -w
package TemplateUpgrader::Test::Template;
use strict; use warnings; use Carp; use Data::Dumper;

$Data::Dumper::Indent = 1;
$Data::Dumper::Maxdepth = 3;

BEGIN {
    $ENV{MT_CONFIG} = $ENV{MT_HOME}.'/mt-config.cgi';
    use Test::More tests => 2;
    use lib qw( plugins/TemplateUpgrader/t/lib );
    use TemplateUpgrader::Test;
    use base qw( TemplateUpgrader::Test );
    use TemplateUpgrader;
    use MT::Test;
}

=pod
Test::Object
Test::Lazy
Test::Lazy::Template
Test::Lazy::Tester
Test::Builder::Tester::Color
Test::Builder
p5-test-exception
Test::Tutorial.pod

=cut

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

my $upgrader = TemplateUpgrader->new();
is(ref $upgrader, 'TemplateUpgrader', 'Upgrader class initialized');        #1

my $tmpl = $upgrader->new_template();
    isa_ok( $tmpl, 'TemplateUpgrader::Template' );                          #2

$tmpl->text('<mt:Entries category="Me AND You" tag="Furry" lastn="10" setvar="Jerry">My Hours are insane </mt:Entries>');
$logger->debug('$tmpl: ', l4mtdump($tmpl));
$logger->debug('tmpl->text: '. (my $txt = $tmpl->text));

$tmpl->{reflow_flag} = 1;
$logger->debug('tmpl->text: '.$tmpl->text);
$logger->debug('$tmpl: ', l4mtdump($tmpl));

# save_backup
# reflow
# innerHTML
# getElementById
# createElement
# createTextNode
# dump_node
# nodeType
# tagName
# getAttribute
# setAttribute
# removeAttribute
# appendAttribute
# prependAttribute
# renameAttribute
# 
# print STDERR Dumper($tmpl);
exit;

__END__

my $app = MT->instance;
isa_ok($app, 'MT::App', 'MT is intialized');                                #5


is( MT->model('templateupgrader_template'),
    'TemplateUpgrader::Template',
    'TemplateUpgrader::Template model');                                    #6

is( MT->model('templateupgrader_handlers'),
    'TemplateUpgrader::Handlers',
    'TemplateUpgrader::Handlers model');                                    #7

is( MT->model('templateupgrader_builder'),
    'TemplateUpgrader::Builder',
    'TemplateUpgrader::Builder model');                                     #8





use strict;
# use lib qw( plugins/TemplateUpgrader/t/lib );
# use base qw( TemplateUpgrader::Test );
# 
# my $app = __PACKAGE__->init();

exit;

# numify            dirify              zero_pad            nl2br
# mteval            sanitize            sprintf             replace
# filters           encode_sha1         regex_replace       spacify
# trim_to           encode_html         capitalize          string_format
# trim              encode_xml          count_characters    strip
# ltrim             encode_js           cat                 strip_tags
# rtrim             encode_php          count_paragraphs    _default
# decode_html       encode_url          count_words         nofollowfy
# decode_xml        upper_case          escape              wrap_text
# remove_html       lower_case          indent              setvar
# space_pad         strip_linefeeds


$Data::Dumper::Sortkeys = \&my_filter;
sub my_filter {
    my ($hash) = @_;
    # return an array ref containing the hash keys to dump
    # in the order that you want them to be dumped
    return [
      # Sort the keys of %$foo in reverse numeric order
        $hash eq $foo ? (sort {$b <=> $a} keys %$hash) :
      # Only dump the odd number keys of %$bar
        $hash eq $bar ? (grep {$_ % 2} keys %$hash) :
      # Sort keys in default order for all other hashes
        (sort keys %$hash)
    ];
}

# $Data::Dumper::Terse = 1;          # don't output names where feasible
# $Data::Dumper::Indent = 0;         # turn off all pretty print
# print Dumper($boo), "\n";
# 
$Data::Dumper::Indent = 1;         # mild pretty print
# print Dumper($boo);
# 
# $Data::Dumper::Indent = 3;         # pretty print with array indices
# print Dumper($boo);
# 
# $Data::Dumper::Useqq = 1;          # print strings in double quotes
# print Dumper($boo);
# 
# $Data::Dumper::Pair = " : ";       # specify hash key/value separator
# print Dumper($boo);

$Data::Dumper::Maxdepth = 3;
