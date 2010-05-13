package TemplateUpgrader::Handlers::Varz;

use strict;
use warnings;
use Carp;
use Data::Dumper;

sub PLUGIN() { 'MT-Varz' }

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

use base qw( TemplateUpgrader::Handlers );

# Rewrite GetVar to Var
sub hdlr_get_var {
    my $node = shift;
    $node->tagName('Var');
    __PACKAGE__->report( $node );
}

sub hdlr_if_one {
    my $node = shift;
    $node->tagName('If');
    $node->setAttribute('eq', 1);
    __PACKAGE__->report( $node );
}

sub hdlr_unless_zero {
    my $node = shift;
    $node->tagName('Unless');
    $node->setAttribute('eq', 0);
    __PACKAGE__->report( $node );
}

sub hdlr_unless_empty {
    my $node = shift;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    # $logger->debug('$node BEFORE: ', l4mtdump($node));
    $node->tagName('Unless');
    $node->setAttribute('eq', '');
    # $node->tagName('IfNonEmpty');
    # $logger->debug('$node AFTER: ', l4mtdump($node));
    __PACKAGE__->report( $node );
}

sub report {
    my $self               = shift;
    my ( $node, $message ) = @_;
    $self->SUPER::report({
        plugin  => PLUGIN,
        node    => $node,
        message => ($message||'')
    });
}

sub report_skipped {
    my $self               = shift;
    my ( $node, $message ) = @_;
    $self->SUPER::report_skipped({
        plugin  => PLUGIN,
        node    => $node,
        message => ($message||'')
    });
}

1;