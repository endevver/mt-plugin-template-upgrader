package TemplateUpgrader::Handlers::Compare;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

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
    
#
# Possible attribute values
#
#   A string
#   [MTFoo] - Interpolated MT template tag
#   [MTGetVar name='showed_already']
#
sub hdlr_if_equal {
    my $node = shift;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    return unless process_attributes( $node );
    $node->tagName('if');
    ###l4p $logger->debug('Finished an IfEqual');
    

}
sub hdlr_if_not_equal {
    my $node = shift;
    
}
sub hdlr_if_greater_or_equal {
    
    my $node = shift;
}
sub hdlr_if_less_or_equal {
    my $node = shift;
    
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
        $logger->warn('Skipping '.$node->tagName.' node');
        return 0;
    }
    elsif ( keys %$node_attr > 2 ) {
        $logger->warn('Skipping '.$node->tagName.' node. Too many attributes.');
        return 0;
    }
    elsif ( keys %$node_attr < 2 ) {
        $logger->warn('Skipping '.$node->tagName.' node. Not enough attributes.');
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
                $logger->error('Skipping tag due to compilation error');
                return 0;
            }

            $logger->debug('PARSED: ', l4mtdump({
                attr     => $attr,
                attr_val => $node_attr->{$attr},
                tok      => $tok,
            }));

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
        $logger->warn('Skippng node. '.$node->tagName
                      .' used two scalar values (no tag/variable)');
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
        # The 'b' attribute takes a 
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
            next unless $set->{type} eq 'var';
            my $tok    = delete $set->{token};
            $set->{type} = 'val';
            $set->{op}   = $op;
            $set->{val}  = '$'.$tok->getAttribute('name'); # $ for variable interpolation
        }
    }

    $logger->debug('@attr_sets: ', l4mtdump(\@attr_sets));

    # Remove all current attributes from the current node
    $node->removeAttribute( $_ ) foreach keys %$node_attr;

    my %new_attr;
    foreach my $set ( @attr_sets ) {
        if ( $set->{type} eq 'val' ) {
            $node->setAttribute( $set->{op}, $set->{val} );
        }
        else {
            my $tok        = $set->{token};
            $node->setAttribute( 'tag', $tok->tagName )
                if $set->{type} eq 'tag';
            $node->setAttribute( $_, $tok->getAttribute($_) )
                foreach keys %{ $tok->[1] };
        }
    }
    $logger->debug('$node FINAL: ', l4mtdump($node));
    
    1;
}

sub hdlr_if_less {
    my $node = shift;
    
}
sub hdlr_if_greater {
    my $node = shift;
    
}
sub hdlr_if_not_between {
    my $node = shift;
    
}
sub hdlr_if_between {
    my $node = shift;
    
}
sub hdlr_if_between_exclusive {
    my $node = shift;
    
}

# Rewrite GetVar to Var
sub hdlr_get_var {
    my $node = shift;
    $node->tagName('Var');
}

sub hdlr_if_one {
    my $node = shift;
    $node->tagName('If');
    $node->setAttribute('eq', 1);
}

sub hdlr_unless_zero {
    my $node = shift;
    $node->tagName('IfNonZero');
}

sub hdlr_unless_empty {
    my $node = shift;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    # $logger->debug('$node BEFORE: ', l4mtdump($node));
    $node->tagName('IfNonEmpty');
    $logger->debug('$node AFTER: ', l4mtdump($node));
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