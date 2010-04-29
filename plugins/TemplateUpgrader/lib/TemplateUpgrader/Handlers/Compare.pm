package TemplateUpgrader::Handlers::Compare;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

use base qw( TemplateUpgrader::Handlers );

our %operators = (
    ifequal          => 'eq',
    ifnotequal       => 'ne',
    ifless           => 'lt',
    ifgreater        => 'gt',
    ifgreaterorequal => 'ge',
    iflessorequal    => 'le'
    # ifnotbetween          # 
    # ifbetween             # We don't handle these three tags
    # ifbetweenexclusive    #
);
    
our %reverse_tags = (
    ifequal          => 'ifequal',
    ifnotequal       => 'ifnotequal',
    ifless           => 'ifgreater',
    ifgreater        => 'ifless',
    ifgreaterorequal => 'iflessorequal',
    iflessorequal    => 'ifgreaterorequal',
);
    
BEGIN {
    no strict 'refs';
    # Tags we transform
    *${\"hdlr_$_"} = \&hdlr_default
        foreach qw( if_equal     if_less    if_greater_or_equal 
                    if_not_equal if_greater if_less_or_equal   );
    # Tags we don't transform
    *${\"hdlr_$_"} = __PACKAGE__->can('_no_transform')
        foreach qw( ifnotbetween  ifbetween  ifbetweenexclusive );
}

sub hdlr_default {
    my ($node, $newtag) = @_;
    $newtag ||= 'If';
    my $tag    = $node->tagName;    
    ##l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    ##l4p $logger->debug('In handler for '.$tag);
    process_attributes( $node ) && $node->tagName( $newtag );
    ##l4p $logger->debug('Leaving handler for '.$tag);
}

sub process_attributes {
    my $node      = shift;
    my $node_attr = $node->[1];
    my $tmpl      = $node->template;
    my $upgrader  = TemplateUpgrader->new();
    my $op        = $operators{ lc($node->tagName) } or return;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    # We don't deal with the case_sensitive, number or  
    # numbered 'b' attributes (e.g. b1, b2, b3, etc)
    if ( grep { 
                m{
                    ^(                      # Start of string
                        case_sensitive      # Would have to turn it into a regex
                            |               #
                        numeric             # No analog to this
                            |               #
                        b\d+                # b1, b2, b3
                    )$                      #
                }xi 
            } keys %$node_attr ) {
        ###l4p $logger->info('Skipping '.$node->tagName.' node');
        return 0;
    }
    elsif ( keys %$node_attr > 2 ) {
        ###l4p $logger->info('Skipping '.$node->tagName.' node. Too many attributes.');
        return 0;
    }
    elsif ( keys %$node_attr < 2 ) {
        ###l4p $logger->info('Skipping '.$node->tagName.' node. Not enough attributes.');
        return 0;
    }

    # Possible combinations for attributes a & b between a tag (If tag="")
    # a template variable (name="blah" or eq="$blah") or a scalar value.
    #
    #   COMBO       ACTION
    #   tag val      OK
    #   var val      OK
    #   val val      Prepend node + setvar, turns into "name var"!
    #                
    #   tag tag      Prepend node + setvar, turns into "tag var"!
    #   var tag      Convert var to val using $interpolation
    #   val tag      FLIP!
    #                
    #   tag var      Convert var to val using $interpolation
    #   var var      OK
    #   val var      FLIP!

    my ( @attr_sets );
    foreach my $attr ( keys %$node_attr ) {

        # Attribute values like a="[MTGetVar name='what']"
        #                    or a="[MTFoo format='1' iso='1']"
        if ( $node_attr->{$attr} =~ m{
                ^\[                 # Starts with a [
                    \s*             # Possible spaces
                    (               #
                        MT          # The MT tag
                        .*?         # and its attributes
                    )               #
                    \s*             # Optional spaces
                \]$                 # Ends with a ]
            }smxi ) {

            my $tok = $upgrader->compile_markup( '<'.$1.'>' );
            if ( ! defined $tok ) {
                ###l4p $logger->warn('Skipping tag due to compilation error');
                return 0;
            }

            ###l4p $logger->debug($node->tagName .' PARSED ATTRIBUTE: ', l4mtdump({
            ###l4p     attr     => $attr,
            ###l4p     attr_val => $node_attr->{$attr},
            ###l4p     tok      => $tok,
            ###l4p }));

            $tok = shift @$tok;
            
            my $attr_type = (lc($tok->tagName) eq 'getvar') ? 'var' : 'tag';
            push @attr_sets, { type => $attr_type, token => $tok };
        }
        # Normal scalar attribute values, e.g. b="John"
        else {
            push @attr_sets, { type => 'val', 
                                 op => $op,
                                val => $node_attr->{$attr} };
        }
    }

    if (    $attr_sets[0]{type} eq 'val'
        and $attr_sets[1]{type} eq 'val' ) {
        ###l4p $logger->info('Skipping node. '.$node->tagName
        ###l4p               .' used two scalar values (no tag/variable)');
        return 0;
    }


    # From combination chart above
    #   tag tag      Prepend node + setvar, turns into "tag var"!
    if (    $attr_sets[0]{type} eq 'tag'
        and $attr_sets[1]{type} eq 'tag' ) {
        my $tok  = $attr_sets[1]{token};
        my $tag  = $tok->tagName;
        # We have to add a setvar assignment node for the 'b' case.
        my $prepend_attr = { setvar => 'mt'.lc($tag) };
        my $prepend = $tmpl->createElement( lc($tag), $prepend_attr );
        my $inserted = $tmpl->insertBefore( $prepend, $node );
        $prepend->setAttribute('setvar', 'mt'.lc($tag));
        # The b attributes becomes an interpolated template variable
        # set by the setvar attribute of the prepended node above
        $attr_sets[1]{type} = 'val';
        $attr_sets[1]{op}   = $op;
        $attr_sets[1]{val}  = '$mt'.lc($tag); # $ for variable interpolation
    }
    # From combination chart above
    #   var tag      FLIP!
    #   val tag      FLIP!
    #   val var      FLIP!
    elsif ( $attr_sets[1]{type} eq 'tag' 
            or (    $attr_sets[0]{type} eq 'val'
                and $attr_sets[1]{type} eq 'var' )) {
        @attr_sets = reverse @attr_sets;
        $node->tagName( $reverse_tags{ lc $node->tagName } );
    }

    # From combination chart above
    #   var tag      Convert var to val using $interpolation
    #   tag var      Convert var to val using $interpolation
    if (   ($attr_sets[0]{type} eq 'tag' and $attr_sets[1]{type} eq 'var')
        || ($attr_sets[0]{type} eq 'var' and $attr_sets[1]{type} eq 'tag')) {
        foreach my $set ( @attr_sets ) {
            if ($set->{type} eq 'var') {
                my $tok    = delete $set->{token};
                $set->{type} = 'val';
                $set->{op}   = $op;
                $set->{val}  = '$'.$tok->getAttribute('name'); # $ for variable interpolation
            }
            else { # $set->{type} eq 'tag'
            }
        }
        
    }

    ###l4p $logger->debug('@attr_sets: ', l4mtdump(\@attr_sets));

    # Remove all current attributes from the current node
    $node->removeAttribute( $_ ) foreach keys %$node_attr;

    foreach my $set ( @attr_sets ) {
        if ( $set->{type} eq 'val' ) {
            $node->setAttribute( $set->{op}, $set->{val} );
            # push @{ $node->[4] }, [ $set->{op}, $set->{val} ];
        }
        else {
            my $tok        = $set->{token};
            $node->setAttribute( 'tag', $tok->tagName )
                if $set->{type} eq 'tag';
            $node->setAttribute( $_, $tok->getAttribute($_) )
                foreach keys %{ $tok->[1] };
                # unshift @args, 'tag', $set->{token}->tagName;

            foreach my $k ( qw( name tag )) {
                next unless exists $node->[1]{$k};
                unshift @{ $node->[4] }, [ $k, $node->getAttribute( $k ) ];
            }
        }
    }
    ###l4p $logger->debug($node->tagName.' FINAL ATTRIBUTES: ', l4mtdump($node->[1]));
    
    1;
}

# This demonstrates modification of order-sensitive attributes based on a condition
#
# sub hdlr_include {
#     my $node = shift;
# 
#     # If we're including a module...
#     if ( defined $node->getAttribute('module') ) {
# 
#         # Set the woohoo attribute
#         $node->setAttribute('woohoo', 1);
# 
#         # Set the ordering of the attributes, if needed
#         $node->[4] = [
#                         [ 'module' => $node->getAttribute('module') ],
#                         [ 'woohoo' => $node->getAttribute('woohoo') ]
#                     ];
#     }
# }


1;