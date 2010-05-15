package TemplateUpgrader::Template;
use strict; use warnings; use Carp; use Data::Dumper;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

use base qw( MT::Template );
use MT::Util qw( weaken );

use TemplateUpgrader::Builder;
use Hook::LexWrap;
use Scalar::Util qw( blessed );
use List::Util qw( first );
wrap *MT::Template::new, post => \&rebless;

sub rebless { 
    # print STDERR "REBLESS ARG: $_\n" foreach @_;
    my $self = first { defined and blessed $_ } @_;
    # print STDERR "REBLESS SELF: $self\n";
    # print STDERR "----------------------------\n";
    bless $self, __PACKAGE__;
    return $self;
}

# END {
#     use Devel::Symdump;
#     $Devel::Symdump::MAX_RECURSION = 10;
#     my @packs = qw( MT::Template MT::Template::Node TemplateUpgrader::Template TemplateUpgrader::Template::Node );
#     my $obj = Devel::Symdump->new(@packs);        # no recursion
#     # my $obj = Devel::Symdump->rnew(@packs);       # with recursion
#     print STDERR join("\n", $obj->functions);
# }

sub NODE () { 'TemplateUpgrader::Template::Node' }
sub NODE_TEXT ()     { 1 }
sub NODE_BLOCK ()    { 2 }
sub NODE_FUNCTION () { 3 }

sub save_backup {
    my $tmpl = shift;
    die unless $tmpl->isa(__PACKAGE__);
    my $blog = $tmpl->blog;
    my $t = time;
    my @ts = MT::Util::offset_time_list( $t, ( $blog ? $blog->id : undef ) );
    my $ts = sprintf "%04d-%02d-%02d %02d:%02d:%02d", $ts[5] + 1900,
      $ts[4] + 1, @ts[ 3, 2, 1, 0 ];
    my $backup = $tmpl->clone;
    delete $backup->{column_values}->{id}; # make sure we don't overwrite original
    delete $backup->{changed_cols}->{id};
    $backup->type('backup');
    $backup->name(
          sprintf("%s (TemplateUpgrader backup of ID %s) %s %s",
                $backup->name,
                $tmpl->id,
                $tmpl->type,
                $ts
          )
    );
    $backup->outfile('');
    $backup->linked_file( undef );
    $backup->identifier(undef);
    $backup->rebuild_me(0);
    $backup->build_dynamic(0);
    $backup->meta('original_template', $tmpl->id);
    $backup->save
        or die sprintf   'Could not save backup template "%s" '
                        .'(Blog: %s, Template: %s): %s',
                        $tmpl->name, $blog->id, $tmpl->id, $backup->errstr;
    return $backup;
}

# sub compile {
#     my $tmpl = shift;
#     die unless $tmpl->isa(__PACKAGE__);
#     my $b = MT->model('templateupgrader_builder')->new();
#     $b->compile($tmpl) or return $tmpl->error($b->errstr);
#     return $tmpl->{__tokens};
# }

# sub tokens {
#     my $tmpl = shift;
#     die unless $tmpl->isa(__PACKAGE__);
#     if (@_) {
#         return bless $tmpl->{__tokens} = shift, 'MT::Template::Tokens';
#     }
#     my $t = $tmpl->{__tokens} || $tmpl->compile;
#     return bless $t, 'MT::Template::Tokens' if $t;
#     return undef;
# }

sub reflow {
    my $tmpl       = shift;
    my ($tokens)   = @_;
    $tokens      ||= $tmpl->tokens;
    my $builder    = MT->model('templateupgrader_builder')->new();
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    die "Found a ".ref($tmpl) unless $tmpl->isa('TemplateUpgrader::Template');

    # reconstitute text of template based on tokens
    my $str = '';
    foreach my $token (@$tokens) {
        if ($token->[0] eq 'TEXT') {
            $str .= $token->[1];
        } else {
            my $tag = $token->[0];
            $str .= '<mt:' . $tag;
            if (my $attrs = $token->[4]) {
                foreach my $a (@$attrs) {
                    if ( ! defined $a->[1] ) {
                        $logger->warn(
                            'Found an uninitialized attribute value for '
                            .$a->[0].': '
                            .$token->dump_node()
                        );
                        $a->[1] = '';
                    }
                    ### DOC: Delete it from the attribute hash
                    my $v = $a->[1];
                    ### DOC: Properly quote the value based on existing quotes
                    $v = $v =~ m/"/ ? qq{'$v'} : qq{"$v"};
                    ### DOC: Assemble the attribute/value string and append
                    $str .= ' ' . $a->[0] . '=' . $v;
                    ### DOC: Remove from the @attr_order array
                }
            }
            $str .= '>';
            if ($token->[2]) {
                # container tag
                $str .= $tmpl->reflow( $token->[2] );
                $str .= '</mt:' . $tag . '>';# unless $tag eq 'else';
            }
        }
    }
    return $str;
}

sub innerHTML {
    my $node = shift;
    if (@_) {
        my ($text) = @_;
        $node->[3] = $text;
        my $builder = MT->model('templateupgrader_builder')->new();
        my $ctx = MT::Template::Context->new;
        $node->[2] = $builder->compile($ctx, $text);
        my $tmpl = $node->ownerDocument;
        if ($tmpl) {
            $tmpl->reset_markers;
            $tmpl->{reflow_flag} = 1;
        }
    }
    return $node->[3];
}

sub getElementById {
    my $tmpl = shift;
    my ($id) = @_;
    if (my $node = $tmpl->token_ids->{$id}) {
        return bless $node, NODE;
    }
    undef;
}

sub createElement {
    my $tmpl = shift;
    die unless $tmpl->isa(__PACKAGE__);
    my ($tag, $attr) = @_;
    my $node = bless [ $tag, $attr, undef, undef, undef, undef, $tmpl ], NODE;
    weaken($node->[6]);
    return $node;
}

sub createTextNode {
    my $tmpl = shift;
    die unless $tmpl->isa(__PACKAGE__);
    my ($text) = @_;
    my $node = bless [ 'TEXT', $text, undef, undef, undef, undef, $tmpl ], NODE;
    weaken($node->[6]);
    return $node;
}


1;

package TemplateUpgrader::Template::Node;
use strict; use warnings; use Carp; use Data::Dumper;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

use base qw( MT::Template::Node );

sub NODE_TEXT ()     { 1 }
sub NODE_BLOCK ()    { 2 }
sub NODE_FUNCTION () { 3 }

sub dump_node {
    my $node     = shift;
    my @elements = @_ || ( 0..4 );
    return Dumper([ @{$node}[@elements] ]);
}

sub nodeType {
    my $node = shift;
    if ($node->[0] eq 'TEXT') {
        return $node->NODE_TEXT();
    } elsif (defined $node->[2]) {
        return $node->NODE_BLOCK();
    } else {
        return $node->NODE_FUNCTION();
    }
}

sub tagName {
    my $node = shift;
    return unless ref($node) 
              and $node->isa('MT::Template::Node')
              and $node->nodeType != MT::Template::NODE_TEXT();
    if ( @_ ) {
        $node->[0] = shift;
        $node->[0] = $node->nodeName(); # For normalization
    }
    return $node->[0];
}

sub getAttribute {
    my $node = shift;
    my ($attr) = @_;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    my @attr = grep { $_->[0] eq $attr } @{ $node->[4] || [] };
    return unless @attr;
    return ( @attr == 1  ? (shift @attr)->[1]
           : wantarray   ? ( map { $_->[1] } @attr )
                         : [ map { $_->[1] } @attr ]        );
}

sub setAttribute {
    my $node = shift;
    my ($attr, $val) = @_;
    $node->SUPER::setAttribute( $attr, $val );
    my $found;
    foreach my $kv ( @{ $node->[4] } ) {
        next unless $kv->[0] eq $attr;
        $kv->[1] = $val;
        $found++ and last;
    }
    push( @{ $node->[4] }, [ $attr, $val ] )
        unless $found;
    return $node;
}

sub removeAttribute {
    my ($node, @attr) = @_;
    my %unwanted;
    @unwanted{@attr} = (1..@attr);  # Hash acting as a binary lookup table
    $node->[4] = [ grep { ! $unwanted{ $_ } } @{ $node->[4] } ];
    delete $node->[1]{@attr};
    return $node;
}

sub attributes {
    my $node = shift;
    return wantarray ?  @{ $node->[4] } : $node->[4];
}

sub attributeKeys {
    my $node = shift;
    my @attrs = map { $_->[0] } @{ $node->[4] };
    return wantarray ?  @attrs : [ @attrs ];
}

sub attributeValues {
    my $node = shift;
    my @attrs = map { $_->[1] } @{ $node->[4] };
    return wantarray ?  @attrs : [ @attrs ];
}

sub appendAttribute {
    my $node = shift;
    my (%param) = @_;
    while ( my ($attr, $val) = each %params ) {
        push @{ $node->[4] }, [ $attr, $val ];
        $node->setAttribute( $attr, $val );
    }
    return $node;
}

sub prependAttribute {
    my $node = shift;
    my ($attr, $val) = @_;
    unshift @{ $node->[4] }, [ $attr, $val ];
    # $node->setAttribute( $attr, $val );
    return $node;
}

sub renameAttribute {
    my ($node, $old, $new, $force) = @_;
    $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    if ( exists $node->[1]{$new} and ! $force ) {
        $logger->error(
            sprintf
             'Renaming of %s attribute (value: %s) to %s failed due '
            .'to existing target attribute (value: %s). You can override '
            .'this protection by calling renameAttribute with a third '
            .'argument which evaluates to boolean TRUE.',
            $old, $node->[1]{$old}, $new, $node->[1]{$new}
        );
        return;
    }
    $node->[1]{$new} = delete $node->[1]{$old};

    foreach my $kv ( @{ $node->[4] } ) {
        next unless $kv->[0] eq $old;
        $kv->[0] = $new;
        last;
    }
    return $node;
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



=head1 NAME

TemplateUpgrader::Template - A subclass of MT::Template for TemplateUpgrader

=head1 METHODS

=over 4

=item * $tmpl->reflow( \@tokens || $tmpl->tokens )
    
    Reconstitute text of template based on tokens
    Iterates over given/loaded tokens doing the following
        Text nodes:  Append to string
        All others:  Create the MT tag
                        If attribute arrayref ($token->[4]) exists
                           Iterate over attribute array
                               Delete key from the attribute hash
                               Appending key/val
                           Iterate over remaining attribute hash keys
                               Appending key/val
                      For container tags:
                           Reflow the inner contents $node->[2]
                           Create the closing tag

=item * $tmpl->text

=item * $tmpl->text( $text )

    $tmpl->text() WITH $tmpl->{reflow_flag} set
        $tmpl->reflow
        Saving output template text to the text column
        $tmpl->reset_tokens;
        Returns $text

    $tmpl->text( $text ) WITHOUT $tmpl->{reflow_flag} set
        Save provided template text to the text column
        Return text

    $tmpl->text() WITHOUT $tmpl->{reflow_flag} set
        Retrieves text (using MT::Object method)
        $tmpl->reset_tokens;
        returns $text


=item *  $tmpl->compile

        Calls $builder->compile($tmpl)
        Returns $tmpl->{__tokens}

=item *  $tmpl->reset_tokens()

    Undefines the tokens

=item * $tmpl->tokens

=item * $tmpl->tokens( @tokens )

    Returns $tmpl->{__tokens} if set
    Or a freshly compiled set of tokens from $tmpl->compile

    $tmpl->tokens( @tokens)
        Sets internal $tmpl->{__tokens} 

=item *  $tmpl->insertAfter( $node1, ( $node2 || $tmpl ) )

    Insert $node1 after $node2

=item *  $tmpl->insertBefore( $node1, ( $node2 || $tmpl ) )

    Insert $node1 before $node2

=item * $tmpl->appendChild

    Appends submitted node to the template's array of child nodes
    Sets $tmpl->{reflow_flag}

=back

=head1 TemplateUpgrader::Template METHODS

=over 4

=item * $node->setAttribute(key, val)

    ONLY sets the attr hash ($node->[1])

=item * $node->getAttribute(key, val)

    ONLY gets the attr hash ($node->[1])

=item * $node->nodeValue

    For text nodes, returns text
    For container tags returns inner nodes
    For all else undef

=item * $node->innerHTML()

=item * $node->innerHTML( $text )

    ALWAYS returns $node->[3]
    If given an extra parameter ($text?)
        It stuffs it into $node->[3]
        Compiles it and stuffs it into $node->[2]
        Sets $tmpl->{reflow_flag} = 1;

=item * $node->appendChild( $new_node )

    Appends submitted node to its array of child nodes
    Sets $tmpl->{reflow_flag}

=cut


