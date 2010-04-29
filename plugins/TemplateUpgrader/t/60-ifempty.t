#!/usr/bin/perl -w
package TemplateUpgrader::Test::Varz;

use strict;
use lib qw( plugins/TemplateUpgrader/t/lib );
use base qw( TemplateUpgrader::Test );

__PACKAGE__->run();

exit;


__DATA__

[
{ "r" : "1",    "t" : "<MTIfEmpty expr=\"[MTEntryComments]1[/MTEntryComments]\">Basta</MTIfEmpty>",
                "e" : "<mt:IfEmpty expr=\"[MTEntryComments]1[/MTEntryComments]\">Basta</mt:IfEmpty>"}, #1

{ "r" : "1",    "t" : "<MTIfEmpty tag=\"Date\">Nodate<MTElse>Yaydate</MTElse></MTIfEmpty>",
                "e" : "<mt:if tag=\"Date\" eq=\"\">Nodate<mt:Else>Yaydate</mt:Else></mt:if>"}, #2

{ "r" : "1",    "t" : "<MTIfNotEmpty tag=\"CGIPath\">yaycgipath</MTIfNotEmpty>",
                "e" : "<mt:unless tag=\"CGIPath\" eq=\"\">yaycgipath</mt:unless>"} #3
]
