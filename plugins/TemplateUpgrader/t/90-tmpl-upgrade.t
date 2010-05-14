# #!/usr/bin/perl -w
# package TemplateUpgrader::Test::Compare;
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
