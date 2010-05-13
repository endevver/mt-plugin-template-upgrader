package TemplateUpgrader::Handlers::IfEmpty;

use strict;
use warnings;
use Carp;
use Data::Dumper;

sub PLUGIN() { 'IfEmpty' }

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

use base qw( TemplateUpgrader::Handlers );

sub hdlr_default {
    my ($node) = @_;
use TemplateUpgrader::Template;
    my $tag    = $node->tagName();
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    ###l4p $logger->debug('In handler for '.$tag);

    # We don't handle the expr attribute because it would be hard to do well
    #    <MTIfEmpty expr="[MTEntryComments]1[/MTEntryComments]">
    #        No comments have been posted yet.
    #    </MTIFEmpty>
    if ( $node->getAttribute('expr') ) {
        return __PACKAGE__->report_skipped(
            $node, 'Skipping tag '.$node->tagName
                    .' due to "expr" attribute.');
    }

    # IfEmpty -> If,  IfNotEmpty -> Unless
    $node->tagName( lc($tag) eq 'ifempty' ? 'If' : 'Unless' );

    # Rename attribute 'var' to 'tag' if it exists
    $node->renameAttribute('var', 'tag') if $node->[1]{'var'};

    # Add the eq="" attribute
    $node->setAttribute( 'eq' => '');

    ###l4p $logger->debug('Leaving handler for '.$tag);
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

