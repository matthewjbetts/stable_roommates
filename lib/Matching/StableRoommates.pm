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

 usage   : $self->preferences();           # get the preference lists for all participants as a hash ref
           $self->preferences($idA);       # get the preferences for a particular participant as a list ref,
           $self->preferences($idA, $idx); # get the participant at a particular position in a particular participant's as preference list,
 function:
 args    : a participant identifier (optional)
 returns : a hash ref, a list or a scalar

=cut

has 'preferences' => (is => 'ro', isa => 'HashRef[Any]', required => 1);

around preferences => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;
    my $idx  = shift;

    if(defined($id)) {
        defined($self->preferences->{$id}) or ($self->preferences->{$id} = []);
        if(defined($idx)) {
            return $self->preferences->{$id}->[$idx];
        }
        else {
            return $self->preferences->{$id};
        }
    }
    else {
        return $self->$orig;
    }
};

=head2 preference_idx

 usage   : $self->preference_idx($idA, $idB); # get position of $idB in $idA's preference list
 function:
 args    :
 returns :

=cut

has 'preference_idx' => (is => 'ro', isa => 'HashRef[Any]', required => 1);

around preference_idx => sub {
    my $orig = shift;
    my $self = shift;
    my $idA  = shift;
    my $idB  = shift;

    if(defined($idA)) {
        if(defined($idB)) {
            return $self->preference_idx->{$idA}->{$idB};
        }
        else {
            return $self->preference_idx->{$idA};
        }
    }
    else {
        return $self->$orig;
    }
};

=head2 current_preference_idx

 usage   : $self->current_preference_idx($idA);       # get the current position in the preference list of a particular participant
           $self->current_preference_idx($idA, $idx); # set the current position in the preference list of a particular participant
 function: get/set the current position in the preference list of a particular participant
 args    :
 returns :

=cut

has 'current_preference_idx' => (is => 'ro', isa => 'HashRef[Any]', default => sub {return {}}, init_arg => undef);

around current_preference_idx => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;
    my $idx  = shift;

    if(defined($id)) {
        defined($self->current_preference_idx->{$id}) or ($self->current_preference_idx->{$id} = -1);
        defined($idx) and ($self->current_preference_idx->{$id} = $idx);
        return $self->current_preference_idx->{$id};
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

has 'participants' => (is => 'ro', isa => 'ArrayRef[Any]', required => 1);

=head2 proposals

 usage   : $self->proposals();
           $self->proposals($idA);

 function: get the proposal lists for all participants as a hash ref,
           or the proposals accepted by a particular participant as a list ref
 args    : a participant identifier (optional)
 returns : a hash ref or a list

=cut

has 'proposals' => (is => 'ro', isa => 'HashRef[Any]', default => sub {return {}}, init_arg => undef);

around proposals => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;

    if(defined($id)) {
        defined($self->proposals->{$id}) or ($self->proposals->{$id} = []);
        return $self->proposals->{$id};
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
                # if idB is in idA's preference list, return its rank
                # if not, return the lowest rank possible, i.e. the number of participants
                $rank = defined($self->ranking->{$idA}->{$idB}) ? $self->ranking->{$idA}->{$idB} : $self->n_participants;
                return $rank;
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

=head2 debug

 usage   :
 function:
 args    :
 returns :

=cut

has 'debug' => (is => 'ro', isa => 'Int', default => 0);

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
    my $k;
    my $key;
    my $value;
    my $preferences;
    my $preference_idx;
    my $n_pairs_max;
    my $n_pairs;

    @args = ();

    $participants = undef;
    for($i = 0, $j = 1; $j < @_; $i += 2, $j += 2) {
        ($key, $value) = @_[$i..$j];

        # get participants from preferences
        if($key eq 'preferences') {
            (ref($value) ne 'HASH') and Carp::croak('preferences should be given as a hash');
            $preferences = $value;
            $preference_idx = {};
            $participants = {};
            foreach $idA (keys %{$preferences}) {
                $participants->{$idA}++;
                $k = 0;
                foreach $idB (@{$preferences->{$idA}}) {
                    $participants->{$idB}++;
                    $preference_idx->{$idA}->{$idB} = $k;
                    ++$k;
                }
            }
            $participants = [sort keys %{$participants}];
            push @args, 'participants', $participants, 'preference_idx', $preference_idx;

            # max number of pairs per participant = number of participants - 1
            $n_pairs_max = scalar @{$participants} - 1;
        }
        elsif($key eq 'n_pairs') {
            $n_pairs = $value;
            next;
        }
        elsif($key eq 'participants') {
            next;
        }

        push @args, $key, $value;
    }
    (($n_pairs < 1) or ($n_pairs > $n_pairs_max)) and ($n_pairs = $n_pairs_max);
    push @args, 'n_pairs', $n_pairs;

    return $class->$orig(@args);
};

sub BUILD {
    my($self) = @_;

    my $idA;
    my $idB;
    my $i;
    my $j;
    my $seen;

    ($self->n_pairs <= 0) and Carp::croak('n_pairs <= 0');
    (keys(%{$self->preferences}) == 0) and Carp::croak('empty preference list');

    # build ranking matrix
    foreach $idA (@{$self->participants}) {
        $i = 0;
        foreach $idB (@{$self->preferences($idA)}) {
            $self->ranking->{$idA}->{$idB} = $i;
            $seen->{$idB}++;
            ++$i;
        }
    }
}

=head2 current_preference_idx_incr

 usage   :
 function:
 args    :
 returns :

=cut

sub current_preference_idx_incr {
    my($self, $id) = @_;

    my $idx;

    $idx = $self->current_preference_idx($id, $self->current_preference_idx($id) + 1);

    return $idx;
}

=head2 current_preference_idx_reset

 usage   :
 function:
 args    :
 returns :

=cut

sub current_preference_idx_reset {
    my($self, $id) = @_;

    my @ids;

    @ids = defined($id) ? ($id) : @{$self->participants};
    foreach $id (@ids) {
        $self->current_preference_idx($id, -1);
    }
}

=head2 next_preference

 usage   :
 function:
 args    :
 returns :

=cut

sub next_preference {
    my($self, $idA) = @_;

    my $idx;
    my $idB;

    $idx = $self->current_preference_idx_incr($idA);
    $idB = $self->preferences($idA, $idx);

    return $idB;
}


=head2 n_participants

 usage   : $self->n_participants;
 function: number of participants
 args    :
 returns :

=cut

sub n_participants {
    my($self) = @_;

    my @parts;

    @parts = @{$self->participants};
    return scalar @parts;
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

    @prefs = @{$self->preferences($id)};
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

    @props = @{$self->proposals($id)};
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
    foreach $id (@{$self->participants}) {
        print $fh join("\t", $id, @{$self->preferences($id)}), "\n";
    }

    return 1;
}

=head2 propose

 usage   : $self->propose($idA, $idB, $queue);
 function: $idA proposes to $idB
           $idB accepts the proposal if it has accepted fewer than $self->n_pairs proposals,
           or this proposal is better than an accepted proposal. In that case, the accepted
           proposal with the lowest preference is rejected.
 args    : id of proposer, id of proposee, ref to array of participants waiting to propose
 returns :

=cut

sub propose {
    my($self, $idA, $idB, $queue) = @_;

    my $accepted;
    my $rank0;
    my $rank1;
    my $idC;
    my $i;

    $self->debug and print("$idA -> $idB");

    $accepted = 0;
    if($self->n_proposals($idB) >= $self->n_pairs) {
        # is the new proposal preferred over any of the existing ones?
        $rank0 = $self->ranking($idB, $idA);
        $i = 0;
        foreach $idC (@{$self->proposals($idB)}) {
            $rank1 = $self->ranking($idB, $idC);

            #$self->debug and print("$idA is at rank $rank0, $idC is at rank $rank1\n");

            if($rank1 > $rank0) {
                # - remove $idC from $idB's accepted proposals
                # - $idC then has to propose to someone else, so put it back on to the queue
                # FIXME - shouldn't really be manipulating the proposal list directly here
                splice @{$self->proposals($idB)}, $i, 1;
                unshift @{$queue}, $idC;
                $self->debug and print("; rem $idB x $idC ($idC < $idA)");

                # add $idA to $idB's accepted proposals
                $self->accept_proposal($idB, $idA);
                ++$accepted;

                last;
            }
            else {
                # - $idB rejects $idA's proposal
                # - $idA then has to propose to someone else, so put it back on the queue
                unshift @{$queue}, $idA;
                $self->debug and print("; ign $idB x $idA ($idA < $idC)");
            }
            ++$i;
        }
    }
    else {
        # accept the proposal
        $self->accept_proposal($idB, $idA);
        ++$accepted;
    }
    $self->debug and print("\n");

    return $accepted;
}

=head2 accept_proposal

 usage   : $self->accept_proposal($idB, $idA);
 function: $idA has proposed to $idB, $idA is added to $idB's list of proposals
 args    :
 returns :

=cut

sub accept_proposal {
    my($self, $idB, $idA) = @_;

    push @{$self->proposals($idB)}, $idA;
}

=head2 phase1

 usage   : $self->output($fh);
 function: print the preferences as a tsv
 args    : a file handle glob (defaults to \*STDOUT)
 returns : 1 on success

=cut

sub phase1 {
    my($self, $fh) = @_;

    my $queue;
    my $idA;
    my $idB;
    my $n_accepted;
    my $firsts;
    my $lasts;
    my $prefix;

    defined($fh) or ($fh = \*STDOUT);

    $self->current_preference_idx_reset();
    $queue = [(@{$self->participants}) x $self->n_pairs];
    while($idA = shift @{$queue}) {
        $n_accepted = 0;
        #while(defined($idB = $self->next_preference($idA))) {
        #    $self->propose($idA, $idB, $queue) and ++$n_accepted;
        #    ($n_accepted == $self->n_pairs) and last;
        #}

        if(defined($idB = $self->next_preference($idA))) {
            $self->propose($idA, $idB, $queue) and ++$n_accepted;
        }
    }
    $self->current_preference_idx_reset();

    if($self->debug) {
        print "\npreferences:\n";
        foreach $idA (@{$self->participants}) {
            print join(' ', "$idA:", @{$self->preferences($idA)}), "\n";
        }

        print "\nproposals:\n";
        foreach $idA (@{$self->participants}) {
            print join(' ', $idA, '<-', @{$self->proposals($idA)}), "\n";
        }

        print "\n";
    }

    $firsts = {};
    $lasts = {};
    foreach $idA (@{$self->participants}) {
        foreach $idB (@{$self->proposals($idA)}) {
            $lasts->{$idA} = $idB;
            $firsts->{$idB} = $idA;
        }
    }
    return 1;

    foreach $idA (@{$self->participants}) {
        print "$idA:";
        $prefix = '-';
        foreach $idB (@{$self->preferences($idA)}) {
            ($idB eq $firsts->{$idA}) and ($prefix = '+');
            print "\t$prefix$idB";
            ($idB eq $lasts->{$idA}) and ($prefix = '-');
        }
        print "\n";
    }

    return 1;
}

1;
