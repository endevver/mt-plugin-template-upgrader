package TemplateUpgrader::Handlers::Varz;
use strict; use warnings; use Carp; use Data::Dumper;

use base qw( TemplateUpgrader::Handlers );

# use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

sub PLUGIN() { 'MT-Varz' }

BEGIN {

    my %dispatch = (
        get_var      => sub {   $_[0]->tagName('var')               },

        set_var      => sub {   $_[0]->tagName('var')               },

        if_one       => sub {   $_[0]->tagName('if')
                                     ->setAttribute('eq', 1)        },

        unless_zero  => sub {   $_[0]->tagName('unless')
                                     ->setAttribute('eq', 0)        },

        unless_empty => sub {   $_[0]->tagName('unless')
                                     ->setAttribute('eq', '')       },
    );

    foreach my $fn ( keys %dispatch ) {
        no strict 'refs';
        *{'hdlr_'.$fn} = sub {
            my $node             = shift;
            my $tmpl             = $node->ownerDocument();
            $tmpl->{reflow_flag} = 1;
            $dispatch{$fn}->( $node, @_ );
            $node->tagName( lc($node->tagName) );
            __PACKAGE__->report([ $node ])
        }
    }
}

1;