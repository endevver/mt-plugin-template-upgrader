#!/usr/bin/perl -w

use strict;

use lib qw( t/lib   plugins/TemplateUpgrader/lib
            plugins/TemplateUpgrader/extlib 
            plugins/TemplateUpgrader/t/lib
            plugins/TemplateUpgrader/t/extlib
            lib extlib );
# use MT::Test;

use Test::More tests => 18;

use_ok('MT::Bootstrap::CLI');                       #1
use_ok('MT::App::CLI');                             #2
use_ok('TemplateUpgrader');                         #3
use_ok('TemplateUpgrader::Bootstrap');              #4
use_ok('TemplateUpgrader::Builder');                #5
use_ok('TemplateUpgrader::Handlers');               #6
use_ok('TemplateUpgrader::Handlers::CatCalendar');  #7
use_ok('TemplateUpgrader::Handlers::Compare');      #8
use_ok('TemplateUpgrader::Handlers::Core');         #9
use_ok('TemplateUpgrader::Handlers::IfEmpty');      #10
use_ok('TemplateUpgrader::Handlers::Varz');         #11
use_ok('TemplateUpgrader::Template');               #12
use_ok('TemplateUpgrader::Test');                   #13
use_ok('TemplateUpgrader::Tool::Upgrade');          #14
use_ok('HTML::Diff');                               #15
use_ok('Hook::LexWrap');                            #16
use_ok('Sub::Install');                             #17
use_ok('MT::Test');                                 #18

# Maybe there's a way to test these programmatically?
#   html/mt/plugins/TemplateUpgrader/config.yaml
#   html/mt/plugins/TemplateUpgrader/tools/upgrade
