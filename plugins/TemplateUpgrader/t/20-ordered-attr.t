#!/usr/bin/perl -w
package TemplateUpgrader::Test::OrderedAttributes;
use strict; use warnings; use Carp; use Data::Dumper;

BEGIN {
    $ENV{MT_CONFIG} = $ENV{MT_HOME}.'/mt-config.cgi';    
}
use lib qw( plugins/TemplateUpgrader/t/lib );
use base qw( TemplateUpgrader::Test );
use TemplateUpgrader;

__PACKAGE__->run_data_tests();

exit;

# numify            dirify              zero_pad            nl2br
# mteval            sanitize            sprintf             replace
# filters           encode_sha1         regex_replace       spacify
# trim_to           encode_html         capitalize          string_format
# trim              encode_xml          count_characters    strip
# ltrim             encode_js           cat                 strip_tags
# rtrim             encode_php          count_paragraphs    _default
# decode_html       encode_url          count_words         nofollowfy
# decode_xml        upper_case          escape              wrap_text
# remove_html       lower_case          indent              setvar
# space_pad         strip_linefeeds

__DATA__

[
{ "r" : "1", "t" : "<mtblogname encode_html=\"1\">",
             "e" : "<mt:blogname encode_html=\"1\">" }, #1

{ "r" : "1", "t" : "<mt:EntryTrackbackCount none=\"No TrackBacks\" plural=\"# TrackBacks\" singular=\"1 TrackBack\">",
             "e" : "<mt:entrytrackbackcount none=\"No TrackBacks\" plural=\"# TrackBacks\" singular=\"1 TrackBack\">" }, #2

{ "r" : "1", "t" : "<mt:EntryTrackbackCount plural=\"# TrackBacks\" none=\"No TrackBacks\" singular=\"1 TrackBack\">",
             "e" : "<mt:entrytrackbackcount plural=\"# TrackBacks\" none=\"No TrackBacks\" singular=\"1 TrackBack\">" }, #3

{ "r" : "1", "t" : "<mt:Comments glue=\",\" sort_order=\"ascend\">This is a comment</mt:Comments>",
             "e" : "<mt:comments glue=\",\" sort_order=\"ascend\">This is a comment</mt:comments>" }, #4
             
{ "r" : "1", "t" : "<form method=\"post\" action=\"<$mt:CGIPath$><$mt:CommunityScript$>\" name=\"entry_form\" id=\"create-entry-form\" enctype=\"multipart/form-data\">",
             "e" : "<form method=\"post\" action=\"<mt:cgipath><mt:communityscript>\" name=\"entry_form\" id=\"create-entry-form\" enctype=\"multipart/form-data\">" }, #5
             
{ "r" : "1", "t" : "<input type=\"hidden\" name=\"blog_id\" value=\"<$mt:BlogID$>\" />",
             "e" : "<input type=\"hidden\" name=\"blog_id\" value=\"<mt:blogid>\" />" }, #6
             
{ "r" : "1", "t" : "<$mt:Include module=\"Form Field\" id=\"entry-title\" class=\"\" label=\"Title\"$>",
             "e" : "<mt:include module=\"Form Field\" id=\"entry-title\" class=\"\" label=\"Title\">" }, #7
             
{ "r" : "1", "t" : "<$mt:Include module=\"Form Field\" id=\"entry-body\" class=\"\" label=\"Body\"$>",
             "e" : "<mt:include module=\"Form Field\" id=\"entry-body\" class=\"\" label=\"Body\">" }, #8
             
{ "r" : "1", "t" : "<mt:SetVarBlock name=\"loop_to\"><$mt:Var name=\"__depth__\" _default=\"0\"$></mt:SetVarBlock><mt:SetVarBlock name=\"spacer\"><mt:For start=\"1\" end=\"$loop_to\">&nbsp;&nbsp;&nbsp;&nbsp;</mt:For></mt:SetVarBlock><option value=\"<$mt:CategoryID$>\"><$mt:Var name=\"spacer\"$><$mt:CategoryLabel$></option><$mt:SubCatsRecurse$>",
             "e" : "<mt:setvarblock name=\"loop_to\"><mt:var name=\"__depth__\" _default=\"0\"></mt:setvarblock><mt:setvarblock name=\"spacer\"><mt:for start=\"1\" end=\"$loop_to\">&nbsp;&nbsp;&nbsp;&nbsp;</mt:for></mt:setvarblock><option value=\"<mt:categoryid>\"><mt:var name=\"spacer\"><mt:categorylabel></option><mt:subcatsrecurse>" }, #9

{ "r" : "1", "t" : "<$mt:Include module=\"Form Field\" id=\"entry-category\" class=\"\" label=\"Category\"$>",
             "e" : "<mt:include module=\"Form Field\" id=\"entry-category\" class=\"\" label=\"Category\">" }, #10

{ "r" : "1", "t" : "<mt:SetVarBlock name=\"custom_field_name\"><$mt:CustomFieldName$></mt:SetVarBlock>
                       <mt:SetVarBlock name=\"field-content\"><$mt:CustomFieldHTML$></mt:SetVarBlock>
                       <mt:SetVarBlock name=\"custom_field_id\">profile_<$mt:CustomFieldName dirify=\"1\"$></mt:SetVarBlock>
                       <$mt:Include module=\"Form Field\" id=\"$custom_field_id\" class=\"\" label=\"$custom_field_name\"$>",
             "e" : "<mt:setvarblock name=\"custom_field_name\"><mt:customfieldname></mt:setvarblock>
                       <mt:setvarblock name=\"field-content\"><mt:customfieldhtml></mt:setvarblock>
                       <mt:setvarblock name=\"custom_field_id\">profile_<mt:customfieldname dirify=\"1\"></mt:setvarblock>
                       <mt:include module=\"Form Field\" id=\"$custom_field_id\" class=\"\" label=\"$custom_field_name\">" }, #11

{ "r" : "1", "t" : "<mt:IfLoggedIn>YAY I AM LOGGED IN<mt:Else>BOO NO LOGIN FOR ME</mt:Else></mt:IfLoggedIn>",
             "e" : "<mt:ifloggedin>YAY I AM LOGGED IN<mt:else>BOO NO LOGIN FOR ME</mt:ifloggedin>" } #12

]

