package TemplateUpgrader::Handlers::IfEmpty;
use strict; use warnings; use Carp; use Data::Dumper;

use base qw( TemplateUpgrader::Handlers );

# use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

sub PLUGIN() { 'IfEmpty' }

sub hdlr_default {
    my ($node) = @_;
    my $tag    = $node->tagName();

    # We don't handle the expr attribute because it would be hard to do well
    #    <MTIfEmpty expr="[MTEntryComments]1[/MTEntryComments]">
    #        No comments have been posted yet.
    #    </MTIFEmpty>
    if ( $node->getAttribute('expr') ) {
        return __PACKAGE__->report_skipped(
            [ $node ], 'Skipping tag '.$node->tagName
                        .' due to "expr" attribute.');
    }

    # IfEmpty -> If,  IfNotEmpty -> Unless
    $node->tagName( lc($tag) eq 'ifempty' ? 'If' : 'Unless' );

    # Rename attribute 'var' to 'tag' if it exists. If not, it's silent
    $node->renameAttribute('var', 'tag');

    # Add the eq="" attribute
    $node->appendAttribute( 'eq' => '');

    __PACKAGE__->report([ $node ]);
}

1;

