package TemplateUpgrader::Builder;
use strict; use warnings; use Carp; use Data::Dumper;

use MT::Util qw( weaken );

use base qw( MT::Builder );
use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

sub NODE () { 'TemplateUpgrader::Template::Node' }

sub compile {
    my $build = shift;
    my($ctx, $text, $opt) = @_;
    my $tmpl;
    ###l4p $logger ||= MT::Log::Log4perl->new(); #$logger->trace();

    $opt ||= { uncompiled => 1 };
    my $depth = $opt->{depth} ||= 0;

    my $ids;
    my $classes;
    my $errors;

    # handle $builder->compile($template) signature
    if (UNIVERSAL::isa($ctx, 'MT::Template')) {
        $tmpl = $ctx;
        $ctx = $tmpl->context;
        $text = $tmpl->text;
        $tmpl->reset_tokens();
        $ids = $build->{__state}{ids} = {};
        $classes = $build->{__state}{classes} = {};
        $errors = $build->{__state}{errors} = [];
        $build->{__state}{tmpl} = $tmpl;
    } else {
        $ids = $build->{__state}{ids} || {};
        $classes = $build->{__state}{classes} || {};
        $tmpl = $build->{__state}{tmpl};
        $errors = $build->{__state}{errors} ||= [];
    }

    return [ ] unless defined $text;

    my $mods;

    # Translate any HTML::Template markup into native MT syntax.
    if ($text =~ m/<(?:MT_TRANS\b|MT_ACTION\b|(?:tmpl_(?:if|loop|unless|else|var|include)))/i) {
        translate_html_tmpl($text);
    }

    my $state = $build->{__state};
    local $state->{tokens} = [];
    local $state->{classes} = $classes;
    local $state->{tmpl} = $tmpl;
    local $state->{ids} = $ids;
    local $state->{text} = \$text;

    my $pos = 0;
    my $len = length $text;
    # MT tag syntax: <MTFoo>, <$MTFoo$>, <$MTFoo>
    #                <MT:Foo>, <$MT:Foo>, <$MT:Foo$>
    #                <MTFoo:Bar>, <$MTFoo:Bar>, <$MTFoo:Bar$>
    # For 'function' tags, the '$' characters are optional
    # For namespace, the ':' is optional for the default 'MT' namespace.
    # Other namespaces (like 'Foo') would require the colon.
    # Tag and attributes are case-insensitive. So you can write:
    #   <mtfoo>...</MTFOO>
    while ($text =~ m!(<\$?(MT:?)((?:<[^>]+?>|"(?:<[^>]+?>|.)*?"|'(?:<[^>]+?>|.)*?'|.)+?)([-]?)[\$/]?>)!gis) {
        my($whole_tag, $prefix, $tag, $space_eater) = ($1, $2, $3, $4);
        ($tag, my($args)) = split /\s+/, $tag, 2;
        my $sec_start = pos $text;
        my $tag_start = $sec_start - length $whole_tag;
        $build->_text_block($state, $pos, $tag_start) if $pos < $tag_start;
        $state->{space_eater} = $space_eater;
        $args ||= '';
        ##l4p $logger->info("ARG STRING: $args") if $args;

        # Structure of a node:
        #   tag name, attribute hashref, contained tokens, template text,
        #       attributes arrayref, parent array reference
        my $rec = bless [ $tag, \my %args, undef, undef, \my @args ], NODE;
        while ($args =~ /
            (?:
                (?:
                    ((?:\w|:)+)                     #1
                    \s*=\s*
                    (?:(?:
                        (["'])                      #2
                        ((?:<[^>]+?>|.)*?)          #3
                        \2
                        (                           #4
                            (?:
                                [,:]
                                (["'])              #5
                                (?:(?:<[^>]+?>|.)*?)
                                \5
                            )+
                        )?
                    ) |
                    (\S+))                          #6
                )
            ) |
            (\w+)                                   #7
            /gsx) {
            if (defined $7) {
                # An unnamed attribute gets stored in the 'name' argument.
                $args{'name'} = $7;
            } else {
                my $attr = lc $1;
                my $value = defined $6 ? $6 : $3;
                my $extra = $4;
                ##l4p $logger->debug('PARSED ATTR/VALS ', l4mtdump({
                ##l4p     attr => $attr,
                ##l4p     value => $value,
                ##l4p     extra => $extra
                ##l4p }));

                if (defined $extra) {
                    my @extra;
                    push @extra, $2 while $extra =~ m/[,:](["'])((?:<[^>]+?>|.)*?)\1/gs;
                    $value = [ $value, @extra ];
                }

                ###########################################################
                ###############!!!! MAJOR CHANGE BELOW !!!!################
                ###
                ### Because it's imperative that we maintain the same
                ### attribute order for all existing attributes (excepting
                ### shifts caused by insertion of new ones or deletions of old
                ### one), we will be tracking ALL attributes and their values
                ### in array reference in the fourth node ($node->[4]). This
                ### obsoletes the hash reference contained in the first node.
                ### For expediency sake, we will still keep the same node
                ### order but the hash reference is not guaranteed to be
                ### correct for the purposes of this subclass/plugin.
                ###
                ##########################################################
                push @args, [$attr, $value];
                $args{$attr} = $value;
                ##########################################################
                if ($attr eq 'id') {
                    # store a reference to this token based on the 'id' for it
                    $ids->{$3} = $rec;
                } 
                elsif ($attr eq 'class') {
                    # store a reference to this token based on the 'id' for it
                    $classes->{lc $3} ||= [];
                    push @{ $classes->{lc $3} }, $rec;
                }
            }
        }
        my($h, $is_container) = $ctx->handler_for($tag);
        if (!$h) {
            # determine line #
            my $pre_error = substr($text, 0, $tag_start);
            my @m = $pre_error =~ m/\r?\n/g;
            my $line = scalar @m;
            if ($depth) {
                $opt->{error_line} = $line;
                push @$errors, { message => MT->translate("<[_1]> at line [_2] is unrecognized.", $prefix . $tag, "#"), line => $line };
            } else {
                push @$errors, { message => MT->translate("<[_1]> at line [_2] is unrecognized.", $prefix . $tag, $line + 1), line => $line };
            }
        }
        if ($is_container) {
            if ($whole_tag !~ m|/>$|) {
                my ($sec_end, $tag_end) = $build->_consume_up_to(\$text,$sec_start,$tag);
                if ($sec_end) {
                    my $sec = $tag =~ m/ignore/i ? '' # ignore MTIgnore blocks
                            : substr $text, $sec_start, $sec_end - $sec_start;
                    if ($sec !~ m/<\$?MT/i) {
                        $rec->[2] = [ ($sec ne '' ? ['TEXT', $sec ] : ()) ];
                    }
                    else {
                        local $opt->{depth} = $opt->{depth} + 1;
                        local $opt->{parent} = $rec;
                        $rec->[2] = $build->compile($ctx, $sec, $opt);
                        if ( @$errors ) {
                            my $pre_error = substr($text, 0, $sec_start);
                            my @m = $pre_error =~ m/\r?\n/g;
                            my $line = scalar @m;
                            foreach (@$errors) {
                                $line += $_->{line};
                                $_->{line} = $line;
                                $_->{message} =~ s/#/$line/;
                            }
                        }
                        # unless (defined $rec->[2]) {
                        #     my $pre_error = substr($text, 0, $sec_start);
                        #     my @m = $pre_error =~ m/\r?\n/g;
                        #     my $line = scalar @m;
                        #     if ($depth) {
                        #         $opt->{error_line} = $line + ($opt->{error_line} || 0);
                        #         return;
                        #     }
                        #     else {
                        #         $line += ($opt->{error_line} || 0) + 1;
                        #         my $err = $build->errstr;
                        #         $err =~ s/#/$line/;
                        #         return $build->error($err);
                        #     }
                        # }
                    }
                    $rec->[3] = $sec if $opt->{uncompiled};
                }
                else {
                    my $pre_error = substr($text, 0, $tag_start);
                    my @m = $pre_error =~ m/\r?\n/g;
                    my $line = scalar @m;
                    if ($depth) {
                        # $opt->{error_line} = $line;
                        # return $build->error(MT->translate("<[_1]> with no </[_1]> on line #", $prefix . $tag));
                        push @$errors, { message => MT->translate("<[_1]> with no </[_1]> on line [_2].", $prefix . $tag, "#" ), line => $line };
                    }
                    else {
                        push @$errors, { message => MT->translate("<[_1]> with no </[_1]> on line [_2].", $prefix . $tag, $line +1 ), line => $line + 1 };
                        # return $build->error(MT->translate("<[_1]> with no </[_1]> on line [_2]", $prefix . $tag, $line + 1));
                    }
                    last; # return undef;
                }
                $pos = $tag_end + 1;
                (pos $text) = $tag_end;
            }
            else {
                $rec->[3] = '';
            }
        }
        weaken($rec->[5] = $opt->{parent} || $tmpl);
        weaken($rec->[6] = $tmpl);
        push @{ $state->{tokens} }, $rec;
        $pos = pos $text;
    }
    $build->_text_block($state, $pos, $len) if $pos < $len;
    if (defined $tmpl) {
        # assign token and id references to template
        $tmpl->tokens($state->{tokens});
        $tmpl->token_ids($state->{ids});
        $tmpl->token_classes($state->{classes});
        $tmpl->errors($state->{errors})
            if $state->{errors} && (@{$state->{errors}});
    }
    return $state->{tokens};
}

sub _consume_up_to {
    my $self = shift if ref $_[0]
                    and ref $_[0] ne 'SCALAR'
                    and $_[0]->isa(__PACKAGE__);
    my($text, $start, $stoptag) = @_;
    my $pos;
    (pos $$text) = $start;
    while ($$text =~ m!(<([\$/]?)MT:?($stoptag)\b(?:[^>]*?)[\$/]?>)!gi) {
        my($whole_tag, $prefix, $tag) = ($1, $2, $3);
        my $end = pos $$text;
        if ($prefix && ($prefix eq '/')) {
            return ($end - length($whole_tag), $end);
        } elsif ($whole_tag !~ m|/>|) {
            my ($sec_end, $end_tag) = _consume_up_to($text, $end, $tag);
            last if !$sec_end;
            (pos $$text) = $end_tag;
        }
    }
    # special case for unclosed 'else' tag:
    if (lc($stoptag) eq 'else' || lc($stoptag) eq 'elseif') {
        return ($start + length($$text), $start + length($$text));
    }
    return (0, 0);
}

sub _text_block {
    my $self = shift;
    my $text = substr ${ $_[0]->{text} }, $_[1], $_[2] - $_[1];
    if ((defined $text) && ($text ne '')) {
        return if $_[0]->{space_eater} && ($text =~ m/^\s+$/s);
        $text =~ s/^\s+//s if $_[0]->{space_eater};
        my $rec = bless [ 'TEXT', $text, undef, undef, undef, $_[0]->{tokens}, $_[0]->{tmpl} ], NODE;
        # Avoids circular reference between NODE and TOKENS, MT::Template.
        weaken($rec->[5]);
        weaken($rec->[6]);
        push @{ $_[0]->{tokens} }, $rec;
    }
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

