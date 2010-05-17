#!/usr/bin/perl -w
package TemplateUpgrader::Test::CatCalendar;

use strict;
use lib qw( plugins/TemplateUpgrader/t/lib );
use base qw( TemplateUpgrader::Test );

__PACKAGE__->run_data_tests();

exit;

__DATA__

[
{ "r" : "1",    "t" : "<MTIfCategoryArchivesEnabled>hoooray</MTIfCategoryArchivesEnabled>",
                "e" : "<mt:ifarchivetypeenabled type=\"Category\">hoooray</mt:ifarchivetypeenabled>"}       #1
]
