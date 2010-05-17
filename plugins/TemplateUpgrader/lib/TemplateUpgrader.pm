package TemplateUpgrader;

use strict; use warnings; use Carp; use Data::Dumper;

BEGIN {
    use base qw( Class::Data::Inheritable Class::Accessor::Fast );
    __PACKAGE__->mk_classdata(qw( bootstrapped ));
    __PACKAGE__->mk_classdata(qw( handlers ));
}
use lib qw( lib extlib );
use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

BEGIN { __PACKAGE__->bootstrap() }

sub new_template {
    my $pkg =  shift;
    $pkg->bootstrap();
    my $tmpl_pkg = MT->model('templateupgrader_template')
        or die "No class for templateupgrader_template model";
    eval "require $tmpl_pkg;";
    return $tmpl_pkg->new( @_ );
}

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new( @_ );
    $self->init() if @_;
    $self;
}

sub init {
    my $self = shift;
    $self->bootstrap();
}

sub upgrade {
    my $self                  = shift;
    my ( $tmpl, $handlers )   = @_;
    my $tmpl_class            = MT->model('templateupgrader_template');
    $handlers               ||= $self->handlers || $self->init_handlers();
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();


    my $text_only = ! ref $tmpl;
    if ( $text_only ) {
        ###l4p $logger->info('Got TEXT-ONLY template');
        $tmpl = $self->new_template(
            type => 'scalarref',
            source => ( ref $tmpl ? $tmpl : \$tmpl )
        );
        ###l4p $logger->info('Got TEXT-ONLY template. Now '.ref($tmpl));
    }
    else {
        $tmpl = $tmpl_class->rebless( $tmpl );
        die "Now it's not an MT::Template subclass!"
            unless UNIVERSAL::isa($tmpl, 'MT::Template');
    }
    ###l4p $logger->debug('Class of template to upgrade: '.ref($tmpl).($text_only ? ' (pseudo)' : ''));
    ###l4p $logger->debug('Template text: ', $tmpl->text());


    # $logger->debug('$handlers: ', l4mtdump($handlers));
    # $logger->debug('$tmpl->tokens: ', l4mtdump($tmpl->tokens));
    my $tokens = $tmpl->tokens;
    my $text   = $tmpl->text;
    while ( my ( $tag, $code ) = each %$handlers ) {
        next if $tag eq 'plugin' and ref $code;
        # $logger->debug("Handling tag: $tag with handler ".$code);
        $code = MT->handler_to_coderef( $code ); 
        my $nodes = $tmpl->getElementsByTagName( lc($tag) ) || [];
        foreach my $node ( @$nodes ) {
            $code->($node);
            if ( my $name = $node->getAttribute('name') ) {
                $node->prependAttribute( 'name', $name )
            }
            $logger->debug('NODE DUMP: '.$node->dump_node());
        }
        $tmpl->{reflow_flag} = 1;
        $text = $tmpl->text;
        
        # $tmpl->text( $tmpl->reflow( $tmpl->tokens ) );
        $logger->debug('TEXT AFTER HANDLER "'.$tag.'": '.$tmpl->text());
        # $tmpl->reset_tokens();
    }
    $tmpl->{reflow_flag} = 1;
    $text = $tmpl->text;

    # $tmpl->text( $tmpl->reflow( $tmpl->tokens ) );
    # $tmpl->reset_tokens();
    $logger->debug('TEXT AFTER ALL HANDLERS: '.$text);
    
    # $tmpl->reflow( $tmpl->tokens() );
    # $tmpl->text( MT->model('templateupgrader_builder')->reflow( $tmpl ) || '' );
    # $tmpl->text( $text );

    return ($text_only ? $text : $tmpl);
}

sub compile_markup {
    my $self    = shift;
    my $markup  = shift;
    my $builder = MT->model('templateupgrader_builder')->new();
    my $ctx     = MT::Template::Context->new;
    $ctx->stash('builder', $builder);
    my $tokens = $builder->compile($ctx, $markup);
    $logger->error('# -- error compiling: ' . $b->errstr)
        unless defined $tokens;
    return $tokens;
}

sub init_handlers {
    my $self = shift;
    my $handlers = $self->handlers || {};
    return $handlers if keys %$handlers;

    my $plugin = MT->component('TemplateUpgrader')
        or die "Could not retrieve TemplateUpgrader plugin component";
    my $regdata = $plugin->registry('tag_upgrade_handlers')
        or die "Failed initialization of plugin registry";
    $self->handlers( $regdata || {} );
        ###l4p $logger->debug('$self->handlers: ', l4mtdump($self->handlers));
    return $self->handlers;
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

