#!/usr/bin/perl -w
package TemplateUpgrader::Test::Init;
use strict; use warnings; use Carp; use Data::Dumper;

BEGIN {
    $ENV{MT_CONFIG} = $ENV{MT_HOME}.'/mt-config.cgi';    
    use Test::More tests => 8;
    use lib qw( plugins/TemplateUpgrader/t/lib );
    use_ok( 'TemplateUpgrader::Test' );                                     #1
    use base qw( TemplateUpgrader::Test );
    use_ok( 'TemplateUpgrader' );                                           #2
    use_ok( 'MT::Test' );                                                   #3
}


my $upgrader = TemplateUpgrader->new();
is(ref $upgrader, 'TemplateUpgrader', 'Upgrader class initialized');        #4

my $app = MT->instance;
isa_ok($app, 'MT::App', 'MT is intialized');                                #5


is( MT->model('templateupgrader_template'),
    'TemplateUpgrader::Template',
    'TemplateUpgrader::Template model');                                    #6

is( MT->model('templateupgrader_handlers'),
    'TemplateUpgrader::Handlers',
    'TemplateUpgrader::Handlers model');                                    #7

is( MT->model('templateupgrader_builder'),
    'TemplateUpgrader::Builder',
    'TemplateUpgrader::Builder model');                                     #8
