package TemplateUpgrader::Handlers::CatCalendar;

use strict;
use warnings;
use Carp;
use Data::Dumper;

sub PLUGIN() { 'CatCalendar' }

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

use base qw( TemplateUpgrader::Handlers );

sub hdlr_default {
    my ($node) = @_;
    my $tag    = $node->tagName();    
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    if (lc $tag eq 'ifcategoryarchivesenabled') {
        $node->tagName('ifarchivetypeenabled');
        $node->setAttribute('type', 'Category');
    }
    ###l4p $logger->debug('Finished '.$tag);
    __PACKAGE__->report( $node );
}

1;
