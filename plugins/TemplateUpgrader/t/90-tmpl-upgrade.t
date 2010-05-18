#!/usr/bin/perl -w
package TemplateUpgrader::Test::Template::Upgrade;
use strict; use warnings; use Carp; use Data::Dumper;

# use Test::More tests => 1;
use Test::More qw( no_plan );
my $app;
BEGIN {
    use lib qw( plugins/TemplateUpgrader/lib );
    use TemplateUpgrader::Bootstrap;
    $app = TemplateUpgrader::Bootstrap->app();
}
# use Test::Deep qw( eq_deeply );
# use Test::Warn;
$Data::Dumper::Indent = 1;
$Data::Dumper::Maxdepth = 4;

use base qw( TemplateUpgrader::Test );
use TemplateUpgrader;
use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new(); $logger->trace();
my $tmpl_class = MT->model('templateupgrader_template');
use TemplateUpgrader::Template;

my %tmpl_data = (
    text    => 'This is the original text',
    name    => "My test template $$",
    type    => 'index',
    blog_id => 1,
);

my $tmpl   = new_template( %tmpl_data );
my $loaded = load_by_id( $tmpl->id );
compare_templates( $tmpl, $loaded );
my $backup = $loaded->save_backup();

subtest 'Backup template' => sub {
    plan tests => 2 + (keys %tmpl_data);
    isa_ok( $backup, $tmpl_class );
    isnt( $backup->id, $tmpl->id, 'Template ID' );
    is( $backup->blog_id, $tmpl_data{blog_id}, 'Template blog_id' );
    like( $backup->name, qr/$tmpl_data{name}/, 'Template name' );
    is( $backup->type, 'backup', 'Template type' );
    is( $backup->meta('parent'), $tmpl->id, 'Parent template ID meta' );
};


sub new_template {
    my %data = @_;
    my $tmpl;
    subtest 'New template' => sub {
        plan tests => 2;
        $tmpl = new_ok( $tmpl_class => [], 'Template' );
        $tmpl->set_values( \%tmpl_data );
        my $rc = $tmpl->save()
            or die "Error saving template: ".$tmpl->errstr;
        ok( $rc, 'Template save'.($rc ? '' : " error: ".$tmpl->errstr ) );
    };
    return $tmpl;
}

sub load_by_id {
    my $id     = shift;
    my $loaded = $tmpl_class->load( $id )
        or die "Error loading template ID $id: ".$tmpl_class->errstr;
}

sub compare_templates {
    my (@tmpls) = @_;
    subtest 'Comparing templates' => sub {
        plan tests => 2 + (keys %tmpl_data);
        isa_ok( $tmpls[0], $tmpl_class );
        isa_ok( $tmpls[1], $tmpl_class );
        is( $tmpls[0]->$_, $tmpls[1]->$_, "Template $_ comparison")
            foreach keys %tmpl_data;
    };
}

# my $tmpl = MT->model('template')->load(468);
# $logger->debug('TMPL: ', l4mtdump($tmpl));
# $tmpl->meta('parent', 401);
# $tmpl->save;
# my @entries = MT::Entry->load(undef, {
#     'join' => MT::Comment->join_on( 'entry_id',
#                 { blog_id => $blog_id },
#                 { 'sort' => 'created_on',
#                   direction => 'descend',
#                   unique => 1,
#                   limit => 10 } )
# });
# 
# ok(1);




# 
# use strict;
# use lib qw( plugins/TemplateUpgrader/t/lib );
# use SelfLoader;
# use base qw( TemplateUpgrader::Test );
# 
# my $template = <<EOF;
# <mt:Unless name="global_options_loaded"><$mt:Include module="Global Options"$></mt:Unless>
# 
# <?php include('<$mt:BlogSitePath$>includes/FilmCritic-lib.php'); ?>
# 
# 
# <mt:Ignore>
#     <!-- ************************
#          *     STYLESHEETS      *
#          ************************ -->
# </mt:Ignore>
#     <link rel="stylesheet" href="<$mt:Var name="master_base_url"$>css/styles-global.css" type="text/css" />
#     <mt:Ignore><link rel="stylesheet" href="<$mt:Var name="master_base_url"$>css/ajaxrating.css" type="text/css" /></mt:Ignore>
#     <link rel="stylesheet" href="<$mt:BlogURL$>css/styles.css" type="text/css" />
#     <mt:Ignore>
#       <?php if (isset($toprated_index)) { ?>
#           <link rel="stylesheet" href="<$mt:TmplSetStaticWebPath$>ui/development-bundle/themes/base/ui.all.css" type="text/css" />
#       <!-- ui/development-bundle/themes/smoothness/ui.all.css -->
#       <? } ?>
#     </mt:Ignore>
#     <link rel="stylesheet" href="http://media.amctv.com/css/filmcritic/custom-echo.css" type="text/css" />
#     <?php if (isset($toprated_index)) { ?>
#         <link rel="stylesheet" href="<$mt:TmplSetStaticWebPath$>ui/development-bundle/themes/base/ui.all.css" type="text/css" />
#     <!-- ui/development-bundle/themes/smoothness/ui.all.css -->
#     <? } ?>
#     <link rel="stylesheet" href="<$mt:TmplSetStaticWebPath$>css/smoothness/jquery-ui-1.7.2.custom.css" type="text/css" />
#     <link rel="stylesheet" href="<$mt:TmplSetStaticWebPath$>css/ui.stars.min.css" type="text/css" />
#     <!--[if lte IE 6]>
#     <link rel="stylesheet" href="<$mt:TmplSetStaticWebPath$>css/fix-ie6.css" type="text/css" />
#     <![endif]-->
#     <!--[if IE 7]>
#     <link rel="stylesheet" href="<$mt:TmplSetStaticWebPath$>css/fix-ie7.css" type="text/css" />
#     <![endif]-->
# <mt:Ignore>
#     <!-- **************************
#          *     MISCELLANEOUS      *
#          ************************** -->
# </mt:Ignore>
#     <link rel="start" href="<$mt:Var name="master_base_url"$>" title="Home" />
#     <link rel="alternate" type="application/atom+xml" title="Recent Entries" href="<$mt:Var name="feed_url"$>" />
#     <meta name="generator" content="<$mt:ProductName version="1"$>" />
# <mt:Ignore>
#     <!-- **************************
#          *       JAVASCRIPT       *
#          ************************** -->
# </mt:Ignore>
#     <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js" type="text/javascript"></script>
#     <script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/jquery-ui.min.js" type="text/javascript"></script>
# <?php if ( isset($search_index) && $search_index ) { ?>
#     <script type="text/javascript">
#     <!--
#         jQuery.noConflict();
#     // -->
#     </script> 
#     <?php } ?><script src="<$mt:TmplSetStaticWebPath$>js/jquery.badebug.min.js" type="text/javascript"></script>
#     <script src="<$mt:TmplSetStaticWebPath$>js/jquery.hoverIntent.minified.js" type="text/javascript"></script>
#     <script src="<$mt:TmplSetStaticWebPath$>js/jquery.idTabs.min.js" type="text/javascript"></script>
#     <script src="<$mt:TmplSetStaticWebPath$>js/jquery.tablesorter.js" type="text/javascript"></script> 
#     <script src="<$mt:TmplSetStaticWebPath$>js/tablefilter/jquery.tablefilter.js" type="text/javascript"></script> 
#     <script src="<$mt:TmplSetStaticWebPath$>js/jquery.cookie.js" type="text/javascript"></script> 
#     <script src="<$mt:TmplSetStaticWebPath$>js/ui.stars.min.js" type="text/javascript"></script>
#     <mt:Ignore><script src="<$mt:Var name="master_base_url"$>js/ajaxrating.js" type="text/javascript"></script></mt:Ignore>
#     <!--[if lte IE 6]>
#     <script type="text/javascript" src="<$mt:TmplSetStaticWebPath$>js/jquery.supersleight.js"></script>
#     <![endif]-->
#     <?php if ( ! (isset($search_index) && $search_index) ) { ?><script src="<$mt:Var name="master_base_url"$>js/mt.js" type="text/javascript"></script><?php } ?>
#     <script src="<$mt:TmplSetStaticWebPath$>js/site.js" type="text/javascript"></script>
#     <$mt:CCLicenseRDF$>
#     <script type="text/javascript"><!--
#         var fcHasEntryTags      = 0;
#         var addthis_pub         = 'rainbowmedia';
#         var filmcriticRatingURL = 'http://<$mt:BlogHost$>/mt/addons/FilmCritic.plugin/rate.cgi';
#         var amgJsonURL          = '<mt:Var name="amgJsonURL">'
#         var baseURL             = '<$mt:Var name="master_base_url"$>';
#         /* Ad code and site metrics variables */
#         var tracker_page_section = '';
#         var tracker_page_name    = '';
#         var ad_category          = '';
#         var ad_entry_title       = '';
#         jQuery(function($) {
#             window.fc = filmcritic();
#         })
#         // -->
#     </script> 
# <mt:If tag="BlogURL" like="/(filmcritic.com|amctv.com)/">
#     <script src="http://s7.addthis.com/js/152/addthis_widget.js" type="text/javascript"></script>
# </mt:If>
# ",
# "e" : "
# <mt:Unless name="global_options_loaded"><$mt:Include module="Global Options"$></mt:Unless>
# 
# <?php include('<$mt:BlogSitePath$>includes/FilmCritic-lib.php'); ?>
# 
# 
# <mt:Ignore>
#     <!-- ************************
#          *     STYLESHEETS      *
#          ************************ -->
# </mt:Ignore>
#     <link rel="stylesheet" href="<$mt:Var name="master_base_url"$>css/styles-global.css" type="text/css" />
#     <mt:Ignore><link rel="stylesheet" href="<$mt:Var name="master_base_url"$>css/ajaxrating.css" type="text/css" /></mt:Ignore>
#     <link rel="stylesheet" href="<$mt:BlogURL$>css/styles.css" type="text/css" />
#     <mt:Ignore>
#       <?php if (isset($toprated_index)) { ?>
#           <link rel="stylesheet" href="<$mt:TmplSetStaticWebPath$>ui/development-bundle/themes/base/ui.all.css" type="text/css" />
#       <!-- ui/development-bundle/themes/smoothness/ui.all.css -->
#       <? } ?>
#     </mt:Ignore>
#     <link rel="stylesheet" href="http://media.amctv.com/css/filmcritic/custom-echo.css" type="text/css" />
#     <?php if (isset($toprated_index)) { ?>
#         <link rel="stylesheet" href="<$mt:TmplSetStaticWebPath$>ui/development-bundle/themes/base/ui.all.css" type="text/css" />
#     <!-- ui/development-bundle/themes/smoothness/ui.all.css -->
#     <? } ?>
#     <link rel="stylesheet" href="<$mt:TmplSetStaticWebPath$>css/smoothness/jquery-ui-1.7.2.custom.css" type="text/css" />
#     <link rel="stylesheet" href="<$mt:TmplSetStaticWebPath$>css/ui.stars.min.css" type="text/css" />
#     <!--[if lte IE 6]>
#     <link rel="stylesheet" href="<$mt:TmplSetStaticWebPath$>css/fix-ie6.css" type="text/css" />
#     <![endif]-->
#     <!--[if IE 7]>
#     <link rel="stylesheet" href="<$mt:TmplSetStaticWebPath$>css/fix-ie7.css" type="text/css" />
#     <![endif]-->
# <mt:Ignore>
#     <!-- **************************
#          *     MISCELLANEOUS      *
#          ************************** -->
# </mt:Ignore>
#     <link rel="start" href="<$mt:Var name="master_base_url"$>" title="Home" />
#     <link rel="alternate" type="application/atom+xml" title="Recent Entries" href="<$mt:Var name="feed_url"$>" />
#     <meta name="generator" content="<$mt:ProductName version="1"$>" />
# <mt:Ignore>
#     <!-- **************************
#          *       JAVASCRIPT       *
#          ************************** -->
# </mt:Ignore>
#     <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js" type="text/javascript"></script>
#     <script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/jquery-ui.min.js" type="text/javascript"></script>
# <?php if ( isset($search_index) && $search_index ) { ?>
#     <script type="text/javascript">
#     <!--
#         jQuery.noConflict();
#     // -->
#     </script> 
#     <?php } ?><script src="<$mt:TmplSetStaticWebPath$>js/jquery.badebug.min.js" type="text/javascript"></script>
#     <script src="<$mt:TmplSetStaticWebPath$>js/jquery.hoverIntent.minified.js" type="text/javascript"></script>
#     <script src="<$mt:TmplSetStaticWebPath$>js/jquery.idTabs.min.js" type="text/javascript"></script>
#     <script src="<$mt:TmplSetStaticWebPath$>js/jquery.tablesorter.js" type="text/javascript"></script> 
#     <script src="<$mt:TmplSetStaticWebPath$>js/tablefilter/jquery.tablefilter.js" type="text/javascript"></script> 
#     <script src="<$mt:TmplSetStaticWebPath$>js/jquery.cookie.js" type="text/javascript"></script> 
#     <script src="<$mt:TmplSetStaticWebPath$>js/ui.stars.min.js" type="text/javascript"></script>
#     <mt:Ignore><script src="<$mt:Var name="master_base_url"$>js/ajaxrating.js" type="text/javascript"></script></mt:Ignore>
#     <!--[if lte IE 6]>
#     <script type="text/javascript" src="<$mt:TmplSetStaticWebPath$>js/jquery.supersleight.js"></script>
#     <![endif]-->
#     <?php if ( ! (isset($search_index) && $search_index) ) { ?><script src="<$mt:Var name="master_base_url"$>js/mt.js" type="text/javascript"></script><?php } ?>
#     <script src="<$mt:TmplSetStaticWebPath$>js/site.js" type="text/javascript"></script>
#     <$mt:CCLicenseRDF$>
#     <script type="text/javascript"><!--
#         var fcHasEntryTags      = 0;
#         var addthis_pub         = 'rainbowmedia';
#         var filmcriticRatingURL = 'http://<$mt:BlogHost$>/mt/addons/FilmCritic.plugin/rate.cgi';
#         var amgJsonURL          = '<mt:Var name="amgJsonURL">'
#         var baseURL             = '<$mt:Var name="master_base_url"$>';
#         /* Ad code and site metrics variables */
#         var tracker_page_section = '';
#         var tracker_page_name    = '';
#         var ad_category          = '';
#         var ad_entry_title       = '';
#         jQuery(function($) {
#             window.fc = filmcritic();
#         })
#         // -->
#     </script> 
# <mt:If tag="BlogURL" like="/(filmcritic.com|amctv.com)/">
#     <script src="http://s7.addthis.com/js/152/addthis_widget.js" type="text/javascript"></script>
# </mt:If>
# EOF
# 
# __PACKAGE__->run_data_tests();
# 
# exit;
