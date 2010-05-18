package TemplateUpgrader::Handlers::Core;
use strict; use warnings; use Carp; use Data::Dumper;

use base qw( TemplateUpgrader::Handlers );

# use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

sub PLUGIN() { 'Core' }

sub hdlr_else {
    my $node             = shift;
    my $tmpl             = $node->ownerDocument();
    $tmpl->{reflow_flag} = 1;
    $node->tagName( lc($node->tagName) );
    return __PACKAGE__->report([ $node ]);
}

1;

__END__

# Structure of a node:
#   [0] = tag name
#   [1] = attribute hashref
#   [2] = contained tokens
#   [3] = template text
#   [4] = attributes arrayref
#   [5] = parent array reference
#   [6] = containing template

