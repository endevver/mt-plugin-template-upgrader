package TemplateUpgrader::Handlers::Varz;
use strict; use warnings; use Carp; use Data::Dumper;

use base qw( TemplateUpgrader::Handlers );

# use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

sub PLUGIN() { 'MT-Varz' }

BEGIN {

    my %dispatch = (
        get_var      => sub {   $_[0]->tagName('Var')              },

        set_var      => sub {   $_[0]->tagName('Var')              },

        if_one       => sub {   $_[0]->tagName('If');              
                                $_[0]->appendAttribute('eq', 1)    },

        unless_zero  => sub {   $_[0]->tagName('Unless');          
                                $_[0]->appendAttribute('eq', 0)    },

        unless_empty => sub {   $_[0]->tagName('Unless');          
                                $_[0]->appendAttribute('eq', '')   },
    );

    foreach my $fn ( keys %dispatch ) {
        *{'hdlr_'.$fn} = sub {
            $dispatch{$fn}->( @_ );
            __PACKAGE__->report([ @_ ])
        }
    }
}

1;