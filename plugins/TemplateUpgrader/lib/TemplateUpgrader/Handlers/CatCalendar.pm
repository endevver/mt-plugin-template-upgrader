package TemplateUpgrader::Handlers::CatCalendar;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

sub hdlr_default {
    my ($node) = @_;
    my $tag    = $node->tagName;    
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    if (lc $node->tagName eq 'ifcategoryarchivesenabled') {
        $node->tagName('ifarchivetypeenabled');
        $node->setAttribute('type', 'Category');
    }
    ###l4p $logger->debug('Finished '.$tag);
}

1;
