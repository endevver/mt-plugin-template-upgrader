package TemplateUpgrader::Template;
use strict; use warnings; use Carp; use Data::Dumper;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

use base qw( MT::Template );
use MT::Util qw( weaken );

use TemplateUpgrader::Builder;
use Hook::LexWrap;

wrap *MT::Template::new, post => \&rebless;

sub rebless { 
    my $self = shift;
    ref $self or $self = shift;
    bless $self, __PACKAGE__;
    return $self;
    # return $self->isa( __PACKAGE__ ) ? $self
    #      : bless $self, __PACKAGE__;
}

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

sub rescan {
    my $tmpl = shift;
    die unless $tmpl->isa(__PACKAGE__);
    my ($tokens) = @_;
    unless ($tokens) {
        # top of tree; reset
        $tmpl->{__ids} = {};
        $tmpl->{__classes} = {};
        # Use tokens if we already have them, otherwise compile
        $tokens = $tmpl->{__tokens} || $tmpl->compile;
    }
    return unless $tokens;
    foreach my $t (@$tokens) {
        if ($t->[0] ne 'TEXT') {
            if ($t->[1]->{id}) {
                my $ids = $tmpl->{__ids} ||= {};
                $ids->{lc $t->[1]->{id}} = $t;
            }
            elsif ($t->[1]->{class}) {
                my $classes = $tmpl->{__classes} ||= {};
                push @{ $classes->{lc $t->[1]->{class}} ||= [] }, $t;
            }
            $tmpl->rescan($t->[2]) if $t->[2];
        }
    }
}

sub compile {
    my $tmpl = shift;
    die unless $tmpl->isa(__PACKAGE__);
    my $b = MT->model('templateupgrader_builder')->new();
    $b->compile($tmpl) or return $tmpl->error($b->errstr);
    return $tmpl->{__tokens};
}

sub tokens {
    my $tmpl = shift;
    die unless $tmpl->isa(__PACKAGE__);
    if (@_) {
        return bless $tmpl->{__tokens} = shift, 'MT::Template::Tokens';
    }
    my $t = $tmpl->{__tokens} || $tmpl->compile;
    return bless $t, 'MT::Template::Tokens' if $t;
    return undef;
}

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
            $token = $builder->order_attributes( $tmpl->context, $token );
            my $tag = $token->[0];
            $str .= '<mt:' . $tag;
            if (my $attrs = $token->[4]) {
                my $attrh = $token->[1];
                my @attr_order = split(',', delete $attrh->{_attr_order} || '');
                ### DOC: For every ordered attribute
                foreach my $a (@$attrs) {
                    ### DOC: Delete it from the attribute hash
                    delete $attrh->{$a->[0]};
                    my $v = $a->[1];
                    ### DOC: Properly quote the value based on existing quotes
                    $v = $v =~ m/"/ ? qq{'$v'} : qq{"$v"};
                    ### DOC: Assemble the attribute/value string and append
                    $str .= ' ' . $a->[0] . '=' . $v;
                    ### DOC: Remove from the @attr_order array
                    @attr_order = grep { $_ ne $a->[0] } @attr_order;
                }
                foreach my $a (@attr_order) {
                    ### DOC: Delete it from the attribute hash
                    my $v = delete $attrh->{$a};
                    next unless defined $v;
                    ### DOC: Properly quote the value based on existing quotes
                    $v = $v =~ m/"/ ? qq{'$v'} : qq{"$v"};
                    ### DOC: Assemble the attribute/value string and append
                    $str .= ' ' . $a . '=' . $v;
                }
                ### DOC: Then iterate over the keys of the attribute hash
                foreach my $a (keys %$attrh) {
                    my $v = $attrh->{$a};
                    ### DOC: Properly quote the value based on existing quotes
                    $v = $v =~ m/"/ ? qq{'$v'} : qq{"$v"};
                    ### DOC: Assemble the attribute/value string and append
                    $str .= ' ' . $a . '=' . $v;
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
    die unless $tmpl->isa(__PACKAGE__);
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

use base qw( MT::Template::Node );

sub NODE_TEXT ()     { 1 }
sub NODE_BLOCK ()    { 2 }
sub NODE_FUNCTION () { 3 }

sub dump_node {
    my $node     = shift;
    my @elements = @_ || ( 0..4 );
    return Dumper( @{$node}[@elements] );
}

sub nodeType {
    my $node = shift;
    die unless $node->isa(__PACKAGE__);
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
    die unless $node->isa(__PACKAGE__);
    return unless ref($node) 
              and $node->isa('MT::Template::Node')
              and $node->nodeType != MT::Template::NODE_TEXT();
    if ( @_ ) {
        $node->[0] = shift;
        $node->[0] = $node->nodeName(); # For normalization
    }
    return $node->[0];
}

sub setAttribute {
    my $node = shift;
    die unless $node->isa(__PACKAGE__);
    my ($attr, $val) = @_;
    $node->SUPER::setAttribute( $attr, $val );
    my %seen;
    my @order = split(',', $node->[1]{_attr_order} || '');
    $node->[1]{_attr_order}
        = join(',',  grep { $_ ne '_attr_order' and ! $seen{$_}++ }
                @order, $attr );
}

sub removeAttribute {
    my ($node, $attr) = @_;
    die unless $node->isa(__PACKAGE__);
    $node->[4] = [ grep { $_->[0] ne $attr } @{ $node->[4] } ];
    my @order = split(',', $node->[1]{_attr_order} || '');
    $node->[1]{_attr_order}
        = join(',',  grep { $_ ne $attr and $_ ne '_attr_order' } @order );
    delete $node->[1]{$attr};
}

sub appendAttribute {
    my $node = shift;
    my ($attr, $val) = @_;
    die unless $node->isa(__PACKAGE__);
    $node->setAttribute( $attr, $val );
    push @{ $node->[4] }, [ $attr, $val ];
}

sub prependAttribute {
    my $node = shift;
    my ($attr, $val) = @_;
    die unless $node->isa(__PACKAGE__);
    $node->setAttribute( $attr, $val );
    unshift @{ $node->[4] }, [ $attr, $val ];
    my %seen;
    my @order = split(',', $node->[1]{_attr_order} || '');
    $node->[1]{_attr_order}
        = join(',',  grep { $_ ne '_attr_order' and ! $seen{$_}++ }
                $attr, @order );
}

sub renameAttribute {
    my ($node, $old, $new) = @_;
    die unless $node->isa(__PACKAGE__);
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    if ( exists $node->[1]{$new} ) {
        $logger->error(
             'Renaming of %s attribute (value: %s) to %s failed due '
            .'to existing target attribute (value: %s)'
        );
        return;
    }
    $node->setAttribute( $new, $node->removeAttribute( $old ) );
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
