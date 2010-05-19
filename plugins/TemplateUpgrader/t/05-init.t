#!/usr/bin/perl -w
package TemplateUpgrader::Test::Init;
use strict; use warnings; use Carp; use Data::Dumper;

use Test::More tests => 6;

my $app;
BEGIN {
    use lib qw( plugins/TemplateUpgrader/lib );
    use TemplateUpgrader::Bootstrap qw( :app );
    $app = TemplateUpgrader::Bootstrap->app();
}

use base qw( TemplateUpgrader::Test );
use TemplateUpgrader;
use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new(); $logger->trace();

### MT::App INITIALIZATION
isa_ok($app, 'MT::App', 'MT is intialized');                                #1

### APP MODDELS
is( $app->model('templateupgrader_template'),
    'TemplateUpgrader::Template',
    'TemplateUpgrader::Template model');                                    #2
is( MT->model('templateupgrader_handlers'),
    'TemplateUpgrader::Handlers',
    'TemplateUpgrader::Handlers model');                                    #3
is( MT->model('templateupgrader_builder'),
    'TemplateUpgrader::Builder',
    'TemplateUpgrader::Builder model');                                     #4

### UPGRADER INITIALIZATION
my $upgrader = TemplateUpgrader->new();
is(ref $upgrader, 'TemplateUpgrader', 'Upgrader class initialized');        #5

### NEW TEMPLATE CREATION
my $tmpl = $upgrader->new_template();
isa_ok( $tmpl, 'TemplateUpgrader::Template' );                              #6

