#!/usr/bin/perl -w
package TemplateUpgrader::Test::TagAttributes;
use strict; use warnings; use Carp; use Data::Dumper;

use Test::More tests => 28;

my $app;
BEGIN {
    use lib qw( plugins/TemplateUpgrader/lib );
    use TemplateUpgrader::Bootstrap qw( :app );
    $app = TemplateUpgrader::Bootstrap->app();
}
use Test::Deep qw( eq_deeply );
use Test::Warn;
$Data::Dumper::Indent = 1;
$Data::Dumper::Maxdepth = 4;

use base qw( TemplateUpgrader::Test );
use TemplateUpgrader;
use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new(); $logger->trace();

### SETUP
my $upgrader = TemplateUpgrader->new();
my $tmpl     = $upgrader->new_template();

### ROUNDTRIPPING WITH $tmpl->text()
my $orig_text = '<mt:Entries category="Me AND You" tag="Furry" lastn="10" setvar="Jerry">My Hours are insane </mt:Entries>';
$tmpl->text($orig_text);
is( $tmpl->text(), $orig_text, 'Roundtrip $tmpl->text');                            #1

# PULL THE NODES
my $tokens   = $tmpl->tokens;
my $node     = $tokens->[0] || [];

### BASIC ATTRIBUTE RETRIEVAL
my $testnode = [
    [ 'category', 'Me AND You' ],
    [ 'tag',       'Furry'     ],
    [ 'lastn',     '10'        ],
    [ 'setvar',    'Jerry'     ]
];
is_deeply( [ $node->attributes ], $testnode, 'Initial node test');          #2
is( my $a = $node->getAttribute('setvar'), 'Jerry',     'getAttribute' );   #3
is( $a = $node->getAttribute('lastn'),    '10',         'getAttribute' );   #4
is( $a = $node->getAttribute('tag'),      'Furry',      'getAttribute' );   #5
is( $a = $node->getAttribute('category'), 'Me AND You', 'getAttribute' );   #6
is( $a = $node->getAttribute('FAKED'),    undef,        'getAttribute' );   #7


### PREPENDING AN ATTRIBUTE
$testnode = [
    [ 'scooby',   'Snack'      ],
    [ 'category', 'Me AND You' ],
    [ 'tag',       'Furry'     ],
    [ 'lastn',     '10'        ],
    [ 'setvar',    'Jerry'     ]
];
$node->prependAttribute('scooby', 'Snack');
is_deeply( [ $node->attributes ], $testnode, 'Prepending attribute' );     #8
is( $a = $node->getAttribute('scooby'),   'Snack',   'getAttribute' );     #9

### APPENDING AN ATTRIBUTE
$testnode = [
    [ 'scooby',   'Snack'      ],
    [ 'category', 'Me AND You' ],
    [ 'tag',       'Furry'     ],
    [ 'lastn',     '10'        ],
    [ 'setvar',    'Jerry'     ],
    [ 'zoey',      'Leigh'     ],
];
$node->appendAttribute('zoey', 'Leigh');
is_deeply( [ $node->attributes ], $testnode, 'Appending attribute' );      #10
is( $a = $node->getAttribute('zoey'),   'Leigh',   'getAttribute' );       #11
                                                                            
### SETTING AN EXISTING ATTRIBUTE
$testnode = [
    [ 'scooby',   'Snack'      ],
    [ 'category', 'Me AND You' ],
    [ 'tag',       'Furry'     ],
    [ 'lastn',     '10'        ],
    [ 'setvar',    'Jerry'     ],
    [ 'zoey',      'Leigh'     ],
    [ 'ophelia',   'Stella'     ],
];
$node->setAttribute('ophelia', 'Stella');
is_deeply( [ $node->attributes ], $testnode, 'Setting attribute' );        #12
is( $a = $node->getAttribute('ophelia'),   'Stella',   'getAttribute' );   #13
                                                                            
### PREPENDING AN ATTRIBUTE WITH AN EXISTING NAME
### GETTING THE VALUES OF A REPEATED ATTRIBUTE
$testnode = [
    [ 'ophelia',   'Chester'    ],
    [ 'scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'setvar',    'Jerry'      ],
    [ 'zoey',      'Leigh'      ],
    [ 'ophelia',   'Stella'     ],
];
$node->prependAttribute('ophelia', 'Chester');
is_deeply( [ $node->attributes ], $testnode,
        'Prepending attribute with existing name' );                       #14
is( @{ $a = $node->getAttribute('ophelia') }, 
    @{['Chester', 'Stella']}, 'getAttribute' );                            #15

### RENAMING AN ATTRIBUTE
$testnode = [
    [ 'ophelia',   'Chester'    ],
    [ 'scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'setvar',    'Jerry'      ],
    [ 'frannie',   'Leigh'      ],
    [ 'ophelia',   'Stella'     ],
];
$node->renameAttribute('zoey', 'frannie');
is_deeply( [ $node->attributes ], $testnode, 'Renaming attribute' );       #16
is( $a = $node->getAttribute('zoey'), undef, 'getAttribute' );             #17
is( $a = $node->getAttribute('frannie'), 'Leigh', 'getAttribute' );        #18

### RENAMING AN ATTRIBUTE WITH TWO VALUES
$testnode = [
    [ 'chichi',   'Chester'    ],
    [ 'scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'setvar',    'Jerry'      ],
    [ 'frannie',   'Leigh'      ],
    [ 'ophelia',   'Stella'     ],
];
$node->renameAttribute('ophelia', 'chichi');
is_deeply( [ $node->attributes ], $testnode,
        'Renaming attribute with two values' );                            #19

### RENAMING AN ATTRIBUTE WITH A CONFLICTING ATTRIBUTE NAME
$testnode = [
    [ 'chichi',   'Chester'    ],
    [ 'scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'setvar',    'Jerry'      ],
    [ 'frannie',   'Leigh'      ],
    [ 'ophelia',   'Stella'     ],
];
# $node->renameAttribute('setvar', 'frannie');
warning_like { $node->renameAttribute('setvar', 'frannie') }
    qr/Renaming of existing attribute failed/, 'Good warnings';            #20
is_deeply( [ $node->attributes ], $testnode, 'Rename conflict handling' ); #21

### FORCE RENAMING AN ATTRIBUTE WITH A CONFLICTING ATTRIBUTE NAME
$testnode = [
    [ 'chichi',   'Chester'    ],
    [ 'scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'frannie',    'Jerry'      ],
    [ 'frannie',   'Leigh'      ],
    [ 'ophelia',   'Stella'     ],
];
$node->renameAttribute('setvar', 'frannie', 'force');
is_deeply( [ $node->attributes ], $testnode ,
    'Forced dupe key rename' );                                            #22

### REMOVING AN ATTRIBUTE
$testnode = [
    [ 'chichi',   'Chester'    ],
    [ 'scooby',    'Snack'      ],
    [ 'category',  'Me AND You' ],
    [ 'tag',       'Furry'      ],
    [ 'lastn',     '10'         ],
    [ 'frannie',    'Jerry'      ],
    [ 'frannie',   'Leigh'      ],
];
$node->removeAttribute('ophelia');
is_deeply( [ $node->attributes ], $testnode, 'Attribute removal' );        #23

### REMOVING MULTIPLE ATTRIBUTES
$testnode = [
    [ 'chichi',   'Chester'    ],
    [ 'category',  'Me AND You' ],
    [ 'lastn',     '10'         ],
    [ 'frannie',    'Jerry'      ],
    [ 'frannie',   'Leigh'      ],
];
$node->removeAttribute('scooby', 'tag');
is_deeply( [ $node->attributes ], $testnode,
        'Removing multiple attributes' );                                  #24

### REMOVING AN ATTRIBUTE WITH TWO VALUES
$testnode = [
    [ 'chichi',   'Chester'    ],
    [ 'category',  'Me AND You' ],
    [ 'lastn',     '10'         ],
];
$node->removeAttribute('frannie');
is_deeply( [ $node->attributes ], $testnode,
        'Removing attribute with two values' );                            #25


### REFLOWING TEMPLATE TEXT
my $new_t = '<mt:Entries chichi="Chester" category="Me AND You" lastn="10">My Hours are insane </mt:Entries>';
$tmpl->text( $tmpl->reflow( $tokens ) );
is( $tmpl->text, $new_t, 'Template text upgraded' );                       #26

$tokens = $tmpl->tokens;
# diag($_->dump_node()) foreach @$tokens;
$node = $tokens->[0];

### PREPENDING A NODE
my $prepend = $tmpl->createElement( 'var' );
$prepend->setAttribute( 'name',  'blue' )
        ->setAttribute( 'value', 'hawaii'  );
my $inserted = $tmpl->insertBefore( $prepend, $node );
$tmpl->{reflow_flag} = 1;
is_deeply( $tmpl->tokens, [ $prepend, $node ], 'Prepended a node');        #27

my $new_text = $tmpl->reflow();
is( $new_text, '<mt:var name="blue" value="hawaii">'.$new_t,
                                'Prepended node in template text')         #28


