=head1 NAME

 Matching::StableRoommates

=head1 DESCRIPTION

 http://en.wikipedia.org/wiki/Stable_roommates_problem

=head1 EXAMPLE USAGE

=head1 AUTHOR - Matthew Betts

 mailto:bettsmatthew@googlemail.com

=cut

package Matching::StableRoommates;

use strict;
use warnings;
use Moose;
use vars qw($VERSION);

$VERSION = "0.01a";

=head1 ACCESSORS

=cut

=head2 n_pairs

 usage   :
 function: the desired number of pairings per participant
 args    :
 returns :

=cut
has 'n_pairs' => (is => 'ro', isa => 'Int', required => 1, default => 1);

=head2 preferences

 usage   :
 function:
 args    :
 returns :

=cut

=head2 preferences

 usage   : $self->preferences();
           $self->preferences($idA);

 function: get the preference lists for all participants as a hash ref,
           or the preferences for a particular participant as a list
 args    : a participant identifier (optional)
 returns : a hash ref or a list

=cut

has 'preferences' => (is => 'ro', isa => 'HashRef[Any]', required => 1);

around preferences => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;

    if(defined($id)) {
        return(defined($self->preferences->{$id}) ? @{$self->preferences->{$id}} : ());
    }
    else {
        return $self->$orig;
    }
};

=head2 participants

 usage   :
 function: built from the preference lists when the object is constructed
 args    :
 returns :

=cut

has 'participants' => (is => 'ro', isa => 'ArrayRef[Any]', auto_deref => 1, required => 1);

=head2 proposals

 usage   : $self->proposals();
           $self->proposals($idA);

 function: get the proposal lists for all participants as a hash ref,
           or the proposals accepted by a particular participant as a list
 args    : a participant identifier (optional)
 returns : a hash ref or a list

=cut

has 'proposals' => (is => 'ro', isa => 'HashRef[Any]', default => sub {return {}}, init_arg => undef);

around proposals => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;

    if(defined($id)) {
        return(defined($self->proposals->{$id}) ? @{$self->proposals->{$id}} : ());
    }
    else {
        return $self->$orig;
    }
};

=head2 ranking

 usage   : $self->ranking;                    # get ranking matrix hash
           $self->ranking($idA);              # get ranking matrix hash for $idA
           $self->ranking($idA, $idB);        # get rank of $idB in $idA's preference list
           $self->ranking($idA, $idB, $rank); # set rank of $idB in $idA's preference list
 function:
 args    :
 returns :

=cut

has 'ranking' => (is => 'ro', isa => 'HashRef[Any]', default => sub {return {}}, init_arg => undef);

around ranking => sub {
    my $orig = shift;
    my $self = shift;
    my $idA  = shift;
    my $idB  = shift;
    my $rank = shift;

    if(defined($idA)){
        if(defined($idB)) {
            if(defined($rank)) {
                $self->ranking->{$idA}->{$idB} = $rank;
                return $rank;
            }
            else {
                return $self->ranking->{$idA}->{$idB};
            }
        }
        else {
            return $self->ranking->{$idA};
        }
    }
    else {
        return $self->$orig;
    }
};

=head1 METHODS

=cut

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my @args;
    my $participants;
    my $idA;
    my $idB;
    my $i;
    my $j;
    my $key;
    my $value;
    my $preferences;

    @args = ();

    $participants = undef;
    for($i = 0, $j = 1; $j < @_; $i += 2, $j += 2) {
        ($key, $value) = @_[$i..$j];

        # get participants from preferences
        if($key eq 'preferences') {
            (ref($value) ne 'HASH') and Carp::croak('preferences should be given as a hash');
            $preferences = $value;
            $participants = {};
            foreach $idA (keys %{$preferences}) {
                $participants->{$idA}++;
                foreach $idB (@{$preferences->{$idA}}) {
                    $participants->{$idB}++;
                }
            }
            $participants = [sort keys %{$participants}];
            push @args, 'participants', $participants;
        }
        elsif($key eq 'participants') {
            next;
        }

        push @args, $key, $value;
    }

    return $class->$orig(@args);
};

sub BUILD {
    my($self) = @_;

    my $idA;
    my $idB;
    my $i;
    my $j;
    my %seen;

    ($self->n_pairs <= 0) and Carp::croak('n_pairs <= 0');
    (keys(%{$self->preferences}) == 0) and Carp::croak('empty preference list');

    # build ranking matrix
    if(0) {
    foreach $idA ($self->participants) {
        $i = 0;
        @seen{$self->participants} = (0) x $self->participants;
        $seen{$idA}++;
        foreach $idB ($self->preferences($idA)) {
            print join("\t", $idA, $idB), "\n";
            $self->ranking->{$idA}->{$idB} = $i;
            $seen{$idB}++;
            ++$i;
        }

        foreach $idB (keys %seen) {
            ($seen{$idB} > 0) and next;
            $self->ranking->{$idA}->{$idB} = $i;
        }
    }
    }
}

=head2 n_preferences

 usage   : $self->n_preferences($id);
 function: number of preferences by the given participant
 args    :
 returns :

=cut

sub n_preferences {
    my($self, $id) = @_;

    my @prefs;

    @prefs = $self->preferences($id);
    return scalar @prefs;
}

=head2 n_proposals

 usage   : $self->n_proposals($id);
 function: number of proposals accepted by the given participant
 args    :
 returns :

=cut

sub n_proposals {
    my($self, $id) = @_;

    my @props;

    @props = $self->proposals($id);
    return scalar @props;
}

=head2 output

 usage   : $self->output($fh);
 function: print the preferences as a tsv
 args    : a file handle glob (defaults to \*STDOUT)
 returns : 1 on success

=cut

sub output_tsv {
    my($self, $fh) = @_;

    my $id;

    defined($fh) or ($fh = \*STDOUT);
    foreach $id ($self->participants) {
        print $fh join("\t", $id, $self->preferences($id)), "\n";
    }

    return 1;
}

=head2 propose

 usage   : $self->propose($idA, $idB);
 function: $idA proposes to $idB
           $idB accepts the proposal if it has accepted fewer than $self->n_pairs proposals,
           or this proposal is better than an accepted proposal. In that case, the accepted
           proposal with the lowest preference is rejected.
 args    :
 returns :

=cut

sub propose {
    my($self, $idA, $idB) = @_;

    print join('', $idA, ' -> ', $idB, ', n_proposals=', $self->n_proposals($idB), ', n_pairs=', $self->n_pairs), "\n";

    if($self->n_proposals($idB) >= $self->n_pairs) {
        # FIXME - is the new proposal prefered?
    }
    else {
        # accept the proposal
        $self->accept_proposal($idA, $idB);
    }
}

=head2 accept_proposal

 usage   : $self->accept_proposal($idA, $idB);
 function: $idA is added to $idB's list of proposals
 args    :
 returns :

=cut

sub accept_proposal {
    my($self, $idA, $idB) = @_;

}

=head2 phase1

 usage   : $self->output($fh);
 function: print the preferences as a tsv
 args    : a file handle glob (defaults to \*STDOUT)
 returns : 1 on success

=cut

sub phase1 {
    my($self, $fh) = @_;

    my $idA;
    my $idB;

    defined($fh) or ($fh = \*STDOUT);
    foreach $idA ($self->participants) {
        foreach $idB ($self->preferences($idA)) {
            $self->propose($idA, $idB, $fh);
        }
        print $fh "//\n";
    }

    return 1;
}

1;
