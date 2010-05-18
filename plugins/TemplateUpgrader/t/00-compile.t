#!/usr/bin/perl -w
use strict; use warnings; use Carp; use Data::Dumper;

use Test::More tests => 18;

use lib qw( plugins/TemplateUpgrader/lib );
use_ok('TemplateUpgrader::Bootstrap');              #1
use_ok('TemplateUpgrader');                         #2
use_ok('TemplateUpgrader::Builder');                #3
use_ok('TemplateUpgrader::Handlers');               #4
use_ok('TemplateUpgrader::Handlers::CatCalendar');  #5
use_ok('TemplateUpgrader::Handlers::Compare');      #6
use_ok('TemplateUpgrader::Handlers::Core');         #7
use_ok('TemplateUpgrader::Handlers::IfEmpty');      #8
use_ok('TemplateUpgrader::Handlers::Varz');         #9
use_ok('TemplateUpgrader::Template');               #10
use_ok('TemplateUpgrader::Test');                   #11
use_ok('TemplateUpgrader::Tool::Upgrade');          #12
use_ok('MT::Bootstrap::CLI');                       #13
use_ok('MT::App::CLI');                             #14
use_ok('HTML::Diff');                               #15
use_ok('Hook::LexWrap');                            #16
use_ok('Sub::Install');                             #17
use_ok('MT::Test');                                 #18

# Maybe there's a way to test these programmatically?
#   html/mt/plugins/TemplateUpgrader/config.yaml
#   html/mt/plugins/TemplateUpgrader/tools/upgrade
