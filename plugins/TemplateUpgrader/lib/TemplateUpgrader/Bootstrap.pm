package TemplateUpgrader::Bootstrap;
use strict; use warnings; use Carp; use Data::Dumper;

BEGIN {
    use base qw( Class::Accessor::Fast Class::Data::Inheritable );
    __PACKAGE__->mk_classdata(qw( bootstrapped ));
    __PACKAGE__->mk_classdata(qw( handlers ));
    __PACKAGE__->mk_classdata(qw( app ));
}
use lib qw( lib extlib );

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();


sub import {
    my $pkg = shift;
    return if $pkg->bootstrapped;
    my ($app, $registry);
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    ###l4p $logger->debug('Bootstrapping class');
    eval {
        require MT::Test;
        MT::Test->init_app( $ENV{MT_HOME}.'/mt-config.cgi' );
        $app = MT->instance;
        ###l4p $logger->debug('Initialized MT app of class: '.ref($app).' '.$app);
        $registry = $app->registry('object_types')
            or die "MT registry not initialized: ".Carp::longmess();
    };
    if ($@) { print STDERR "$@\n"; exit }

    ###l4p $logger->debug('Registry: ', l4mtdump($registry));

    foreach my $type ( qw( Template Builder Handlers )) {
        my $opkg   = join('::', (split('::', $pkg))[0], $type );
        ( my $model = lc $opkg ) =~ s{::}{_}g;
        ###l4p $logger->debug('Model/Pkg: ', l4mtdump({
        ###l4p     model     => $model,
        ###l4p     opkg      => $opkg,
        ###l4p     app_model => $app->model( $model ),
        ###l4p }));        
        next if $app->model( $model );
        ###l4p $logger->info("Setting registry object type $model to $opkg");
        $registry->{ $model } = $opkg;
        my $app_model = $app->model( $model, $opkg ); # Forced refresh!
        ###l4p $logger->debug("Initialized MT model $model: ".$app_model);
    }
    ###l4p $logger->info('WE ARE NOW BOOTSTRAPPED IN '.$pkg);
    $pkg->app( $app );
    $pkg->bootstrapped(1);

    ###l4p $logger->debug('Registry: ', l4mtdump($registry));
}

1;