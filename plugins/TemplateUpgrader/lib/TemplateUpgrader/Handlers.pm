package TemplateUpgrader::Handlers;
use strict; use warnings; use Carp; use Data::Dumper;

# This demonstrates a tag name change
sub hdlr_setvar {
    my $node = shift;
    $node->tagName('Var');
}

# This demonstrates modification of order-sensitive attributes based on a condition
sub hdlr_include {
    my $node = shift;

    # If we're including a module...
    if ( defined $node->getAttribute('module') ) {

        # Set the woohoo attribute
        $node->setAttribute('woohoo', 1);

        # Set the ordering of the attributes, if needed
        $node->[4] = [
                        [ 'module' => $node->getAttribute('module') ],
                        [ 'woohoo' => $node->getAttribute('woohoo') ]
                    ];
    }
}


1;