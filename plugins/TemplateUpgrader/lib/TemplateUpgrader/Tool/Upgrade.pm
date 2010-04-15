package TemplateUpgrader::Tool::Upgrade;
use strict; use warnings; use Carp; use Data::Dumper;

use Getopt::Long qw( :config auto_version auto_help );
use Pod::Usage;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

use vars qw( $VERSION @ISA $timer );
$VERSION = '0.1';

# Structure of a node:
#   [0] = tag name
#   [1] = attribute hashref
#   [2] = contained tokens
#   [3] = template text
#   [4] = attributes arrayref
#   [5] = parent array reference
#   [6] = containing template

use base qw( MT::App::CLI );

$| = 1;

sub usage { '( --blog BLOG | --template TEMPLATE ) [ --debug ]' }

sub option_spec {
    return (
        'blog|b=s', 'template|tmpl|t=s', 'debug|d',
        $_[0]->SUPER::option_spec()
    );
}

sub help {
    return q{
        This is a template upgrading script
    };
}

sub mode_default {
    my $app      = shift;
    my $blog     = $app->param('blog');
    my $template = $app->param('template');
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    require MT::Util::ReqTimer;
    $timer = MT::Util::ReqTimer->new( join('-', __PACKAGE__, $$) );

    if ( ! defined $blog && ! $template ) {
        $app->show_usage(
            'Error: Either --blog or --template parameter is required.' );
    }

    my $tmpl_iter;

    # Load the blog if blog parameter is given
    if ( defined $blog ) {
        $blog = $app->load_by_name_or_id('blog', $blog, 1);
        
    }

    # If no template parameter is given, we 
    # iterate through all of the blog templates
    if ( ! defined $template ) {
        $tmpl_iter = MT->model('template')->load_iter({
            blog_id => $blog->id
        }) unless defined $template;
    }
    # If the template parameter looks like an ID, we try to load it
    elsif ( $template =~ m{^[0-9]+$} ) { 
        $template   = $app->load_by_name_or_id('template', $template, 1);
        $blog     ||= $template->blog;
        # Check that template blog ID matches the blog ID
        # If not, reset $template to the original parameter value
        if ( $blog->id != $template->blog->id ) {
            $template = $app->param('template');
        }
        else {
            my @templates = ( $template );
            require Data::ObjectDriver::Iterator;
            $tmpl_iter = Data::ObjectDriver::Iterator->new( sub { shift ( @templates ) } );
        }
    }

    # If given an template parameter that is still not loaded,
    # load it using the blog terms.
    if ( ! $tmpl_iter ) {
        $blog or $app->show_usage(
                     'Error: If you only specify a template parameter, '
                    .'it must be a valid template ID.'
                );

        my %blog_terms = ( blog_id => $blog->id );
        $tmpl_iter = MT->model('template')->load_iter([
            {
                id         => $template, %blog_terms
            }
                => -or =>
            {
                identifier => $template, %blog_terms
            }
                => -or =>
            {
                name       => $template, %blog_terms
            }
        ]);
    }

    while ( my $tmpl = $tmpl_iter->() ) {
        $app->upgrade_template( $tmpl );
    }

    return "Upgrade completed in ".$timer->total_elapsed." seconds.\n";
}

sub upgrade_template {
    my ( $self, $tmpl ) = @_;
    # my $ctx           = $tmpl->context();
    my $app             = MT->instance;
    my $orig            = $tmpl->text || '';
    my $handlers        = $app->registry('tag_upgrade_handlers') || {};
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    while ( my ( $tag, $code ) = each %$handlers ) {
        $code     = $app->handler_to_coderef($code) unless ref($code) eq 'CODE';
        my $nodes = $tmpl->getElementsByTagName( lc($tag) ) || [];
        $code->($_) foreach @$nodes;
    }

    $tmpl->reset_markers;
    $tmpl->{reflow_flag} = 1;
    my $new = reflow($tmpl) || '';
    
    if ( $new eq $orig ) {
        printf "%s template \"%s\" (ID:%s) not modified.\n",
            ucfirst($tmpl->type), $tmpl->name, $tmpl->id;
        return 0;
    }

    ###l4p if ( $logger->is_debug() ) {
    ###l4p      $logger->debug('Template "'.$tmpl->name.'" $orig template: ', $orig);
    ###l4p      $logger->debug('Template "'.$tmpl->name.'" $new template: ', $new);
    ###l4p      require HTML::Diff;
    ###l4p      import HTML::Diff qw(html_word_diff);
    ###l4p      $logger->debug(
    ###l4p          'Template diff for '.$tmpl->name.' (ID:'.$tmpl->id.'): ',
    ###l4p          l4mtdump(html_word_diff($orig, $new))
    ###l4p      );
    ###l4p }

    if ( $app->param('debug') ) {
        printf "%s\n%s TEMPLATE \"%s\" (ID:%d)\n",
            ('='x50), ucfirst($tmpl->type), $tmpl->name, $tmpl->id;
        printf "ORIGINAL template: %s\n", $orig;
        printf "NEW template: %s\n", $new;
        require HTML::Diff;
        import HTML::Diff qw(html_word_diff);
        printf "TEMPLATE DIFF:\n%s\n",
            Dumper(html_word_diff($orig, $new));
    }
    else {
        $tmpl->save_backup();

        $tmpl->text( $new );
        $tmpl->save;

        printf "%s template \"%s\" (ID:%s) upgraded.\n",
            ucfirst($tmpl->type), $tmpl->name, $tmpl->id;
    }

    return 1;
}

sub reflow {
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
                $str .= reflow( $tmpl, $token->[2] );
                # $str .= $tmpl->reflow( $token->[2] );
                $str .= '</mt:' . $tag . '>';
            }
        }
    }
    return $str;
}

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

sub appendAttribute {
    
}

sub prependAttribute {
    
}

1;