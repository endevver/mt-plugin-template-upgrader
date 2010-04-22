package TemplateUpgrader::Handlers;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

sub default_hdlr {
    my $node = shift;
    require MT::Log::Log4perl;
    $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    my $attrs = $node->[1];
    # $logger->debug('$node->[1]: ', l4mtdump($node->[1]));
    my $tmpl = $node->template;
    # $logger->debug('$tmpl: ', l4mtdump($tmpl));
    my $blog = $tmpl->blog;
    # $logger->debug('$blog: ', l4mtdump($blog));
    $logger->info(
          sprintf('PLUGIN TAG (%s, %s): ', $tmpl->id, $blog->id)
        . join( " ",
                $node->tagName,
                map { join('=', $_, $attrs->{$_}) }
                    keys %$attrs
          )
    );
}

# This demonstrates a tag name change
#
# sub hdlr_setvar {
#     my $node = shift;
#     $node->tagName('Var');
# }


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