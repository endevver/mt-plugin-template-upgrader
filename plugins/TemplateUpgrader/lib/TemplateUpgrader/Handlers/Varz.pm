package TemplateUpgrader::Handlers::Varz;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

# Rewrite GetVar to Var
sub hdlr_get_var {
    my $node = shift;
    $node->tagName('Var');
}

sub hdlr_if_one {
    my $node = shift;
    $node->tagName('If');
    $node->setAttribute('eq', 1);
}

sub hdlr_unless_zero {
    my $node = shift;
    $node->tagName('Unless');
    $node->setAttribute('eq', 0);
}

sub hdlr_unless_empty {
    my $node = shift;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    # $logger->debug('$node BEFORE: ', l4mtdump($node));
    $node->tagName('Unless');
    $node->setAttribute('eq', '');
    # $node->tagName('IfNonEmpty');
    # $logger->debug('$node AFTER: ', l4mtdump($node));
}

# This demonstrates modification of order-sensitive attributes based on a condition
#
# sub hdlr_include {
#     my $node = shift;
# 
#     # If we're including a module...
#     if ( defined $node->getAttribute('module') ) {
# 
#         # Set the woohoo attribute
#         $node->setAttribute('woohoo', 1);
# 
#         # Set the ordering of the attributes, if needed
#         $node->[4] = [
#                         [ 'module' => $node->getAttribute('module') ],
#                         [ 'woohoo' => $node->getAttribute('woohoo') ]
#                     ];
#     }
# }


1;