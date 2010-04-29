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
    my $tmpl  = $node->template;
    my $blog  = $tmpl->blog;
    my $tag   = $node->tagName;
    # $logger->debug('$blog: ', l4mtdump({ blog => $blog, tmpl => $tmpl, node1 => $node->[1] }));
    $logger->info(
          sprintf('PLUGIN TAG %s (%s, %s): ', $tag, $blog->id, $tmpl->id)
        . join( " ", $tag, map { join('=', $_, $attrs->{$_}) } keys %$attrs )
    );
}

sub _no_transform {
    my $node = shift;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    ###l4p $logger->info($node->tagName.': Skipping node, no transformation defined');
}

1;
