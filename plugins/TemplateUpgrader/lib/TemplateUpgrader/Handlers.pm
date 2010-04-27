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

1;

__END__

# This demonstrates a tag name change
sub hdlr_setvar {
    my $node = shift;
    $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    $node->tagName('Var');
}


# This demonstrates modification of order-sensitive
# attributes based on a condition
sub hdlr_include {
    my $node = shift;

    # If we're including a module...
    if ( defined $node->getAttribute('module') ) {

        # Set the woohoo attribute
        $node->setAttribute('woohoo', 1);

        # Set the ordering of the attributes, if needed
        $node->[4] = [
                        [ 'module' => $node->getAttribute('module') ],
                        [ 'woohoo' => $node->getAttribute('woohoo') ]
                    ];
    }
}