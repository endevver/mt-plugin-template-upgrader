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
    my $prepend = $params->{prepend};
    my $tmpl    = $node->ownerDocument;
    my $blog    = $tmpl->blog;
    my $tmpl_id = $tmpl && $tmpl->id ? $tmpl->id : 0;
    my $blog_id = $blog ? $blog->id : 0;

    my $tagattr = '';
    foreach my $tok ( $prepend, $node ) {
        next unless defined $tok;
        my $tag        = $tok->tagName;
        my $attrs      = $tok->[1];
        my @attr_order = split(',', $tok->[1]{_attr_order}||'');
        $tagattr      .= join( " ", $tag, map { join('=', $_, $attrs->{$_}||'') } @attr_order ).' // ';
    }

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
    my $prepend;

    eval {
        ( $node, $prepend ) = @$node if ref($node) eq 'ARRAY';
    };
    if ( $@ ) {
        $logger->debug('$node: ', l4mtdump($node));
        die "Node ain't right here with ref ".ref($node).' '.Carp::longmess();
    }

    $self->_report({
        plugin  => $self->PLUGIN,
        node    => $node,
        message => ($message||''),
        ($prepend ? (prepend => $prepend) : ()),
    });
}

sub report_skipped {
    my $self               = shift;
    my ( $node, $message ) = @_;
    my $prepend;
    ( $node, $prepend ) = @$node
        unless $node->isa('TemplateUpgrader::Template::Node');
    $self->_report({
        plugin  => $self->PLUGIN,
        node    => $node,
        message => ($message||''),
        ($prepend ? (prepend => $prepend) : ()),
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

