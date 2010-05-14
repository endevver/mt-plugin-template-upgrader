package TemplateUpgrader::Handlers::CatCalendar;
use strict; use warnings; use Carp; use Data::Dumper;

use base qw( TemplateUpgrader::Handlers );

# use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

sub PLUGIN() { 'CatCalendar' }

sub hdlr_default {
    my ($node)   = @_;
    my $tag      = $node->tagName();
    my $reporter = __PACKAGE__->can('report_skipped');

    if (lc $tag eq 'ifcategoryarchivesenabled') {
        $node->tagName(       'ifarchivetypeenabled'  );
        $node->setAttribute(  'type',     'Category'  );
        $reporter = __PACKAGE__->can('report');
    }

    $reporter->(__PACKAGE__, [ $node ])
}

1;
