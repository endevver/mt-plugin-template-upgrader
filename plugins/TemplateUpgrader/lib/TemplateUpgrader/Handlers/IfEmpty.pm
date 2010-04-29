package TemplateUpgrader::Handlers::IfEmpty;

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

    # We don't handle the expr attribute because it would be hard to do well
    #    <MTIfEmpty expr="[MTEntryComments]1[/MTEntryComments]">
    #        No comments have been posted yet.
    #    </MTIFEmpty>
    if ( $node->getAttribute('expr') ) {
        $logger->warn('Skipping tag '.$node->tagName.' due to "expr" attribute.');
        return;
    }

    # IfEmpty -> If,  IfNotEmpty -> Unless
    $node->tagName( lc($tag) eq 'ifempty' ? 'If' : 'Unless' );

    # Add the eq="" attribute
    $node->setAttribute( 'eq' => '');

    # Replace var= with tag=
    if ( my $tag = $node->getAttribute('var') ) {
        $node->setAttribute('tag');
        $node->removeAttribute('var');
    }
    ###l4p $logger->debug('Finished '.$tag);
}

1;

