package TemplateUpgrader::Handlers;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();


sub default_hdlr {
    my ($self, $node, $params ) = @_;
    my $attrs   = $node->[1];
    my $tmpl    = $node->template;
    my $blog    = $tmpl->blog;
    my $tmpl_id = $tmpl && $tmpl->id ? $tmpl->id : 0;
    my $blog_id = $blog ? $blog->id : 0;
    my $plugin  = 
    my $tag     = $node->tagName;
    my $logger = MT::Log::Log4perl->new( $params->{plugin} ); # $logger->trace();
    # $logger->debug('$blog: ', l4mtdump({ blog => $blog, tmpl => $tmpl, node1 => $node->[1] }));
    $logger->info(
          sprintf('%-10d %-10s Not transformed: ', $blog_id, $tmpl_id )
        . ' '.join( " ", $tag, map { join('=', $_, $attrs->{$_}) } keys %$attrs )
    );
}

sub report {
    my $node = shift;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    ###l4p $logger->info($node->tagName.': Skipping node, no transformation defined');
}

sub report_skipped {
    my $node = shift;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    ###l4p $logger->info($node->tagName.': Skipping node, no transformation defined');
}

1;
