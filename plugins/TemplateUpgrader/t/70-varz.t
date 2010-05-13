#!/usr/bin/perl -w
package TemplateUpgrader::Test::Varz;

use strict;
use lib qw( plugins/TemplateUpgrader/t/lib );
use base qw( TemplateUpgrader::Test );

__PACKAGE__->run();

exit;


__DATA__

[
{ "r" : "1", "t" : "", "e" : ""},                                           #1

{ "r" : "1",    "t" :  "<$mt:SetVar name=\"hello\" value=\"kitty\"$>", 
                "e" : "<mt:var value=\"kitty\" name=\"hello\">"},           #2

{ "r" : "1",    "t" : "<MTGetVar name=\"hello\">",
                "e" : "<mt:var name=\"hello\">"},                           #3

{ "r" : "1",    "t" : "<MTIfOne name=\"hello\">1</MTIfOne>",
                "e" : "<mt:if name=\"hello\" eq=\"1\">1</mt:if>"},          #4

{ "r" : "1",    "t" : "<MTUnlessZero name=\"hello\">1</MTUnlessZero>",
                "e" : "<mt:ifnonzero name=\"hello\">1</mt:ifnonzero>"},     #5

{ "r" : "1",    "t" : "<MTUnlessEmpty name=\"hello\">1</MTUnlessEmpty>",
                "e" : "<mt:ifnonempty name=\"hello\">1</mt:ifnonempty>"}   #6
]
