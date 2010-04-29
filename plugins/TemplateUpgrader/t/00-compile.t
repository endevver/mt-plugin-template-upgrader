#!/usr/bin/perl -w

use strict;

use lib qw( t/lib   plugins/TemplateUpgrader/lib
            plugins/TemplateUpgrader/extlib lib extlib );
# use MT::Test;

use Test::More tests => 9;

use_ok('MT::Bootstrap::CLI');                   #1
use_ok('MT::App::CLI');                         #2
use_ok('TemplateUpgrader');                     #3
use_ok('TemplateUpgrader::Tool::Upgrade');      #4
use_ok('TemplateUpgrader::Handlers');           #5
use_ok('TemplateUpgrader::Handlers::Varz');     #6
use_ok('TemplateUpgrader::Handlers::Compare');  #7
use_ok('TemplateUpgrader::Handlers::IfEmpty');  #8
use_ok('HTML::Diff');                           #9

# Maybe there's a way to test these programmatically?
#   html/mt/plugins/TemplateUpgrader/config.yaml
#   html/mt/plugins/TemplateUpgrader/tools/upgrade
