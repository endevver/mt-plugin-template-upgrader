#!/usr/bin/perl -w
package TemplateUpgrader::Test::Template;
use strict; use warnings; use Carp; use Data::Dumper;

$Data::Dumper::Indent = 1;
$Data::Dumper::Maxdepth = 4;

BEGIN {
    $ENV{MT_CONFIG} = $ENV{MT_HOME}.'/mt-config.cgi';
    use lib qw( plugins/TemplateUpgrader/t/lib );
    use TemplateUpgrader::Test;
    use base qw( TemplateUpgrader::Test );
    use TemplateUpgrader;
}

use Test::More tests => 23;
use Test::Deep qw( eq_deeply );
use Test::Warn;
use MT::Test;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

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

### UPGRADER INITIALIZATION
my $upgrader = TemplateUpgrader->new();
is(ref $upgrader, 'TemplateUpgrader', 'Upgrader class initialized');        #1

### NEW TEMPLATE CREATION
my $tmpl = $upgrader->new_template();
isa_ok( $tmpl, 'TemplateUpgrader::Template' );                              #2

### ROUNDTRIPPING WITH $tmpl->text()
my $t = '<mt:Entries category="Me AND You" tag="Furry" lastn="10" setvar="Jerry">My Hours are insane </mt:Entries>';
$tmpl->text($t);
is( $tmpl->text(), $t, 'Roundtrip with $tmpl->text');                       #3

### INITIAL ATTRIBUTE ORDERING
my @testnode = (
    [ 'category', 'Me AND You' ],
    [ 'tag',       'Furry'     ],
    [ 'lastn',     '10'        ],
    [ 'setvar',    'Jerry'     ]
);
my $tokens = $tmpl->tokens;
my $node = $tokens->[0];
ok( eq_deeply( $node->[4], \@testnode ) );                                  #4
is( my $a = $node->getAttribute('setvar'),   'Jerry',      'getAttribute' ); #5
is(    $a = $node->getAttribute('lastn'),    '10',         'getAttribute' ); #6
is(    $a = $node->getAttribute('tag'),      'Furry',      'getAttribute' ); #7
is(    $a = $node->getAttribute('category'), 'Me AND You', 'getAttribute' ); #8

@testnode = (
    [ 'Scooby',   'Snack'      ],
    [ 'category', 'Me AND You' ],
    [ 'tag',       'Furry'     ],
    [ 'lastn',     '10'        ],
    [ 'setvar',    'Jerry'     ]
);
$node->prependAttribute('Scooby', 'Snack');
ok( eq_deeply( $node->[4], \@testnode ) );                                  #9
is( $a = $node->getAttribute('Scooby'),   'Snack',   'getAttribute' );     #10

@testnode = (
    [ 'Scooby',   'Snack'      ],
    [ 'category', 'Me AND You' ],
    [ 'tag',       'Furry'     ],
    [ 'lastn',     '10'        ],
    [ 'setvar',    'Jerry'     ],
    [ 'Zoey',      'Leigh'     ],
);
$node->appendAttribute('Zoey', 'Leigh');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #11
is( $a = $node->getAttribute('Zoey'),   'Leigh',   'getAttribute' );       #12

@testnode = (
    [ 'Scooby',   'Snack'      ],
    [ 'category', 'Me AND You' ],
    [ 'tag',       'Furry'     ],
    [ 'lastn',     '10'        ],
    [ 'setvar',    'Jerry'     ],
    [ 'Zoey',      'Leigh'     ],
    [ 'Ophelia',   'Stella'     ],
);
$node->setAttribute('Ophelia', 'Stella');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #13
is( $a = $node->getAttribute('Ophelia'),   'Stella',   'getAttribute' );   #14

@testnode = (
    [ 'Ophelia',   'Chester'    ],
    [ 'Scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'setvar',    'Jerry'      ],
    [ 'Zoey',      'Leigh'      ],
    [ 'Ophelia',   'Stella'     ],
);
$node->prependAttribute('Ophelia', 'Chester');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #15
is( @{ $a = $node->getAttribute('Ophelia') }, 
    @{['Chester', 'Stella']}, 'getAttribute' );                            #16

@testnode = (
    [ 'Ophelia',   'Chester'    ],
    [ 'Scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'setvar',    'Jerry'      ],
    [ 'Frannie',   'Leigh'      ],
    [ 'Ophelia',   'Stella'     ],
);
$node->renameAttribute('Zoey', 'Frannie');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #17

@testnode = (
    [ 'Chi-chi',   'Chester'    ],
    [ 'Scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'setvar',    'Jerry'      ],
    [ 'Frannie',   'Leigh'      ],
    [ 'Ophelia',   'Stella'     ],
);
$node->renameAttribute('Ophelia', 'Chi-chi');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #18

@testnode = (
    [ 'Chi-chi',   'Chester'    ],
    [ 'Scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'setvar',    'Jerry'      ],
    [ 'Frannie',   'Leigh'      ],
    [ 'Ophelia',   'Stella'     ],
);
$node->renameAttribute('setvar', 'Frannie');
warning_like { $node->renameAttribute('setvar', 'Frannie') }
['failed due to existing target attribute'], 'Good warnings';

ok( eq_deeply( $node->[4], \@testnode ) );                                 #19

@testnode = (
    [ 'Chi-chi',   'Chester'    ],
    [ 'Scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'Frannie',    'Jerry'      ],
    [ 'Frannie',   'Leigh'      ],
    [ 'Ophelia',   'Stella'     ],
);
$node->renameAttribute('setvar', 'Frannie', 'force');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #20

@testnode = (
    [ 'Chi-chi',   'Chester'    ],
    [ 'Scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'Frannie',    'Jerry'      ],
    [ 'Frannie',   'Leigh'      ],
);
$node->removeAttribute('Ophelia');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #21

@testnode = (
    [ 'Chi-chi',   'Chester'    ],
    [ 'category',  'Me AND You' ],
    [ 'lastn',     '10'         ],
    [ 'Frannie',    'Jerry'      ],
    [ 'Frannie',   'Leigh'      ],
);
$node->removeAttribute('Scooby', 'tag');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #22

@testnode = (
    [ 'Chi-chi',   'Chester'    ],
    [ 'category',  'Me AND You' ],
    [ 'lastn',     '10'         ],
);
$node->removeAttribute('Frannie');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #23

# diag( Dumper( $node->[4] ));

# save_backup
# reflow
# innerHTML
# getElementById
# createElement
# createTextNode
# removeAttribute

# dump_node
# nodeType
# tagName
# appendAttribute
# prependAttribute
# getAttribute
# setAttribute
# 
# print STDERR Dumper($tmpl);
exit;

__END__

# my $app = MT->instance;
# isa_ok($app, 'MT::App', 'MT is intialized');                                #5
# 
# 
# is( MT->model('templateupgrader_template'),
#     'TemplateUpgrader::Template',
#     'TemplateUpgrader::Template model');                                    #6
# 
# is( MT->model('templateupgrader_handlers'),
#     'TemplateUpgrader::Handlers',
#     'TemplateUpgrader::Handlers model');                                    #7
# 
# is( MT->model('templateupgrader_builder'),
#     'TemplateUpgrader::Builder',
#     'TemplateUpgrader::Builder model');                                     #8
# 
# 
# 
# 
# 
# use strict;
# # use lib qw( plugins/TemplateUpgrader/t/lib );
# # use base qw( TemplateUpgrader::Test );
# # 
# # my $app = __PACKAGE__->init();
# 
# exit;
# 
# # numify            dirify              zero_pad            nl2br
# # mteval            sanitize            sprintf             replace
# # filters           encode_sha1         regex_replace       spacify
# # trim_to           encode_html         capitalize          string_format
# # trim              encode_xml          count_characters    strip
# # ltrim             encode_js           cat                 strip_tags
# # rtrim             encode_php          count_paragraphs    _default
# # decode_html       encode_url          count_words         nofollowfy
# # decode_xml        upper_case          escape              wrap_text
# # remove_html       lower_case          indent              setvar
# # space_pad         strip_linefeeds
# 
# 
# $Data::Dumper::Sortkeys = \&my_filter;
# sub my_filter {
#     my ($hash) = @_;
#     # return an array ref containing the hash keys to dump
#     # in the order that you want them to be dumped
#     return [
#       # Sort the keys of %$foo in reverse numeric order
#         $hash eq $foo ? (sort {$b <=> $a} keys %$hash) :
#       # Only dump the odd number keys of %$bar
#         $hash eq $bar ? (grep {$_ % 2} keys %$hash) :
#       # Sort keys in default order for all other hashes
#         (sort keys %$hash)
#     ];
# }
# 
# # $Data::Dumper::Terse = 1;          # don't output names where feasible
# # $Data::Dumper::Indent = 0;         # turn off all pretty print
# # print Dumper($boo), "\n";
# # 
# $Data::Dumper::Indent = 1;         # mild pretty print
# # print Dumper($boo);
# # 
# # $Data::Dumper::Indent = 3;         # pretty print with array indices
# # print Dumper($boo);
# # 
# # $Data::Dumper::Useqq = 1;          # print strings in double quotes
# # print Dumper($boo);
# # 
# # $Data::Dumper::Pair = " : ";       # specify hash key/value separator
# # print Dumper($boo);
# 
# $Data::Dumper::Maxdepth = 3;
