package TemplateUpgrader::Handlers;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();


sub default_hdlr {
    my ($self, $node, $params ) = @_;
    $self->_report( { node => $node, %$params }, 'SKIPPED' );
}

sub _report {
    my ( $self, $params, $skipped ) = @_;
    my $node    = $params->{node};
    my $attrs   = $node->[1];
    my $tmpl    = $node->template;
    my $blog    = $tmpl->blog;
    my $tmpl_id = $tmpl && $tmpl->id ? $tmpl->id : 0;
    my $blog_id = $blog ? $blog->id : 0;
    my $tag     = $node->tagName;
    my $tagattr = join( " ", $tag, map { join('=', $_, $attrs->{$_}) } keys %$attrs );

    my $message = $skipped ? 'Not transformed' : 'Transformed';
    $message    = join('--', $message, $params->{message} )
        if $params->{message};

    my $logger  = MT::Log::Log4perl->new( $params->{plugin} ); # $logger->trace();
    # $logger->debug('$blog: ', l4mtdump({ blog => $blog, tmpl => $tmpl, node1 => $node->[1] }));
    $logger->info(
          sprintf("%-10d %-10s $message: ", $blog_id, $tmpl_id ),
          $tagattr
    );
    return ( ! $skipped );
}

sub report {
    my $self               = shift;
    my ( $node, $message ) = @_;
    $self->_report({
        plugin  => $self->PLUGIN,
        node    => $node,
        message => ($message||'')
    });
}

sub report_skipped {
    my $self               = shift;
    my ( $node, $message ) = @_;
    $self->_report_skipped({
        plugin  => $self->PLUGIN,
        node    => $node,
        message => ($message||'')
    }, 'SKIPPED');
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

