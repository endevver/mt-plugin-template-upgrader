package TemplateUpgrader;

use strict; use warnings; use Carp; use Data::Dumper;
use base qw(Class::Accessor::Fast);

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

sub new {
    my $class = shift;
    $class->mk_accessors(qw( handlers ));
    my $self = $class->SUPER::new( @_ );
    $self->init() if @_;
    $self;
}

sub init {
    my $self = shift;
    
}

# sub add_handler {
#     my $self = shift;
#     my ( $tag, $handler ) = @_;
#     my $handlers = $self->handlers;
#     push @$handlers, { $tag => $handler };
#     $self->handlers( $handlers );
# }

sub upgrade {
    my $self                  = shift;
    my ( $tmpl, $handlers )   = @_;
    $handlers               ||= $self->handlers || {};
    #l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    my $text_only = ! ref $tmpl;
    if ( $text_only ) {
        my $tmpl_obj = MT->model('template')->new();
        $tmpl_obj->text( ref $tmpl ? $$tmpl : $tmpl );
        $tmpl = $tmpl_obj;
    }

    # $logger->debug('$handlers: ', l4mtdump($handlers));
    # $logger->debug('$tmpl->tokens: ', l4mtdump($tmpl->tokens));

    while ( my ( $tag, $code ) = each %$handlers ) {
        $code = MT->handler_to_coderef($code); 
        # $logger->debug('Handling tag: '.$tag);
        my $nodes = $tmpl->getElementsByTagName( lc($tag) ) || [];
        $code->($_) foreach @$nodes;
    }

    $tmpl->reset_markers;
    $tmpl->{reflow_flag} = 1;
    $tmpl->text( $self->reflow( $tmpl ) || '' );

    return $text_only ? $tmpl->text : $tmpl;
}

sub compile_markup {
    my $self    = shift;
    my $markup  = shift;
    my $builder = MT::Builder->new();
    my $ctx     = MT::Template::Context->new;
    $ctx->stash('builder', $builder);
    my $tokens = $builder->compile($ctx, $markup);
    $logger->error('# -- error compiling: ' . $b->errstr)
        unless defined $tokens;
    return $tokens;
}

sub reflow {
    my $self = shift;
    my $tmpl = shift;
    my ($tokens) = @_;
    $tokens ||= $tmpl->tokens;

    # reconstitute text of template based on tokens
    my $str = '';
    foreach my $token (@$tokens) {
        if ($token->[0] eq 'TEXT') {
            $str .= $token->[1];
        } else {
            my $tag = $token->[0];
            $str .= '<mt:' . $tag;
            if (my $attrs = $token->[4]) {
                my $attrh = $token->[1];
                foreach my $a (@$attrs) {
                    delete $attrh->{$a->[0]};
                    my $v = $a->[1];
                    $v = $v =~ m/"/ ? qq{'$v'} : qq{"$v"};
                    $str .= ' ' . $a->[0] . '=' . $v;
                }
                foreach my $a (keys %$attrh) {
                    my $v = $attrh->{$a};
                    $v = $v =~ m/"/ ? qq{'$v'} : qq{"$v"};
                    $str .= ' ' . $a . '=' . $v;
                }
            }
            $str .= '>';
            if ($token->[2]) {
                # container tag
                $str .= $self->reflow( $tmpl, $token->[2] );
                # $str .= $tmpl->reflow( $token->[2] );
                $str .= '</mt:' . $tag . '>';
            }
        }
    }
    return $str;
}


1;

package MT::Template;

sub save_backup {
    my $tmpl = shift;
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
          $backup->name 
        . MT->instance->translate( ' (TemplateUpgrader backup from [_1]) [_2]', 
                            $ts, $tmpl->type )
    );
    $backup->outfile('');
    $backup->linked_file( undef );
    $backup->identifier(undef);
    $backup->rebuild_me(0);
    $backup->build_dynamic(0);
    $backup->save;
}

package MT::Template::Node;

sub NODE_TEXT ()     { return MT::Template::NODE_TEXT()     }
sub NODE_BLOCK ()    { return MT::Template::NODE_BLOCK()    }
sub NODE_FUNCTION () { return MT::Template::NODE_FUNCTION() }

sub tagName {
    my $node = shift;
    return undef if ref($node) ne 'MT::Template::Node'
                 or $node->nodeType == MT::Template::NODE_TEXT();
    if ( @_ ) {
        $node->[0] = shift;
        $node->[0] = $node->nodeName(); # For normalization
    }
    return $node->[0];
}

sub removeAttribute {
    my ($node, $attr) = @_;
    delete $node->[1]{$attr};
}

sub appendAttribute {
    
}

sub prependAttribute {
    
}

sub renameAttribute {
    my ($node, $old, $new) = @_;
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