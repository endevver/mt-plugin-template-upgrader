package TemplateUpgrader::Handlers::Compare;
use strict; use warnings; use Carp; use Data::Dumper;

use base qw( TemplateUpgrader::Handlers );

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

use Scalar::Util qw( looks_like_number );

sub PLUGIN() { 'Compare' }

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
    #    ifnotbetween  ifbetween  ifbetweenexclusive
}

sub operator { $operators{ lc($_[0]) } }

sub reverse_tag { $reverse_tags{ lc($_[0]) } }

sub hdlr_default {
    my ($node, $newtag) = @_;
    $newtag ||= 'If';
    my $tag    = $node->tagName;    
    ##l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    ##l4p $logger->debug('In handler for '.$tag);
    my @nodes = process_attributes( $node ) or return; # i.e. an error
    $node->tagName( $newtag );
    ##l4p $logger->debug('Leaving handler for '.$tag);
    __PACKAGE__->report( @nodes > 1 ? [ @nodes ] : shift @nodes );
}

sub process_attributes {
    my $node      = shift;
    my $node_attr = $node->[1];
    my $tmpl      = $node->template;
    my $upgrader  = TemplateUpgrader->new();
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    my $op        = operator( lc($node->tagName) )  
        or return __PACKAGE__->report_skipped($node,
                                'Skipping node due to unrecognized tag');

    # EXCEPTIONAL ATTRIBUTES AND ATTRIBUTE COMBINATIONS
    my $invalid = invalid_attributes( $node );
    return $invalid if defined $invalid;

    # PARSE ATTRIBUTE VALUES INTO ATTRIBUTE SETS
    my @attr_sets;
    foreach ( @{ $node->[4] } ) {
        my $attr_set = parse_attr_value( $node, $_->[1], $op );
        # The returned value should be a hash reference.  A number (probably
        # is an exceptional error condition that aborts our processing of
        # this tag.  The error has already been reported to the client.
        return if looks_like_number $attr_set; 
        push( @attr_sets, $attr_set  );
        
    }

    # Possible combinations for attributes a & b between a tag (If tag="")
    # a template variable (name="blah" or eq="$blah") or a scalar value.
    #
    #   COMBO        ACTION
    #   tag val       OK
    #   var val       OK
    #   var var       OK
    #                 
    #   val tag       FLIP and invert condition if needed
    #   val var       FLIP and invert condition if needed
    #                 
    #   val val       Prepend node + setvar, turns into "name var"!
    #   tag tag       Prepend node + setvar, turns into "tag var"!
    #                 
    #   var tag       Make var a val with variable $interpolation
    #   tag var       Make var a val with variable $interpolation

    
    if (    $attr_sets[0]{type} eq 'val'
        and $attr_sets[1]{type} eq 'val' ) {

        # We have to add a setvar assignment node for the 'b' case.
        my $prepend_attr = { name => 'compare_val', value => $attr_sets[0]{val} };
        my $prepend = $tmpl->createElement( 'var', $prepend_attr );
        ###l4p $logger->debug('PROCATTR PREPEND: '. $prepend->dump_node());

        my $inserted = $tmpl->insertBefore( $prepend, $node );
        $prepend->prependAttribute( 'value', $attr_sets[0]{val} );
        $prepend->prependAttribute( 'name', 'compare_val' );
        ###l4p $logger->debug('PROCATTR PREPEND: '. $prepend->dump_node());

        # The b attributes becomes an interpolated template variable
        # set by the setvar attribute of the prepended node above
        # $node->prependAttribute( 'name', $attr_sets[0]{val} );
        $node->setAttribute( 'name', $attr_sets[0]{val} );
        ###l4p $logger->debug('PROCATTR NODE: '. $prepend->dump_node());

        $attr_sets[0]{type} = 'var';
        $attr_sets[0]{val}  = 'compare_val';
        delete $attr_sets[0]{op};
        $attr_sets[1]{type} = 'val';
        $attr_sets[1]{op}   = $op;
        # $attr_sets[1]{val}  = '$compare_val'; # $ for variable interpolation
        ###l4p $logger->debug('PROCATTR attr_sets: ', l4mtdump(@attr_sets));

        # return __PACKAGE__->report_skipped($node, 'Skipping node. '.$node->tagName
        #                     .' used two scalar values (no tag/variable)');
    }


    # From combination chart above
    #   tag tag      Prepend node + setvar, turns into "tag var"!
    if (    $attr_sets[0]{type} eq 'tag'
        and $attr_sets[1]{type} eq 'tag' ) {
        my $tok  = $attr_sets[1]{token};
        my $tag  = $tok->tagName;
        # We have to add a setvar assignment node for the 'b' case.
        my $prepend_attr = { setvar => 'tag_mt'.lc($tag) };
        my $prepend = $tmpl->createElement( lc($tag), $prepend_attr );
        my $inserted = $tmpl->insertBefore( $prepend, $node );
        $prepend->setAttribute('setvar', 'tag_mt'.lc($tag));
        # The b attributes becomes an interpolated template variable
        # set by the setvar attribute of the prepended node above
        $attr_sets[1]{type} = 'val';
        $attr_sets[1]{op}   = $op;
        $attr_sets[1]{val}  = '$tag_mt'.lc($tag); # $ for variable interpolation
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
    $node->removeAttribute( $_ ) foreach grep { $_ ne '_attr_order' } keys %$node_attr;

    my $prepend;
    foreach my $set ( @attr_sets ) {
        if ( $set->{type} eq 'val' ) {
            $node->setAttribute( $set->{op}, $set->{val} );
            # push @{ $node->[4] }, [ $set->{op}, $set->{val} ];
        }
        elsif ( $set->{type} eq 'var' and ! $set->{token} ) {
            $node->setAttribute( 'name', $set->{val} );
            # push @{ $node->[4] }, [ $set->{op}, $set->{val} ];
        }
        else {
            my $tok        = $set->{token};
            $logger->debug('TOKEE: '.$tok->dump_node());
            my @tok_order = split(',', $tok->[1]{_attr_order}||'');
             
            if ( keys %{ $tok->[1] } > 2 ) { # e.g. A modifier on GetVar 
                
                # We have to prepend a setvar assignment node to handle the
                # of the tag/var attribute
                my $prepend_attr = {
                    (map { $_ => $tok->getAttribute($_)||'' } @tok_order),
                };
                $prepend_attr->{setvar}      = 'compare_val';
                $prepend_attr->{_attr_order}
                    = join(',',$tok->[1]{_attr_order},'setvar');
                $prepend = $tmpl->createElement( 'var', $prepend_attr );
                ###l4p $logger->debug('PROCATTR PREPEND: '. $prepend->dump_node());

                foreach my $k ( @tok_order, 'setvar' ) {
                    $prepend->setAttribute( $k, $prepend_attr->{$k} );
                    next if $k eq '_attr_order';
                    push( @{$prepend->[4]}, [ $k, $prepend_attr->{$k} ])
                }
                my $inserted = $tmpl->insertBefore( $prepend, $node );
                ###l4p $logger->debug('PROCATTR PREPEND: '. $prepend->dump_node());

                # $node->setAttribute( 'tag', $tok->tagName )
                #     if $set->{type} eq 'tag';
                $node->setAttribute( 'name', 'compare_val' );
                my @node_order = split(',', $node->[1]{_attr_order}||'');
                $node->setAttribute( $_, $tok->getAttribute($_) )
                    foreach grep { $_ ne 'tag' and $_ ne 'name' } @node_order;
                ###l4p $logger->debug('PROCATTR NODE: '. $node->dump_node());
                
            }
            else {
                $node->setAttribute( 'tag', $tok->tagName )
                    if $set->{type} eq 'tag';
                $node->setAttribute( $_, $tok->getAttribute($_) )
                    foreach grep { $_ ne 'tag' } @tok_order;
                # $node->setAttribute( 'tag', $tok->tagName )
                #     if $set->{type} eq 'tag';
                # $node->setAttribute( $_, $tok->getAttribute($_) )
                #     foreach keys %{ $tok->[1] };
                    # unshift @args, 'tag', $set->{token}->tagName;
                $logger->debug('NODEE: '.$node->dump_node());

                # foreach my $k ( qw( name tag )) {
                #     next unless exists $node->[1]{$k};
                #     unshift @{ $node->[4] }, [ $k, $node->getAttribute( $k ) ];
                # }                
            }
        }
    }
    ###l4p $logger->debug($node->tagName.' FINAL NODE: '.$node->dump_node());
    ###l4p $logger->debug($node->tagName.' FINAL PREPEND: '.$prepend->dump_node()) if $prepend;
    return ( $node, $prepend );
    1;
}

sub flip_attributes {
    
}

# A tag like the following with two uninterpolated VALUES:
#
#       <mt:IfEqual a="VAL1" b="VAL2">...</mt:IfEqual>
#
# Needs to be split into a second tag ($prepend below) to set 
# up a variable to be used with the 'name' attribute:
#
#  <mt:var name="compare_val" value="VAL1">  
#      <mt:If name="compare_val" eq="VAL2">...</mt:Else>
#
# The above is broken over two lines for readability.  In real-world
# situations the tags would be adjacent with no intervening space.
#
sub split_attributes {
    my ($node, $left, $right) = @_;
    my $tmpl      = $node->template;

    if (    $left->{type} eq 'val'
        and $right->{type} eq 'val' ) {

        ### Create the tag to insert before our current one
        my $prepend = $tmpl->createElement(
            'var', { name => 'compare_val',  value => $left->{val} } );
        $prepend->setAttribute( 'name', 'compare_val' );
        $prepend->setAttribute( 'value', $left->{val} );
        ###l4p $logger->debug('PROCATTR PREPEND: '. $prepend->dump_node());

        # The b attributes becomes an interpolated template variable
        # set by the setvar attribute of the prepended node above
        # $node->prependAttribute( 'name', $left->{val} );
        $node->prependAttribute( 'name', 'compare_val' );
        ###l4p $logger->debug('PROCATTR NODE: '. $prepend->dump_node());

        $left->{type} = 'var';
        $left->{val}  = 'compare_val';
        delete $left->{op};
        
        $right->{type} = 'val';
        $right->{op}   = operator( $node->tagName );

        # $right->{val}  = '$compare_val'; # $ for variable interpolation
        ##l4p $logger->debug('PROCATTR attr_sets: ', l4mtdump(@attr_sets));

        # return __PACKAGE__->report_skipped($node, 'Skipping node. '.$node->tagName
        #                     .' used two scalar values (no tag/variable)');


        my $inserted = $tmpl->insertBefore( $prepend, $node );
        ###l4p $logger->debug('PROCATTR PREPEND: '. $prepend->dump_node());

    }


    # From combination chart above
    #   tag tag      Prepend node + setvar, turns into "tag var"!
    if (    $left->{type} eq 'tag'
        and $right->{type} eq 'tag' ) {
        my $tok  = $right->{token};
        my $tag  = $tok->tagName;
        # We have to add a setvar assignment node for the 'b' case.
        my $prepend_attr = { setvar => 'tag_mt'.lc($tag) };
        my $prepend = $tmpl->createElement( lc($tag), $prepend_attr );
        my $inserted = $tmpl->insertBefore( $prepend, $node );
        $prepend->setAttribute('setvar', 'tag_mt'.lc($tag));
        # The b attributes becomes an interpolated template variable
        # set by the setvar attribute of the prepended node above
        $right->{type} = 'val';
        $right->{op}   = operator( $node->tagName );
        $right->{val}  = '$tag_mt'.lc($tag); # $ for variable interpolation
    }
    
}

sub invalid_attributes {
    my $node = shift;
    my @attr_keys = map { $_->[0] }  @{ $node->[4] };
    my $tag = $node->tagName;
    my $SKIPPING = "Skipping $tag node";
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
            } @attr_keys ) {

        return __PACKAGE__->report_skipped({
            nodes   => $node,
            message => "$SKIPPING due to $1 attribute"
        });
    }

    if ( @attr_keys != 2 ) {
        my $qual = @attr_keys > 2 ? 'Too many' : 'Not enough';
        return __PACKAGE__->report_skipped({ 
            nodes   => $node,
            message => "$SKIPPING. $qual attributes." 
        });
    }
    return undef;
}


sub parse_attr_value {
    my ($node, $str, $op) = @_;
    my $attr_set;
    
    # Attribute values like the following are either TAG values or VAR
    # (variable) values:
    #                       a="[MTGetVar name='what']"
    #                    or a="[MTFoo format='1' iso='1']"
    # 
    if ( $str =~ m{
            ^\[                 # Starts with a [
                \s*             # Possible spaces
                (               #
                    MT          # The MT tag
                    .*?         # and its attributes
                )               #
                \s*             # Optional spaces
            \]$                 # Ends with a ]
        }smxi ) {
        
        # Compile the template code as if it were a tag
        my $upgrader  = TemplateUpgrader->new();
        my $tok = $upgrader->compile_markup( '<'.$1.'>' );
        if ( ! defined $tok ) {
            return __PACKAGE__->report_skipped(
                $node, 
                'Skipping tag due to compilation error'
            );
        }

        ##l4p $logger->debug($node->tagName .' PARSED ATTRIBUTE: ',
        ##l4p      l4mtdump({
        ##l4p          attr     => $attr,
        ##l4p          attr_val => $str,
        ##l4p          tok      => $tok,
        ##l4p      }));

        
        $tok = shift @$tok; # There's only one token in the array
        $attr_set = {
            type  => ( lc($tok->tagName) eq 'getvar' ) ? 'var' : 'tag',
            token => $tok
        };
    }
    # Normal scalar attribute values, e.g. b="John"
    else {
        $attr_set = { 
            type => 'val',
            op   => $op,
            val  => $str
        };
    }

    return $attr_set;
}


1;