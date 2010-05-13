#!/usr/bin/perl -w

use strict;

use lib qw( t/lib   plugins/TemplateUpgrader/lib
            plugins/TemplateUpgrader/extlib 
            plugins/TemplateUpgrader/t/lib
            plugins/TemplateUpgrader/t/extlib
            lib extlib );
# use MT::Test;

use Test::More tests => 16;

use_ok('MT::Bootstrap::CLI');                       #1
use_ok('MT::App::CLI');                             #2
use_ok('TemplateUpgrader');                         #3
use_ok('TemplateUpgrader::Builder');                #4
use_ok('TemplateUpgrader::Handlers');               #5
use_ok('TemplateUpgrader::Handlers::CatCalendar');  #6
use_ok('TemplateUpgrader::Handlers::Compare');      #7
use_ok('TemplateUpgrader::Handlers::Core');         #8
use_ok('TemplateUpgrader::Handlers::IfEmpty');      #9
use_ok('TemplateUpgrader::Handlers::Varz');         #10
use_ok('TemplateUpgrader::Template');               #11
use_ok('TemplateUpgrader::Test');                   #12
use_ok('TemplateUpgrader::Tool::Upgrade');          #13
use_ok('HTML::Diff');                               #14
use_ok('Hook::LexWrap');                            #15
use_ok('Sub::Install');                             #16

# Maybe there's a way to test these programmatically?
#   html/mt/plugins/TemplateUpgrader/config.yaml
#   html/mt/plugins/TemplateUpgrader/tools/upgrade
