package TemplateUpgrader::Handlers::Core;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

use base qw( TemplateUpgrader::Handlers );

sub hdlr_else {
    my $node    = shift;
    # my $parent  = $node->parentNode()  if $node;
    # my $content = $parent->nodeValue() if $parent;
    # return unless defined $content;
    my $tmpl = $node->ownerDocument();
    $tmpl->{reflow_flag} = 1;
    ###l4p $logger->debug('REFLOWED TEXT: '.$tmpl->text());
    __PACKAGE__->report( $node );
    return;

    # my $tmpl    = $node->ownerDocument();
    # ##l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    # ##l4p $logger->debug("PRE ELSE CONTENT: $content");
    # $content =~ s{<\s*/mt:?else\s*>}{}gi;
    # ##l4p $logger->debug("POST ELSE CONTENT: $content");
    # ##l4p $logger->debug('Nodes 0-4: ', l4mtdump([ map { $node->[$_] } 0..4 ]));

    # my $builder = TemplateUpgrader::Builder->new();
    # $parent->innerHTML( $builder->reflow( $node ) );

    # $parent->[3] = $content;
    # $tmpl->tokens();
    # if ($tmpl) {
    #     $tmpl->{reflow_flag} = 1;
    #     $builder->reflow()
    #     $tmpl->reflow();
    # 
    # }
    # 
    __PACKAGE__->report( $node );
}

sub report {
    my $self               = shift;
    my ( $node, $message ) = @_;
    $self->SUPER::report({
        plugin  => 'Core',
        node    => $node,
        message => ($message||'')
    });
}

sub report_skipped {
    my $self               = shift;
    my ( $node, $message ) = @_;
    $self->SUPER::report_skipped({
        plugin  => 'Core',
        node    => $node,
        message => ($message||'')
    });
}

1;

__END__

# Structure of a node:
#   [0] = tag name
#   [1] = attribute hashref
#   [2] = contained tokens
#   [3] = template text
#   [4] = attributes arrayref
#   [5] = parent array reference
#   [6] = containing template

