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

{ "r" : "1",    "t" : "<MTIfEmpty tag=\"Date\">Nodate<mt:Else>Yaydate</MTIfEmpty>",
                "e" : "<mt:if tag=\"Date\" eq=\"\">Nodate<mt:Else>Yaydate</mt:Else></mt:if>"}, #3

{ "r" : "1",    "t" : "<MTIfNotEmpty tag=\"CGIPath\">yaycgipath</MTIfNotEmpty>",
                "e" : "<mt:unless tag=\"CGIPath\" eq=\"\">yaycgipath</mt:unless>"}, #4

{ "r" : "1",    "t" : "<MTIfEmpty var=\"Date\">Nodate<MTElse>Yaydate</MTElse></MTIfEmpty>",
                "e" : "<mt:if tag=\"Date\" eq=\"\">Nodate<mt:else>Yaydate</mt:if>"}, #5

{ "r" : "1",    "t" : "<MTIfEmpty var=\"Date\">Nodate<mt:Else>Yaydate</MTIfEmpty>",
                "e" : "<mt:if tag=\"Date\" eq=\"\">Nodate<mt:else>Yaydate</mt:if>"}, #6

{ "r" : "1",    "t" : "<MTIfNotEmpty var=\"CGIPath\">yaycgipath</MTIfNotEmpty>",
                "e" : "<mt:unless tag=\"CGIPath\" eq=\"\">yaycgipath</mt:unless>"} #7
]
