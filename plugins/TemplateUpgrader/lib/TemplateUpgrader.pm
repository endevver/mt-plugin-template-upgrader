package TemplateUpgrader;

use strict; use warnings; use Carp; use Data::Dumper;

BEGIN {
    use base qw( Class::Data::Inheritable Class::Accessor::Fast );
    __PACKAGE__->mk_classdata(qw( bootstrapped ));
    __PACKAGE__->mk_classdata(qw( handlers ));
    use TemplateUpgrader::Bootstrap;
}
use lib qw( lib extlib );
use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

sub new_template {
    my $pkg =  shift;
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
}

sub upgrade {
    my $self                  = shift;
    my ( $tmpl, $handlers )   = @_;
    my $tmpl_class            = MT->model('templateupgrader_template');
    $handlers               ||= $self->handlers || $self->init_handlers();
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    my $text_only = ! ref $tmpl;
    if ( $text_only ) {
        $tmpl = $self->new_template(
            type => 'scalarref',
            source => ( ref $tmpl ? $tmpl : \$tmpl )
        );
    }
    else {
        $tmpl = TemplateUpgrader::Bootstrap->rebless( $tmpl );
        die "Now it's not an MT::Template subclass!"
            unless UNIVERSAL::isa($tmpl, 'MT::Template');
    }

    my $tokens = $tmpl->tokens;
    my $text   = $tmpl->text;
    while ( my ( $tag, $code ) = each %$handlers ) {
        next if $tag eq 'plugin' and ref $code;
        $code = MT->handler_to_coderef( $code ); 
        my $nodes = $tmpl->getElementsByTagName( lc($tag) ) || [];
        foreach my $node ( @$nodes ) {
            $logger->info("Running code on node $node: ".$node->dump_node());
            $code->($node);
            $logger->debug('NODE DUMP: '.$node->dump_node(0,1,4));
        }
        $tmpl->text( $tmpl->reflow() );
        $tokens = $tmpl->tokens;
        $logger->debug('TEXT AFTER HANDLER "'.$tag.'": '
                        .( $text = $tmpl->text ));
    }
    $text = $tmpl->text;
    $logger->debug('TEXT AFTER ALL HANDLERS: '.$text);
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

