#!/usr/bin/perl -w
package TemplateUpgrader::Test::Template;
use strict; use warnings; use Carp; use Data::Dumper;

$Data::Dumper::Indent = 1;
$Data::Dumper::Maxdepth = 4;

BEGIN {
    $ENV{MT_CONFIG} = $ENV{MT_HOME}.'/mt-config.cgi';
    use lib qw( plugins/TemplateUpgrader/lib plugins/TemplateUpgrader/t/lib );
    use TemplateUpgrader::Bootstrap;

}
use TemplateUpgrader::Test;
use base qw( TemplateUpgrader::Test );
use TemplateUpgrader;

use Test::More tests => 24;
use Test::Deep qw( eq_deeply );
use Test::Warn;
# use MT::Test;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();


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
    [ 'scooby',   'Snack'      ],
    [ 'category', 'Me AND You' ],
    [ 'tag',       'Furry'     ],
    [ 'lastn',     '10'        ],
    [ 'setvar',    'Jerry'     ]
);
$node->prependAttribute('scooby', 'Snack');
ok( eq_deeply( $node->[4], \@testnode ) );                                  #9
is( $a = $node->getAttribute('scooby'),   'Snack',   'getAttribute' );     #10

@testnode = (
    [ 'scooby',   'Snack'      ],
    [ 'category', 'Me AND You' ],
    [ 'tag',       'Furry'     ],
    [ 'lastn',     '10'        ],
    [ 'setvar',    'Jerry'     ],
    [ 'zoey',      'Leigh'     ],
);
$node->appendAttribute('zoey', 'Leigh');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #11
is( $a = $node->getAttribute('zoey'),   'Leigh',   'getAttribute' );       #12

@testnode = (
    [ 'scooby',   'Snack'      ],
    [ 'category', 'Me AND You' ],
    [ 'tag',       'Furry'     ],
    [ 'lastn',     '10'        ],
    [ 'setvar',    'Jerry'     ],
    [ 'zoey',      'Leigh'     ],
    [ 'ophelia',   'Stella'     ],
);
$node->setAttribute('ophelia', 'Stella');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #13
is( $a = $node->getAttribute('ophelia'),   'Stella',   'getAttribute' );   #14

@testnode = (
    [ 'ophelia',   'Chester'    ],
    [ 'scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'setvar',    'Jerry'      ],
    [ 'zoey',      'Leigh'      ],
    [ 'ophelia',   'Stella'     ],
);
$node->prependAttribute('ophelia', 'Chester');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #15
is( @{ $a = $node->getAttribute('ophelia') }, 
    @{['Chester', 'Stella']}, 'getAttribute' );                            #16

@testnode = (
    [ 'ophelia',   'Chester'    ],
    [ 'scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'setvar',    'Jerry'      ],
    [ 'frannie',   'Leigh'      ],
    [ 'ophelia',   'Stella'     ],
);
$node->renameAttribute('zoey', 'frannie');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #17

@testnode = (
    [ 'chichi',   'Chester'    ],
    [ 'scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'setvar',    'Jerry'      ],
    [ 'frannie',   'Leigh'      ],
    [ 'ophelia',   'Stella'     ],
);
$node->renameAttribute('ophelia', 'chichi');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #18

@testnode = (
    [ 'chichi',   'Chester'    ],
    [ 'scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'setvar',    'Jerry'      ],
    [ 'frannie',   'Leigh'      ],
    [ 'ophelia',   'Stella'     ],
);
$node->renameAttribute('setvar', 'frannie');
# warning_like { $node->renameAttribute('setvar', 'frannie') }
# ['Renaming of existing attribute failed'], 'Good warnings';

ok( eq_deeply( $node->[4], \@testnode ) );                                 #19

@testnode = (
    [ 'chichi',   'Chester'    ],
    [ 'scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'frannie',    'Jerry'      ],
    [ 'frannie',   'Leigh'      ],
    [ 'ophelia',   'Stella'     ],
);
$node->renameAttribute('setvar', 'frannie', 'force');
ok( eq_deeply( $node->[4], \@testnode ), 'Forced dupe key rename' );     #20

@testnode = (
    [ 'chichi',   'Chester'    ],
    [ 'scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'frannie',    'Jerry'      ],
    [ 'frannie',   'Leigh'      ],
);
$node->removeAttribute('ophelia');
ok( eq_deeply( $node->[4], \@testnode ), 'Attribute removal' );         #21

@testnode = (
    [ 'chichi',   'Chester'    ],
    [ 'category',  'Me AND You' ],
    [ 'lastn',     '10'         ],
    [ 'frannie',    'Jerry'      ],
    [ 'frannie',   'Leigh'      ],
);
$node->removeAttribute('scooby', 'tag');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #22

@testnode = (
    [ 'chichi',   'Chester'    ],
    [ 'category',  'Me AND You' ],
    [ 'lastn',     '10'         ],
);
$node->removeAttribute('frannie');
ok( eq_deeply( $node->[4], \@testnode ) );                                 #23

my $new_t = '<mt:Entries chichi="Chester" category="Me AND You" lastn="10">My Hours are insane </mt:Entries>';
$tmpl->{reflow_flag} = 1;
is( $tmpl->text, $new_t, 'Template text upgraded' );                           #24


#### UNTESTED #####
# save_backup
# reflow
# innerHTML
# getElementById
# createElement
# createTextNode
# dump_node
# nodeType
# tagName

