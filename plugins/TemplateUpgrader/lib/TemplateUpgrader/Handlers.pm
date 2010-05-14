package TemplateUpgrader::Handlers;
use strict; use warnings; use Carp; use Data::Dumper;

use MT::Log::Log4perl qw(l4mtdump); use Log::Log4perl qw( :resurrect );
###l4p our $logger = MT::Log::Log4perl->new();

sub default_hdlr {
    my ($self, $node, $params ) = @_;
    $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    $logger->warn('default_hdlr usage detected '.Carp::longmess());
    $self->_report( { node => $node, %$params }, 'SKIPPED' );
}

sub report {
    my $self = shift;
    my ( $nodes, $message ) = @_;
    my $plugin = $self->PLUGIN();
    my $skipped = 0;

    # Massage the polymorphic data into a nice hashref. Data from the
    # report_skipped function is already a hash reference with an
    # extra skip key, which we'll save in $skipped
    my $data;
    if ( ref $nodes eq 'HASH' and $nodes->{skip} ) {
        $skipped = delete $nodes->{skip};
        $data = $nodes;
    }
    # Data supplied in direct calls to report() just need to be hashed
    else {
        $data = {
            nodes   => $nodes,
            message => ( $message||'' ),
        };
    }
    delete $data->{message}  if  defined $data->{message}
                            and  '' eq $data->{message}

    # Derive the template ID and Blog ID (if any) for reporting purposes
    my $tmpl    = $data->{nodes}[0]->ownerDocument;
    my $tmpl_id = $tmpl && $tmpl->id ? $tmpl->id : 0;
    my $blog    = $tmpl->blog;
    my $blog_id = $blog ? $blog->id : 0;

    # Convert the nodes into a final string
    my $tagattr = '';
    foreach my $tok ( @{ $data->{nodes} } ) {
        next unless defined $tok;

        # Join each of the arrayref elements into key=values (quoted values)
        my @keyvalues = ();        
        foreach my $kv ( @{ $tok->[4] } ) {
            my ($k, $v) = ($kv->[0], $kv->[1]);
            $v = $v =~ m/"/ ? qq{'$v'} : qq{"$v"};
            push @keyvalues,  join('=', $k, $kv )
        }
        # And join each of the key=values by a space
        $tagattr .= '<'.join( ' ', $tok->tagName, @keyvalues ).'>';
    }

    # Create the reporting message
    my $logger  = MT::Log::Log4perl->new( $plugin );
    my $message = $skipped ? 'Not transformed' : 'Transformed';
    $message   .= join('--', $message, $data->{message} ) if $data->{message};
    $logger->info(
          sprintf("%-10d %-10s $message: ", $blog_id, $tmpl_id ),
          $tagattr
    );
    return ( ! $skipped );
}

sub report_skipped {
    my $self = shift;
    my ( $nodes, $message ) = @_;
    $self->report({
        skip    => 1,
        nodes   => $nodes,
        message => ( $message||'' ),
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

