package TemplateUpgrader::Bootstrap;
use strict; use warnings; use Carp; use Data::Dumper;

BEGIN {
    use base qw( Class::Data::Inheritable Class::Accessor::Fast );
    __PACKAGE__->mk_classdata(qw( bootstrapped ));
    __PACKAGE__->mk_classdata(qw( handlers ));
}
use lib qw( lib extlib );

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();


sub import {
    my $pkg = shift;
    return if $pkg->bootstrapped;

    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    ###l4p $logger->debug('Bootstrapping class');
    my ($app, $registry);
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
        my $opkg   = join('::', $pkg, $type );
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
    $pkg->bootstrapped(1);
}

