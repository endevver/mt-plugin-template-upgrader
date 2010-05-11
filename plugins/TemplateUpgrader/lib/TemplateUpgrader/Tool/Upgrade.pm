package TemplateUpgrader::Tool::Upgrade;
use strict; use warnings; use Carp; use Data::Dumper;

use Getopt::Long qw( :config auto_version auto_help );
use Pod::Usage;

$| = 1;
use vars qw( $VERSION @ISA $timer );
$VERSION = '0.1';

use base qw( MT::App::CLI );
our $handlers;
our @BUNDLED_TAG_PLUGINS = qw(
    Community.pack
    Commercial.pack
    ActionStreams
    CommunityActionStreams
    FacebookCommenters/plugin.pl
    Markdown/Markdown.pl
    Markdown/SmartyPants.pl
    MultiBlog/multiblog.pl
    Textile/textile2.pl
    TypePadAntiSpam/TypePadAntiSpam.pl
);

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

use TemplateUpgrader;

sub usage {
    'upgrade [options] [--blog KEY] '
        .'[( --file PATH || --template KEY || --stdin )]'
}

sub option_spec {
    return (
        'blog|b=s', 'template|tmpl|t=s', 'file|f=s', 'stdin|s',
        'analyze|a', 'upgrade|u', 'debug|d',
        $_[0]->SUPER::option_spec()
    );
}

sub help {
    return q{
        This is a template upgrading script
    };
}

sub tags_from_plugin {
    my ($app, $plugin) = @_;
    my $tags   = $plugin->registry('tags') || {};
    my @tags;
    foreach my $type ( qw( function block ) ) {
        next unless $tags->{$type};
        push @tags, grep { $_ ne 'plugin'} # Skip plugin and
                    map {                  # Remove
                        s{\?$}{};          #  conditional 
                        $_                 #   marker
                    }
                    keys %{ $tags->{$type} };
    }
    return @tags;
}

sub initialize_default_handler {
    my $app = shift;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    # my $plugin   = MT->component('TemplateUpgrader');
    $handlers = $app->registry('tag_upgrade_handlers') || {};

    my %plugin_tags;
    PLUGIN: foreach my $sig ( keys %MT::Plugins ) {
        next PLUGIN if grep { $_ eq $sig } @BUNDLED_TAG_PLUGINS;
        my $plugin = $MT::Plugins{$sig}{object} or next PLUGIN;
        my @tags   = $app->tags_from_plugin( $plugin ) or next PLUGIN;
        push @{ $plugin_tags{$sig} }, @tags;
        TAG: foreach my $tag ( @tags ) {
            next TAG if $handlers->{$tag} and ! $app->param('analyze');
            require TemplateUpgrader::Handlers;
            $handlers->{$tag} = sub {
                TemplateUpgrader::Handlers->default_hdlr(
                        @_, { plugin => $sig } );
            };
        }
    }
    $app->registry('tag_upgrade_handlers', $handlers);
    $app->request('tag_upgrade_plugin_tags', \%plugin_tags );
    ###l4p if ( $logger->is_debug() ) {
    ###l4p     $logger->debug("Tags: ", l4mtdump(\%plugin_tags));
    ###l4p     $logger->debug('$handlers: ', l4mtdump($handlers));
    ###l4p }
}

sub init_options {
    my $app = shift;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    $app->SUPER::init_options( @_ );
    my $options = $app->options();

    my $exclusive = grep { $options->{$_} } qw( template file stdin );
    if ( $exclusive > 1 ) {
        $app->show_usage({
            -exitval => 2,
            -verbose => 0,
            -message => 'Error: The --template, --file and --stdin '
                        .'options cannot be used together.'
        });
    }
    
    $app->show_usage() unless $exclusive || defined $options->{blog};

    $options->{file} = '-' if $options->{stdin};

    if ( my $file = $options->{file} ) {
        require MT::FileMgr;
        my $fmgr = MT::FileMgr->new('Local');
        my $text = $fmgr->get_data( $file ) || '';
        if ( $text eq '' ) {
            $app->show_usage({
                -exitval => 2,
                -verbose => 0,
                -message => 'Error: No template data found.'
            });
        }
        my $tmpl = MT->model('template')->new();
        $tmpl->name( 'Unnamed template from '
                    . ($options->{stdin} ? 'STDIN' : $file));
        $tmpl->text( $text );
        $options->{template} = $tmpl;
    }
    $options;
}

sub mode_default {
    my $app      = shift;
    my $blog     = $app->param('blog');
    my $template = $app->param('template');
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    $app->initialize_default_handler();

    require MT::Util::ReqTimer;
    $timer = MT::Util::ReqTimer->new( join('-', __PACKAGE__, $$) );

    my $tmpl_iter;

    # Load the blog if blog parameter is given
    if ( defined $blog and ! ref $blog) {
        $blog = $app->load_by_name_or_id('blog', $blog, 1);
    }

    # If no template parameter is given, we 
    # iterate through all of the blog templates
    if ( ! defined $template ) {
        $tmpl_iter = MT->model('template')->load_iter({
            blog_id => $blog->id
        });
    }
    # If the template parameter looks like a template object
    elsif ( ref $template and $template->isa( MT->model('template') ) ) { 
        my @templates = ( $template );
        require Data::ObjectDriver::Iterator;
        $tmpl_iter = Data::ObjectDriver::Iterator->new(
                        sub { shift ( @templates ) } );
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
            $tmpl_iter = Data::ObjectDriver::Iterator->new(
                            sub { shift ( @templates ) } );
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

    my $text;
    while ( my $tmpl = $tmpl_iter->() ) {
        $app->upgrade_template( $tmpl );
    }

    return "Upgrade completed in ".$timer->total_elapsed." seconds.\n";
}

sub upgrade_template {
    my $app     = shift;
    my $tmpl    = shift;
    my $orig    = $tmpl->text || '';
    $handlers ||= $app->registry('tag_upgrade_handlers') || {};
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    my $upgrader = TemplateUpgrader->new({ handlers => $handlers });
    $tmpl        = $upgrader->upgrade( $tmpl );

    my $new = $tmpl->text || '';

    if ( $new eq $orig ) {
        my $msg = sprintf('%-10d %-10s Template not modified: %s/%s',
                    $app->blog->id, $tmpl->id, ucfirst($tmpl->type), $tmpl->name );
        print $msg."\n" and $logger->info( $msg );
        return 0;
    }

    ###l4p if ( $app->param('debug') && $logger->is_debug() ) {
    ###l4p      $logger->debug('Template "'.$tmpl->name.'" $orig template: ', $orig);
    ###l4p      $logger->debug('Template "'.$tmpl->name.'" $new template: ', $new);
    ###l4p      require HTML::Diff;
    ###l4p      import HTML::Diff qw(html_word_diff);
    ###l4p      $logger->debug(
    ###l4p          'Template diff for '.$tmpl->name.' (ID:'.($tmpl->id||0).'): ',
    ###l4p          l4mtdump(html_word_diff( $orig, $new ))
    ###l4p      );
    ###l4p }

    if ( $app->param('debug') ) {
        printf "%s\n%s TEMPLATE \"%s\" (ID:%d)\n",
            ('='x50), ucfirst($tmpl->type), $tmpl->name, ($tmpl->id||0);
        printf "ORIGINAL template: %s\n", $orig;
        printf "NEW template: %s\n", $new;
        require HTML::Diff;
        import HTML::Diff qw(html_word_diff);
        printf "TEMPLATE DIFF:\n%s\n",
            Dumper(html_word_diff($orig, $new));
    }
    elsif ( $app->param('file') ) {
        $app->print( $new );
    }
    elsif ( $app->param('upgrade') ) {
        my $backup = $tmpl->save_backup();

        $tmpl->text( $new );
        $tmpl->save;

        printf "%s template \"%s\" (ID:%s) upgraded.\n",
            ucfirst($tmpl->type), $tmpl->name, $tmpl->id;
    }

    return 1;
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

